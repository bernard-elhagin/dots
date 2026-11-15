#!/usr/bin/env bash
set -euo pipefail

usage() {
    printf 'Usage: %s [search words...]\n       %s --list\n' "${0##*/}" "${0##*/}"
    printf 'Open a temporary floating picker; Enter launches on workspace 3, Esc cancels.\n'
}

case "${1:-}" in
    -h|--help) usage; exit 0 ;;
esac

if [[ "${1:-}" == --picker ]]; then
    shift
elif [[ "${1:-}" != --list ]]; then
    command -v xfce4-terminal >/dev/null 2>&1 || {
        printf 'Missing required command: xfce4-terminal\n' >&2
        exit 1
    }
    script_path="$(readlink -f -- "${BASH_SOURCE[0]}")"
    exec xfce4-terminal --disable-server --class=SteamLauncher \
        --title='Steam Launcher' --geometry=100x28 --hide-menubar \
        --hide-toolbar --hide-scrollbar --execute bash "$script_path" --picker "$@"
fi

for dependency in python3; do
    command -v "$dependency" >/dev/null 2>&1 || {
        printf 'Missing required command: %s\n' "$dependency" >&2
        exit 1
    }
done

# Read Steam's local metadata; no API key, network request, or credentials needed.
games="$(python3 - <<'PY'
import os
import json
import pathlib
import re
import sys


def read_vdf(path):
    text = path.read_text(encoding="utf-8-sig", errors="replace")
    tokens = re.findall(r'"(?:\\.|[^"\\])*"|[{}]|//[^\n]*', text)
    tokens = iter(t for t in tokens if not t.startswith('//'))

    def string(token):
        if not token.startswith('"'):
            raise ValueError('Expected quoted VDF string')
        return re.sub(r'\\(["\\])', r'\1', token[1:-1])

    def object_(nested=False):
        result = {}
        for token in tokens:
            if token == '}':
                if not nested:
                    raise ValueError('Unexpected closing brace')
                return result
            key = string(token)
            value = next(tokens)
            result[key] = object_(True) if value == '{' else string(value)
        if nested:
            raise ValueError('Unclosed VDF object')
        return result

    return object_()


home = pathlib.Path.home()
data = pathlib.Path(os.environ.get('XDG_DATA_HOME') or home / '.local/share')
roots = [data / 'Steam', home / '.steam/steam', home / '.steam/root',
         home / '.var/app/com.valvesoftware.Steam/.local/share/Steam']
libraries = set()
for root in roots:
    if not root.is_dir():
        continue
    libraries.add(root.resolve())
    path = root / 'steamapps/libraryfolders.vdf'
    try:
        folders = read_vdf(path).get('libraryfolders', {})
        for key, entry in folders.items():
            if not key.isdigit():
                continue
            location = entry.get('path') if isinstance(entry, dict) else entry
            if location:
                libraries.add(pathlib.Path(location).expanduser().resolve())
    except (OSError, ValueError, StopIteration, AttributeError) as exc:
        print(f'Could not read {path}: {exc}', file=sys.stderr)

games = {}
for library in sorted(libraries):
    for manifest in sorted((library / 'steamapps').glob('appmanifest_*.acf')):
        try:
            app = read_vdf(manifest)['AppState']
            appid, name = app['appid'], app['name']
            if not appid.isdigit() or not int(app.get('StateFlags', '0')) & 4:
                continue
            if not (library / 'steamapps/common' / app['installdir']).is_dir():
                continue
            # Compatibility runtimes and redistributables are not launchable games.
            if appid == '228980' or name.casefold().startswith(('proton', 'steam linux runtime')):
                continue
            name = ''.join(' ' if ord(c) < 32 or ord(c) == 127 else c for c in name)
            games[appid] = name
        except (OSError, ValueError, StopIteration, KeyError, TypeError) as exc:
            print(f'Skipping {manifest.name}: {exc}', file=sys.stderr)

state = pathlib.Path(os.environ.get('XDG_STATE_HOME') or home / '.local/state')
history_path = state / 'steam-launcher/launch-counts.json'
try:
    history = json.loads(history_path.read_text())
    if not isinstance(history, dict) or any(
        not isinstance(v, int) or isinstance(v, bool) or v < 0 for v in history.values()
    ):
        raise ValueError('Expected nonnegative launch counts')
except FileNotFoundError:
    history = {}
except (OSError, ValueError) as exc:
    print(f'Could not read launch history: {exc}', file=sys.stderr)
    history = {}

for appid, name in sorted(games.items(), key=lambda pair: (
    -history.get(pair[0], 0), pair[1].casefold(), pair[0]
)):
    print(f'{appid}\t{name}')
PY
)"

if [[ -z "$games" ]]; then
    printf 'No installed Steam games found in your Steam libraries.\n' >&2
    exit 1
fi

if [[ "${1:-}" == --list ]]; then
    printf '%s\n' "$games"
    exit 0
fi

for dependency in fzf steam; do
    command -v "$dependency" >/dev/null 2>&1 || {
        printf 'Missing required command: %s\n' "$dependency" >&2
        exit 1
    }
done

if selection="$(printf '%s\n' "$games" | fzf --no-multi --delimiter=$'\t' \
    --with-nth=2.. --tiebreak=index --query="$*" --prompt='Steam > ' \
    --header='Frequent first, then A–Z | Enter: launch on workspace 3 | Esc: cancel' --height=100% --layout=reverse)"; then
    [[ -n "$selection" ]] || exit 0
else
    result=$?
    [[ "$result" == 1 || "$result" == 130 ]] && exit 0
    exit "$result"
fi

appid="${selection%%$'\t'*}"
if [[ ! "$appid" =~ ^[0-9]+$ ]]; then
    printf 'Invalid Steam App ID returned by the picker.\n' >&2
    exit 1
fi
command -v hyprctl >/dev/null 2>&1 || {
    printf 'Missing required command: hyprctl\n' >&2
    exit 1
}
if ! workspace_result="$(hyprctl dispatch 'hl.dsp.workspace.move({ workspace = "3", monitor = "DP-1" })' 2>&1)"; then
    printf 'Could not move workspace 3 to DP-1: %s\n' "$workspace_result" >&2
    exit 1
fi
if ! workspace_result="$(hyprctl dispatch 'hl.dsp.focus({ workspace = 3 })' 2>&1)"; then
    printf 'Could not switch to workspace 3: %s\n' "$workspace_result" >&2
    exit 1
fi
printf 'Launching %s...\n' "${selection#*$'\t'}"
# Steam must survive this temporary terminal closing, even on a cold start.
python3 - "$appid" <<'PY'
import subprocess
import sys
import fcntl
import json
import os
import pathlib
import tempfile

subprocess.Popen(
    ["steam", "steam://rungameid/" + sys.argv[1]],
    stdin=subprocess.DEVNULL,
    stdout=subprocess.DEVNULL,
    stderr=subprocess.DEVNULL,
    start_new_session=True,
)

# Count successful launch requests, not picker openings or cancelled selections.
# Lock the read/modify/write and replace atomically for overlapping launchers.
state = pathlib.Path(os.environ.get('XDG_STATE_HOME') or pathlib.Path.home() / '.local/state')
directory = state / 'steam-launcher'
try:
    directory.mkdir(parents=True, exist_ok=True)
    with (directory / 'history.lock').open('a') as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        path = directory / 'launch-counts.json'
        try:
            history = json.loads(path.read_text())
            if not isinstance(history, dict) or any(
                not isinstance(v, int) or isinstance(v, bool) or v < 0 for v in history.values()
            ):
                raise ValueError('Expected nonnegative launch counts')
        except FileNotFoundError:
            history = {}
        history[sys.argv[1]] = history.get(sys.argv[1], 0) + 1
        temporary = None
        try:
            with tempfile.NamedTemporaryFile(mode='w', dir=directory, delete=False) as output:
                temporary = pathlib.Path(output.name)
                json.dump(history, output)
                output.write('\n')
            temporary.replace(path)
        finally:
            if temporary is not None:
                temporary.unlink(missing_ok=True)
except (OSError, ValueError) as exc:
    print(f'Game launch requested, but history could not be updated: {exc}', file=sys.stderr)
PY
