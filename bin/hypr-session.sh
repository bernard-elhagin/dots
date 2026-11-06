#!/usr/bin/env bash
set -euo pipefail

# Save and restore a best-effort snapshot of a Hyprland session.
# Requires Python 3 and hyprctl. State defaults to ~/.config/hypr/session.json.
exec python3 - "$@" <<'PY'
import argparse
import collections
import json
import os
import pathlib
import subprocess
import sys
import tempfile
import time


DEFAULT_STATE = pathlib.Path.home() / ".config/hypr/session.json"
POLL_SECONDS = 15


def run_hyprctl(*args, required=True):
    try:
        result = subprocess.run(
            ["hyprctl", *map(str, args)],
            check=False,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
        )
    except FileNotFoundError:
        raise RuntimeError("hyprctl is not installed or is not on PATH")
    if required and result.returncode != 0:
        message = result.stderr.strip() or result.stdout.strip()
        raise RuntimeError(message or f"hyprctl {' '.join(map(str, args))} failed")
    return result


def hypr_json(command):
    result = run_hyprctl("-j", command)
    try:
        return json.loads(result.stdout)
    except json.JSONDecodeError as exc:
        raise RuntimeError(f"Could not parse hyprctl {command} JSON: {exc}")


def process_info(pid):
    info = {"argv": [], "cwd": None}
    if not isinstance(pid, int) or pid <= 0:
        return info
    try:
        raw = pathlib.Path(f"/proc/{pid}/cmdline").read_bytes()
        info["argv"] = [os.fsdecode(arg) for arg in raw.split(b"\0") if arg]
        info["cwd"] = os.readlink(f"/proc/{pid}/cwd")
    except (FileNotFoundError, PermissionError, ProcessLookupError, OSError):
        pass
    return info


def workspace_selector(workspace):
    name = str(workspace.get("name", ""))
    ident = workspace.get("id")
    if name.startswith("special:"):
        return name
    if name and name != str(ident):
        return "name:" + name
    return str(ident)


def save_session(path):
    clients = hypr_json("clients")
    workspaces = hypr_json("workspaces")
    monitors = hypr_json("monitors")
    active_workspace = hypr_json("activeworkspace")
    active_window = hypr_json("activewindow")

    windows = []
    for client in clients:
        ws = client.get("workspace") or {}
        proc = process_info(client.get("pid"))
        windows.append({
            "class": client.get("class", ""),
            "initialClass": client.get("initialClass", ""),
            "title": client.get("title", ""),
            "initialTitle": client.get("initialTitle", ""),
            "pid": client.get("pid"),
            "argv": proc["argv"],
            "cwd": proc["cwd"],
            "workspace": {
                "id": ws.get("id"),
                "name": ws.get("name", ""),
                "monitor": client.get("monitor", ""),
            },
            "floating": bool(client.get("floating", False)),
            "pseudo": bool(client.get("pseudo", False)),
            "fullscreen": int(client.get("fullscreen", 0) or 0),
            "pinned": bool(client.get("pinned", False)),
            "at": client.get("at"),
            "size": client.get("size"),
            "focusHistoryID": client.get("focusHistoryID"),
        })

    state = {
        "version": 1,
        "savedAt": time.strftime("%Y-%m-%dT%H:%M:%S%z"),
        "monitors": [
            {"name": m.get("name", ""), "width": m.get("width"),
             "height": m.get("height"), "scale": m.get("scale")}
            for m in monitors
        ],
        "workspaces": [
            {"id": w.get("id"), "name": w.get("name", ""),
             "monitor": w.get("monitor", "")}
            for w in workspaces
        ],
        "activeWorkspace": {
            "id": active_workspace.get("id"),
            "name": active_workspace.get("name", ""),
            "monitor": active_workspace.get("monitor", ""),
        },
        "activeWindow": {
            "class": active_window.get("class", ""),
            "initialClass": active_window.get("initialClass", ""),
            "title": active_window.get("title", ""),
            "workspace": (active_window.get("workspace") or {}).get("name", ""),
        },
        "windows": windows,
    }

    path.parent.mkdir(parents=True, exist_ok=True)
    fd, temp_name = tempfile.mkstemp(prefix=path.name + ".", dir=path.parent)
    try:
        os.fchmod(fd, 0o600)
        with os.fdopen(fd, "w", encoding="utf-8") as output:
            json.dump(state, output, indent=2, ensure_ascii=False)
            output.write("\n")
        os.replace(temp_name, path)
        os.chmod(path, 0o600)
    except Exception:
        try:
            os.unlink(temp_name)
        except FileNotFoundError:
            pass
        raise
    print(f"Saved {len(windows)} windows and {len(workspaces)} workspaces to {path}")
    print("The state file is mode 600; saved process arguments can still contain sensitive values.")


def lua_string(value):
    return json.dumps(str(value), ensure_ascii=False)


def dispatch(name, parameter="", extra=""):
    if name == "workspace":
        code = f"hl.dsp.focus({{ workspace = {lua_string(parameter)} }})"
    elif name == "focusmonitor":
        code = f"hl.dsp.focus({{ monitor = {lua_string(parameter)} }})"
    elif name == "moveworkspacetomonitor":
        workspace, monitor = parameter.rsplit(" ", 1)
        code = ("hl.dsp.workspace.move({ workspace = " + lua_string(workspace)
                 + ", monitor = " + lua_string(monitor) + " })")
    elif name == "focuswindow":
        code = f"hl.dsp.focus({{ window = {lua_string(parameter)} }})"
    elif name == "float":
        code = ("hl.dsp.window.float({ window = " + lua_string(parameter)
                 + ", action = " + lua_string(extra) + " })")
    elif name == "move":
        address, x, y = parameter.split(" ", 2)
        code = ("hl.dsp.window.move({ window = " + lua_string(address)
                 + f", x = {int(x)}, y = {int(y)}, relative = false }})")
    elif name == "resize":
        address, width, height = parameter.split(" ", 2)
        code = ("hl.dsp.window.resize({ window = " + lua_string(address)
                 + f", x = {int(width)}, y = {int(height)}, relative = false }})")
    elif name in ("pseudo", "pin"):
        code = (f"hl.dsp.window.{name}({{ window = {lua_string(parameter)}, "
                 f"action = {lua_string(extra)} }})")
    elif name == "fullscreen":
        mode = "maximized" if extra == "maximized" else "fullscreen"
        code = ("hl.dsp.window.fullscreen({ window = " + lua_string(parameter)
                 + ', action = "set", mode = ' + lua_string(mode) + " })")
    else:
        raise RuntimeError(f"Unsupported Hyprland action: {name}")

    result = run_hyprctl("dispatch", code, required=False)
    if result.returncode != 0:
        message = result.stderr.strip() or result.stdout.strip()
        print(f"hyprctl dispatch {name} {parameter}: {message or 'failed'}", file=sys.stderr)
        return False
    return True


def client_key(client):
    ws = client.get("workspace") or {}
    return (str(ws.get("name", ws.get("id", ""))),
            str(client.get("initialClass") or client.get("class") or ""))


def clients_now():
    try:
        return hypr_json("clients")
    except RuntimeError as exc:
        print(f"Could not refresh window list: {exc}", file=sys.stderr)
        return []


def restore_window(saved, existing_counts):
    ws = saved.get("workspace") or {}
    selector = workspace_selector(ws)
    app_class = saved.get("initialClass") or saved.get("class") or ""
    key = (str(ws.get("name", ws.get("id", ""))), str(app_class))
    if existing_counts[key] > 0:
        existing_counts[key] -= 1
        print(f"Already open; leaving {app_class or 'window'} on {key[0]} alone")
        return

    argv = saved.get("argv") or []
    if not argv:
        print(f"Skipping {app_class or 'window'}: its process command was unavailable at save time", file=sys.stderr)
        return

    monitor = ws.get("monitor") or ""
    known_monitors = {m.get("name") for m in hypr_json("monitors")}
    if monitor and monitor in known_monitors:
        dispatch("focusmonitor", monitor)
    elif monitor:
        print(f"Monitor {monitor!r} is not connected; opening {app_class or argv[0]} on the current monitor")

    dispatch("workspace", selector)
    before = {str(c.get("address")) for c in clients_now()}
    cwd = saved.get("cwd")
    if not cwd or not os.path.isdir(cwd):
        cwd = str(pathlib.Path.home())
    try:
        process = subprocess.Popen(argv, cwd=cwd, start_new_session=True)
    except (FileNotFoundError, PermissionError, OSError) as exc:
        print(f"Could not launch {argv[0]!r}: {exc}", file=sys.stderr)
        return

    deadline = time.monotonic() + POLL_SECONDS
    opened = None
    while time.monotonic() < deadline:
        time.sleep(0.4)
        current = clients_now()
        new_clients = [c for c in current if str(c.get("address")) not in before]
        matches = [c for c in new_clients
                   if not app_class or (c.get("initialClass") or c.get("class")) == app_class]
        if not matches and new_clients:
            matches = [c for c in new_clients
                       if str((c.get("workspace") or {}).get("name", "")) == str(ws.get("name", ""))]
        if matches:
            opened = matches[-1]
            break
        if process.poll() is not None and not new_clients:
            # A launcher may exit after handing the request to an existing app.
            time.sleep(0.8)

    if opened is None:
        print(f"No new window detected for {app_class or argv[0]} after {POLL_SECONDS}s; it may be a single-instance app or a helper process", file=sys.stderr)
        return

    address = str(opened.get("address", ""))
    if not address:
        print(f"Opened {app_class or argv[0]}, but Hyprland returned no window address", file=sys.stderr)
        return

    dispatch("focuswindow", "address:" + address)
    current_floating = bool(opened.get("floating", False))
    if current_floating != bool(saved.get("floating", False)):
        dispatch("float", "address:" + address,
                 "set" if saved.get("floating", False) else "unset")

    if saved.get("floating"):
        at = saved.get("at") or []
        size = saved.get("size") or []
        if len(at) >= 2:
            dispatch("move", f"address:{address} {int(at[0])} {int(at[1])}")
        if len(size) >= 2:
            dispatch("resize", f"address:{address} {int(size[0])} {int(size[1])}")

    if saved.get("pseudo") and not opened.get("pseudo", False):
        dispatch("pseudo", "address:" + address, "set")
    if saved.get("pinned") and not opened.get("pinned", False):
        dispatch("pin", "address:" + address, "set")
    if int(saved.get("fullscreen", 0) or 0) and not int(opened.get("fullscreen", 0) or 0):
        dispatch("fullscreen", "address:" + address,
                 "maximized" if int(saved.get("fullscreen", 0)) == 1 else "fullscreen")

    existing_counts[key] += 1
    print(f"Opened {app_class or argv[0]} on workspace {selector}")


def restore_session(path):
    try:
        state = json.loads(path.read_text(encoding="utf-8"))
    except FileNotFoundError:
        raise RuntimeError(f"No saved session at {path}; run 'hypr-session.sh save' first")
    except json.JSONDecodeError as exc:
        raise RuntimeError(f"Saved session is not valid JSON: {exc}")
    if state.get("version") != 1:
        raise RuntimeError(f"Unsupported session file version: {state.get('version')!r}")

    monitor_names = {m.get("name") for m in hypr_json("monitors")}
    for workspace in state.get("workspaces", []):
        name = workspace.get("name", "")
        if name.startswith("special:"):
            continue
        monitor = workspace.get("monitor") or ""
        if monitor and monitor in monitor_names:
            dispatch("focusmonitor", monitor)
        selector = workspace_selector(workspace)
        dispatch("workspace", selector)
        if monitor and monitor in monitor_names:
            dispatch("moveworkspacetomonitor", f"{selector} {monitor}")

    counts = collections.Counter(client_key(c) for c in clients_now())
    windows = state.get("windows", [])
    for saved in windows:
        restore_window(saved, counts)

    active = state.get("activeWorkspace") or {}
    active_selector = workspace_selector(active)
    active_monitor = active.get("monitor") or ""
    current_monitors = {m.get("name") for m in hypr_json("monitors")}
    if active_monitor in current_monitors:
        dispatch("focusmonitor", active_monitor)
    if active_selector:
        dispatch("workspace", active_selector)

    active_window = state.get("activeWindow") or {}
    wanted_class = active_window.get("initialClass") or active_window.get("class")
    wanted_title = active_window.get("title")
    if wanted_class:
        matches = [c for c in clients_now()
                   if (c.get("initialClass") or c.get("class")) == wanted_class
                   and (not wanted_title or c.get("title") == wanted_title)]
        if matches:
            dispatch("focuswindow", "address:" + str(matches[-1].get("address", "")))
    print("Session restore finished. Check the reported skips and launch failures.")


def main():
    parser = argparse.ArgumentParser(description="Save or restore a Hyprland window/workspace snapshot.")
    parser.add_argument("action", choices=("save", "restore"))
    parser.add_argument("--file", type=pathlib.Path, default=DEFAULT_STATE,
                        help=f"session JSON path (default: {DEFAULT_STATE})")
    args = parser.parse_args()
    try:
        if args.action == "save":
            save_session(args.file)
        else:
            restore_session(args.file)
    except RuntimeError as exc:
        print(f"hypr-session: {exc}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
PY
