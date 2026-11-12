#!/usr/bin/env bash
set -euo pipefail

# Save and restore a best-effort snapshot of a Hyprland session.
# Requires Python 3 and hyprctl. State defaults to ~/.config/hypr/session.json.
exec python3 - "$@" <<'PY'
import argparse
import json
import os
import pathlib
import subprocess
import sys
import tempfile
import time


DEFAULT_STATE = pathlib.Path.home() / ".config/hypr/session.json"
POLL_SECONDS = 15
STEAM_POLL_SECONDS = 180


def run_hyprctl(*args, required=True):
    try:
        result = subprocess.run(
            ["hyprctl", *map(str, args)],
            check=False,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            timeout=20,
        )
    except subprocess.TimeoutExpired:
        raise RuntimeError("hyprctl timed out")
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
    previous_windows = []
    if path.exists():
        try:
            previous = json.loads(path.read_text(encoding="utf-8"))
            previous_windows = previous["windows"]
            if not isinstance(previous_windows, list):
                raise ValueError("windows must be an array")
            for saved in previous_windows:
                startup_options(saved)
        except (ValueError, KeyError, TypeError) as exc:
            raise RuntimeError(f"Refusing to overwrite invalid session settings: {exc}")
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
            "savedAddress": client.get("address", ""),
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
                "monitor": next((m.get("name", "") for m in monitors
                                 if m.get("id") == client.get("monitor")), ""),
            },
            "floating": bool(client.get("floating", False)),
            "pseudo": bool(client.get("pseudo", False)),
            "fullscreen": int(client.get("fullscreen", 0) or 0),
            "pinned": bool(client.get("pinned", False)),
            "at": client.get("at"),
            "size": client.get("size"),
            "focusHistoryID": client.get("focusHistoryID"),
        })

    preserve_startups(previous_windows, windows)

    state = {
        "version": 2,
        "savedAt": time.strftime("%Y-%m-%dT%H:%M:%S%z"),
        "monitors": [
            {"name": m.get("name", ""), "width": m.get("width"),
             "height": m.get("height"), "scale": m.get("scale"),
             "id": m.get("id"), "x": m.get("x"), "y": m.get("y")}
            for m in monitors
        ],
        "workspaces": [
            {"id": w.get("id"), "name": w.get("name", ""),
             "monitor": w.get("monitor", ""),
             "layout": w.get("tiledLayout") or w.get("layout") or option("general:layout", "str"),
             "masterOrientation": option("master:orientation", "str") or "right"}
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

    for workspace in state["workspaces"]:
        selector = workspace_selector(workspace)
        tiled = [w for w in windows if workspace_selector(w["workspace"]) == selector
                 and not w["floating"] and not w["fullscreen"]]
        orientation = workspace["masterOrientation"]
        if workspace["layout"] == "master" and len(tiled) >= 2 and orientation in ("left", "right", "top", "bottom"):
            horizontal = orientation in ("left", "right")
            axis, cross = (0, 1) if horizontal else (1, 0)
            # Support the common single-master arrangement; do not guess at multi-master grids.
            if all(w.get("at") and w.get("size") for w in tiled):
                extreme = (max if orientation in ("right", "bottom") else min)(w["at"][axis] for w in tiled)
                masters = [w for w in tiled if w["at"][axis] == extreme]
                if len(masters) == 1:
                    master = masters[0]
                    low = min(w["at"][axis] for w in tiled)
                    high = max(w["at"][axis] + w["size"][axis] for w in tiled)
                    order = [master] + sorted([w for w in tiled if w is not master], key=lambda w: w["at"][cross])
                    workspace["masterPlacement"] = {
                        "order": [w["savedAddress"] for w in order],
                        "orientation": orientation,
                        "ratio": master["size"][axis] / max(1, high - low),
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
    elif name == "movetoworkspace":
        code = ("hl.dsp.window.move({ window = " + lua_string(parameter)
                + ", workspace = " + lua_string(extra) + ", follow = false })")
    elif name == "fullscreenstate":
        code = ("hl.dsp.window.fullscreen_state({ window = " + lua_string(parameter)
                + f", internal = {int(extra)}, client = {int(extra)} }})")
    elif name == "layout":
        code = "hl.dsp.layout(" + lua_string(parameter) + ")"
    elif name == "swap":
        code = "hl.dsp.window.swap({ target = " + lua_string(parameter) + " })"
    else:
        raise RuntimeError(f"Unsupported Hyprland action: {name}")

    result = run_hyprctl("dispatch", code, required=False)
    if result.returncode != 0:
        message = result.stderr.strip() or result.stdout.strip()
        print(f"hyprctl dispatch {name} {parameter}: {message or 'failed'}", file=sys.stderr)
        return False
    return True


def option(name, field):
    result = run_hyprctl("-j", "getoption", name, required=False)
    try:
        return json.loads(result.stdout).get(field)
    except (ValueError, AttributeError):
        return None


def app_class(client):
    return client.get("initialClass") or client.get("class") or ""


def startup_options(saved):
    if not isinstance(saved, dict):
        raise ValueError("each window must be an object")
    startup = saved.get("startup")
    if startup is None:
        return {}
    if not isinstance(startup, dict):
        raise ValueError("startup must be an object")
    argv = startup.get("argv")
    if not isinstance(argv, list) or not argv or any(
            not isinstance(arg, str) or "\0" in arg for arg in argv) or not argv[0]:
        raise ValueError("startup.argv must be a nonempty array of command arguments")
    for key in ("cwd", "class"):
        if key in startup and (not isinstance(startup[key], str) or not startup[key]
                               or "\0" in startup[key]):
            raise ValueError(f"startup.{key} must be a nonempty string")
    return startup


def preserve_startups(previous, windows):
    claimed = set()
    for saved in previous:
        startup = startup_options(saved)
        if not startup:
            continue
        available = [i for i in range(len(windows)) if i not in claimed]
        exact = [i for i in available if saved.get("savedAddress")
                 and windows[i].get("savedAddress") == saved["savedAddress"]
                 and app_class(windows[i]) == app_class(saved)]
        identified = [i for i in available if startup.get("class")
                      and app_class(windows[i]) == startup["class"]]
        titled = [i for i in available if app_class(windows[i]) == app_class(saved)
                  and windows[i].get("title") == saved.get("title")
                  and workspace_selector(windows[i]["workspace"]) ==
                  workspace_selector(saved.get("workspace") or {})]
        candidates = exact or identified or titled
        if len(candidates) == 1:
            index = candidates[0]
            windows[index]["startup"] = startup
            claimed.add(index)
        else:
            # Keep settings for a closed or ambiguous window rather than lose
            # them or attach its command to an unrelated terminal.
            print(f"Retaining unmatched startup entry for {app_class(saved)}", file=sys.stderr)
            windows.append(dict(saved))
            claimed.add(len(windows) - 1)


def launch_argv(saved):
    startup = startup_options(saved)
    if startup:
        return startup["argv"]
    # Steam's UI belongs to steamwebhelper, whose arguments refer to a dead
    # parent process after logout. Ask the public launcher to show the UI.
    if app_class(saved).lower() == "steam":
        return ["steam", "steam://open/main"]
    return saved.get("argv") or []


def match_existing(saved, claimed):
    current = clients_now()
    if saved.get("startup"):
        same_live_window = [c for c in current if c.get("address") not in claimed
                            and c.get("address") == saved.get("savedAddress")
                            and c.get("pid") == saved.get("pid")
                            and app_class(c) == app_class(saved)]
        if len(same_live_window) == 1:
            return same_live_window[0]
    candidates = [c for c in current
                  if c.get("address") not in claimed and window_matches(saved, c)]
    if startup_options(saved).get("class") and len(candidates) == 1:
        return candidates[0]
    # Exact titles first, then same workspace. Never consume a window twice.
    title = saved.get("title")
    exact = [c for c in candidates if title and c.get("title") == title]
    if exact:
        return max(exact, key=lambda c: workspace_selector(c.get("workspace") or {}) ==
                   workspace_selector(saved.get("workspace") or {}))
    same_ws = [c for c in candidates if workspace_selector(c.get("workspace") or {}) ==
               workspace_selector(saved.get("workspace") or {})]
    return same_ws[0] if same_ws else None


def clients_now():
    try:
        return hypr_json("clients")
    except RuntimeError as exc:
        print(f"Could not refresh window list: {exc}", file=sys.stderr)
        return []


def window_matches(saved, client):
    wanted_class = startup_options(saved).get("class", app_class(saved))
    if app_class(client) != wanted_class:
        return False
    # Steam maps startup/dialog windows before its main UI, and may reuse an
    # existing window after its launcher exits. Wait for the saved UI title.
    if app_class(saved).lower() == "steam" and saved.get("title"):
        return client.get("title") == saved["title"]
    return True


def restore_window(saved, claimed):
    ws = saved.get("workspace") or {}
    selector = workspace_selector(ws)
    wanted_class = app_class(saved)
    if not wanted_class:
        print("Skipping window with no application class", file=sys.stderr)
        return
    opened = match_existing(saved, claimed)
    if opened is not None:
        return place_window(saved, opened, claimed)

    argv = launch_argv(saved)
    if not argv:
        print(f"Skipping {wanted_class or 'window'}: its process command was unavailable at save time", file=sys.stderr)
        return

    monitor = ws.get("monitor") or ""
    known_monitors = {m.get("name") for m in hypr_json("monitors")}
    if monitor and monitor in known_monitors:
        dispatch("focusmonitor", monitor)
    elif monitor:
        print(f"Monitor {monitor!r} is not connected; opening {wanted_class or argv[0]} on the current monitor")

    dispatch("workspace", selector)
    before = {str(c.get("address")) for c in clients_now()}
    cwd = startup_options(saved).get("cwd", saved.get("cwd"))
    if saved.get("startup") and cwd and not os.path.isdir(cwd):
        raise RuntimeError(f"Startup working directory does not exist: {cwd}")
    if not cwd or not os.path.isdir(cwd):
        cwd = str(pathlib.Path.home())
    try:
        process = subprocess.Popen(argv, cwd=cwd, start_new_session=True)
    except (FileNotFoundError, PermissionError, OSError) as exc:
        print(f"Could not launch {argv[0]!r}: {exc}", file=sys.stderr)
        return

    is_steam = wanted_class.lower() == "steam"
    poll_seconds = STEAM_POLL_SECONDS if is_steam else POLL_SECONDS
    deadline = time.monotonic() + poll_seconds
    opened = None
    while time.monotonic() < deadline:
        time.sleep(0.4)
        current = clients_now()
        new_clients = [c for c in current if str(c.get("address")) not in before]
        # Steam's single-instance launcher can reopen or retitle a window that
        # was already present before launch, so its address need not be new.
        matches = [c for c in (current if is_steam else new_clients)
                   if window_matches(saved, c)]
        matches = [c for c in matches if c.get("address") not in claimed]
        if len(matches) > 1:
            exact = [c for c in matches if c.get("title") == saved.get("title")]
            matches = exact if len(exact) == 1 else []
        if matches:
            opened = matches[-1]
            break
        if process.poll() is not None and not new_clients:
            # A launcher may exit after handing the request to an existing app.
            time.sleep(0.8)

    if opened is None:
        print(f"No new window detected for {wanted_class or argv[0]} after {poll_seconds}s; it may be a single-instance app or a helper process", file=sys.stderr)
        return

    return place_window(saved, opened, claimed)


def place_window(saved, opened, claimed):
    selector = workspace_selector(saved.get("workspace") or {})
    wanted_class = app_class(saved)
    address = str(opened.get("address", ""))
    if not address:
        print(f"Opened {wanted_class or 'window'}, but Hyprland returned no window address", file=sys.stderr)
        return

    claimed.add(address)
    if not dispatch("movetoworkspace", "address:" + address, selector):
        raise RuntimeError(f"Could not place {wanted_class} on workspace {selector}")
    if opened.get("fullscreen"):
        dispatch("fullscreenstate", "address:" + address, "0")
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

    for prop in ("pseudo", "pinned"):
        if bool(saved.get(prop)) != bool(opened.get(prop)):
            dispatch("pin" if prop == "pinned" else prop, "address:" + address,
                     "set" if saved.get(prop) else "unset")
    print(f"Placed {wanted_class or 'window'} on workspace {selector}")
    return address


def restore_master_layouts(state, restored):
    addresses = {saved.get("savedAddress"): address for saved, address in restored}
    current_workspaces = {workspace_selector(w): w for w in hypr_json("workspaces")}
    for workspace in state.get("workspaces", []):
        placement = workspace.get("masterPlacement")
        selector = workspace_selector(workspace)
        if not placement:
            continue
        current = current_workspaces.get(selector, {})
        layout = current.get("tiledLayout") or current.get("layout") or option("general:layout", "str")
        if layout != "master":
            print(f"Skipping master arrangement on {selector}: current layout is {layout!r}")
            continue
        order = [addresses.get(a) for a in placement["order"]]
        if not all(order):
            print(f"Skipping master arrangement on {selector}: some windows did not restore")
            continue
        orientation = placement["orientation"]
        axis, cross = (0, 1) if orientation in ("left", "right") else (1, 0)
        dispatch("workspace", selector)
        dispatch("layout", "orientation" + orientation)
        dispatch("layout", f"mfact exact {max(0.1, min(0.9, placement['ratio'])):.5f}")
        # Read actual geometry after each swap; client enumeration is not layout order.
        for index, wanted in enumerate(order):
            current = [c for c in clients_now()
                       if workspace_selector(c.get("workspace") or {}) == selector
                       and not c.get("floating")]
            if len(current) != len(order) or any(not c.get("at") for c in current):
                print(f"Skipping remaining master order on {selector}: window set changed")
                break
            extreme = (max if orientation in ("right", "bottom") else min)(c["at"][axis] for c in current)
            masters = [c for c in current if c["at"][axis] == extreme]
            if len(masters) != 1:
                print(f"Skipping master order on {selector}: multiple masters are unsupported")
                break
            master = masters[0]
            slots = [master] + sorted([c for c in current if c is not master], key=lambda c: c["at"][cross])
            occupant = slots[index]["address"]
            if occupant != wanted:
                dispatch("focuswindow", "address:" + wanted)
                dispatch("swap", "address:" + occupant)


def restore_session(path):
    try:
        state = json.loads(path.read_text(encoding="utf-8"))
    except FileNotFoundError:
        raise RuntimeError(f"No saved session at {path}; run 'hypr-session.sh save' first")
    except json.JSONDecodeError as exc:
        raise RuntimeError(f"Saved session is not valid JSON: {exc}")
    if state.get("version") not in (1, 2):
        raise RuntimeError(f"Unsupported session file version: {state.get('version')!r}")
    try:
        for saved in state.get("windows", []):
            startup_options(saved)
    except ValueError as exc:
        raise RuntimeError(f"Invalid startup settings: {exc}")

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

    claimed = set()
    windows = state.get("windows", [])
    restored = []
    for saved in windows:
        address = restore_window(saved, claimed)
        if address:
            restored.append((saved, address))
    restore_master_layouts(state, restored)
    for saved, address in restored:
        dispatch("fullscreenstate", "address:" + address, str(int(saved.get("fullscreen", 0))))

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
                   and (not wanted_title or c.get("title") == wanted_title)
                   and workspace_selector(c.get("workspace") or {}) == active_selector]
        if matches:
            dispatch("focuswindow", "address:" + str(matches[-1].get("address", "")))
    print(f"Session restore finished: placed {len(restored)}/{len(windows)} saved windows.")
    print("Check the reported skips and launch failures; dwindle split trees are not reconstructed.")


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
