import argparse
import configparser
import ctypes
import datetime
import errno
import fcntl
import hashlib
import json
import os
from pathlib import Path
import shutil
import shlex
import signal
import subprocess
import sys
import tempfile
import time
import xml.etree.ElementTree as ET

VIDEO_EXTENSIONS = {
    '.mkv', '.mp4', '.avi', '.mov', '.m4v', '.webm', '.mpg', '.mpeg',
    '.mpe', '.m2v', '.ts', '.m2ts', '.mts', '.wmv', '.flv', '.vob',
    '.ogv', '.3gp', '.3g2', '.divx', '.asf', '.rm', '.rmvb', '.f4v',
    '.mpv', '.mxf',
}
DEFAULT_DIRECTORY = '/run/media/bertold/Media/Video/TV/Looney Tunes'
HOOK_STARTUP_SECONDS = 20
SIDECAR_EXTENSIONS = {'.nfo', '.jpg', '.jpeg', '.png', '.webp', '.srt', '.ass', '.ssa', '.vtt', '.sub', '.idx', '.sup'}


def terminate(signum, frame):
    raise SystemExit(128 + signum)


def scan_videos(root, include_marked=False):
    candidates = []
    errors = []
    count = 0
    for directory, _, files in os.walk(root, onerror=lambda error: errors.append(str(error))):
        for name in files:
            video = Path(directory) / name
            if (name.startswith('_') and not include_marked) or video.suffix.lower() not in VIDEO_EXTENSIONS:
                continue
            count += 1
            if video.is_symlink():
                errors.append(f'Refusing symbolic-link video: {video}')
                continue
            nfo = video.with_suffix('.nfo')
            if name.startswith('_') and not nfo.exists():
                # Support videos marked by the original video-only launcher.
                nfo = video.with_name(video.name[1:]).with_suffix('.nfo')
            try:
                aired = ET.parse(nfo).getroot().findtext('aired')
                date = datetime.date.fromisoformat((aired or '').strip())
            except (OSError, ET.ParseError, ValueError) as error:
                errors.append(f'Cannot determine aired date from {nfo}: {error}')
                continue
            relative = str(video.relative_to(root))
            candidates.append((date, relative.casefold(), relative, video))
    return candidates, errors, count


def select_video(root):
    candidates, errors, _ = scan_videos(root)
    if errors:
        raise ValueError('\n'.join(errors))
    return min(candidates) if candidates else None


def compatible_command(command):
    """Conservatively allow presentation properties, never playback-control commands."""
    if any(c in command for c in ';\n\r'):
        return False
    try:
        parts = shlex.split(command)
    except ValueError:
        return False
    safe = {'volume', 'volume-max', 'mute', 'speed', 'af', 'vf', 'hwdec', 'deinterlace',
            'brightness', 'contrast', 'gamma', 'saturation', 'hue', 'panscan',
            'aid', 'sid', 'vid', 'secondary-sid'}
    return (len(parts) >= 3 and parts[0] in ('set', 'set_property', 'set-property')
            and (parts[1] in safe or parts[1].startswith(('audio-', 'sub-', 'video-'))))


def kconfig_unescape(value):
    escapes = {'n': '\n', 'r': '\r', 't': '\t', 's': ' ', '\\': '\\'}
    result = []
    index = 0
    while index < len(value):
        if value[index] == '\\' and index + 1 < len(value) and value[index + 1] in escapes:
            index += 1
            result.append(escapes[value[index]])
        else:
            result.append(value[index])
        index += 1
    return ''.join(result)


def write_custom_commands(source, destination, hook):
    original = configparser.ConfigParser(interpolation=None, strict=False)
    original.optionxform = str
    original.read(source)
    commands = configparser.ConfigParser(interpolation=None)
    commands.optionxform = str
    for group in original.sections():
        values = dict(original.items(group))
        if compatible_command(kconfig_unescape(values.get('Command', ''))):
            commands[group] = values
        else:
            print(f'Skipping incompatible Haruna custom command: {group}', file=sys.stderr)
    group = 'LooneyNextCompletion'
    while commands.has_section(group):
        group += '_'
    command = 'load-script "' + str(hook).replace('\\', '\\\\').replace('"', '\\"') + '"'
    commands[group] = {'Type': 'startup', 'SetOnStartup': 'true',
                       'Command': command.replace('\\', '\\\\')}
    with destination.open('w', encoding='utf-8') as output:
        commands.write(output, space_around_delimiters=False)


def rename_without_overwrite(source, destination):
    # Linux renameat2 makes the collision check and rename one atomic operation.
    libc = ctypes.CDLL(None, use_errno=True)
    rename = libc.renameat2
    rename.argtypes = [ctypes.c_int, ctypes.c_char_p, ctypes.c_int, ctypes.c_char_p, ctypes.c_uint]
    rename.restype = ctypes.c_int
    if rename(-100, os.fsencode(source), -100, os.fsencode(destination), 1):
        number = ctypes.get_errno()
        raise OSError(number, os.strerror(number), str(destination))


def rename_plan(video, include_sidecars):
    sources = []
    if include_sidecars:
        for sibling in sorted(video.parent.iterdir()):
            if (sibling.suffix.lower() in SIDECAR_EXTENSIONS
                    and (sibling.name.startswith(video.stem + '.')
                         or sibling.name.startswith(video.stem + '-'))):
                sources.append(sibling)
    sources.append(video)  # Mark the video last, after its sidecars.
    plan = []
    for source in sources:
        if source.is_symlink() or not source.is_file():
            raise ValueError(f'Refusing non-regular file: {source}')
        destination = source.with_name('_' + source.name)
        if os.path.lexists(destination):
            raise FileExistsError(errno.EEXIST, 'Marked filename already exists', str(destination))
        plan.append((source, destination, source.stat()))
    return plan


def unchanged(path, before):
    after = path.lstat()
    return (before.st_dev, before.st_ino, before.st_size, before.st_mtime_ns) == (
        after.st_dev, after.st_ino, after.st_size, after.st_mtime_ns)


def mark_watched(plan, journal):
    for source, _, before in plan:
        if not unchanged(source, before):
            raise ValueError(f'File changed during playback; refusing to rename: {source}')
    fd = os.open(journal, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600)
    with os.fdopen(fd, 'w', encoding='utf-8') as output:
        json.dump([{'source': str(s), 'destination': str(d)} for s, d, _ in plan], output, indent=2)
        output.flush()
        os.fsync(output.fileno())
    completed = []
    try:
        for source, destination, before in plan:
            if not unchanged(source, before):
                raise ValueError(f'File changed before rename: {source}')
            rename_without_overwrite(source, destination)
            completed.append((source, destination, before))
    except BaseException:
        rollback_failed = False
        for source, destination, before in reversed(completed):
            try:
                if not unchanged(destination, before):
                    raise ValueError(f'Renamed file changed: {destination}')
                rename_without_overwrite(destination, source)
            except (OSError, ValueError) as error:
                rollback_failed = True
                print(f'Rollback failed: {error}', file=sys.stderr)
        if rollback_failed:
            print(f'Recovery paths retained in {journal}; resolve them before running again.', file=sys.stderr)
        else:
            journal.unlink()
        raise
    journal.unlink()


def play_video(video):
    with tempfile.TemporaryDirectory(prefix='looney-next-') as directory:
        temporary = Path(directory)
        marker = temporary / 'finished'
        ready = temporary / 'ready'
        script = temporary / 'finished.lua'
        script.write_text('''local active = false
local function finished()
    if active then
        local output = assert(io.open(os.getenv("LOONEY_NEXT_FINISHED"), "w"))
        output:write("finished\\n")
        output:close()
    end
end
mp.register_event("file-loaded", function()
    active = mp.get_property("path") == os.getenv("LOONEY_NEXT_VIDEO")
end)
mp.observe_property("eof-reached", "bool", function(_, value)
    if value then finished() end
end)
mp.register_event("end-file", function(event)
    if event.reason == "eof" then finished() end
    active = false
end)
local ready = assert(io.open(os.getenv("LOONEY_NEXT_READY"), "w"))
ready:write("ready\\n")
ready:close()
''')
        config_home = Path(os.environ.get('XDG_CONFIG_HOME', str(Path.home() / '.config')))
        settings = configparser.ConfigParser(interpolation=None, strict=False)
        settings.optionxform = str
        settings.read(config_home / 'haruna/haruna.conf')
        for group, values in {
            'General': {'UseSingleInstance': 'false', 'FullscreenOnStartUp': 'true'},
            'Playlist': {'LoadSiblings': 'false', 'PlaybackBehavior': 'StopAfterItem'},
            'Playback': {'RestoreFilePosition': 'false'},
        }.items():
            if not settings.has_section(group):
                settings.add_section(group)
            for key, value in values.items():
                settings.set(group, key, value)
        config = temporary / 'config/haruna'
        config.mkdir(parents=True)
        with (config / 'haruna.conf').open('w') as output:
            settings.write(output, space_around_delimiters=False)
        shortcuts = config_home / 'haruna/shortcuts.conf'
        if shortcuts.is_file():
            shutil.copyfile(shortcuts, config / 'shortcuts.conf')
        write_custom_commands(config_home / 'haruna/custom-commands.conf',
                              config / 'custom-commands.conf', script)
        environment = dict(os.environ, LOONEY_NEXT_FINISHED=str(marker), LOONEY_NEXT_READY=str(ready),
                           LOONEY_NEXT_VIDEO=str(video), XDG_CONFIG_HOME=str(config.parent),
                           XDG_DATA_HOME=str(temporary / 'data'), XDG_CACHE_HOME=str(temporary / 'cache'))
        process = subprocess.Popen(['haruna', '--', str(video)], env=environment, start_new_session=True)
        try:
            deadline = time.monotonic() + HOOK_STARTUP_SECONDS
            while process.poll() is None and not marker.is_file():
                if not ready.is_file() and time.monotonic() >= deadline:
                    raise RuntimeError('Haruna completion hook did not start within 20 seconds; filename unchanged')
                time.sleep(0.1)
            if marker.is_file():
                return True
            code = process.wait()
            if code != 0:
                raise RuntimeError(f'Haruna failed with exit status {code}; filename unchanged')
            return False  # Closing Haruna normally before EOF is cancellation.
        finally:
            # Close only the isolated instance launched here, never another player.
            if process.poll() is None:
                process.terminate()
                try:
                    process.wait(timeout=5)
                except subprocess.TimeoutExpired:
                    process.kill()
                    process.wait()


def main():
    parser = argparse.ArgumentParser(prog='looney-next', description='Play one unmarked video, oldest NFO aired date first.')
    parser.add_argument('--directory', type=Path, default=Path(DEFAULT_DIRECTORY))
    modes = parser.add_mutually_exclusive_group()
    modes.add_argument('--dry-run', action='store_true', help='Show the next video without playing or renaming it')
    modes.add_argument('--check', action='store_true', help='Report all video/NFO metadata problems without playing or renaming')
    parser.add_argument('--rename-sidecars', action=argparse.BooleanOptionalAction, default=True,
                        help='Also prefix matching NFO, artwork and subtitle filenames with an underscore')
    args = parser.parse_args()
    root = args.directory.expanduser().resolve(strict=True)
    if not root.is_dir():
        raise ValueError(f'Not a directory: {root}')
    if args.check:
        candidates, errors, count = scan_videos(root, include_marked=True)
        for error in errors:
            print(error, file=sys.stderr)
        print(f'Checked {count} videos: {len(candidates)} valid aired dates; {len(errors)} problems.')
        if errors:
            raise SystemExit(1)
        return
    if args.dry_run:
        show_selection(select_video(root))
        return
    if shutil.which('haruna') is None:
        raise ValueError('Haruna is required')
    state = Path(os.environ.get('XDG_STATE_HOME', str(Path.home() / '.local/state'))) / 'looney-next'
    state.mkdir(parents=True, exist_ok=True)
    key = hashlib.sha256(os.fsencode(root)).hexdigest()
    fd = os.open(state / (key + '.lock'), os.O_CREAT | os.O_RDWR | os.O_NOFOLLOW, 0o600)
    with os.fdopen(fd, 'w') as lock:
        try:
            fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError:
            raise ValueError('Another looney-next instance is already playing from this directory')
        journal = state / (key + '.pending.json')
        if journal.exists():
            raise ValueError(f'An interrupted rename needs review; recovery paths are in {journal}')
        selected = select_video(root)
        show_selection(selected)
        if selected is None:
            return
        video = selected[-1]
        plan = rename_plan(video, args.rename_sidecars)
        if not play_video(video):
            print('Playback cancelled before completion; filename unchanged.')
            return
        mark_watched(plan, journal)
        print(f'Marked watched: {plan[-1][1]}', flush=True)


def show_selection(selected):
    if selected is None:
        print('No unmarked video files remain.')
    else:
        print(f'Aired: {selected[0]}\nNext: {selected[-1]}', flush=True)


if __name__ == '__main__':
    signal.signal(signal.SIGTERM, terminate)
    try:
        main()
    except (OSError, ValueError, RuntimeError, configparser.Error) as error:
        sys.exit(f'looney-next: {error}')
    except KeyboardInterrupt:
        sys.exit(130)
