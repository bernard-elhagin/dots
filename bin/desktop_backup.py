"""Private, allowlisted desktop state archives; never extracts arbitrary tar paths."""
import argparse
import datetime
import io
import os
from pathlib import Path
import tarfile
import tempfile

HOME_FILES = (
    '.config/hypr/session.json',
    '.config/haruna/haruna.conf', '.config/haruna/shortcuts.conf',
    '.config/haruna/custom-commands.conf', '.config/flameshot/flameshot.ini',
    '.config/systemd/user/arch-update.timer',
)
SYSTEM_FILES = (
    'etc/openrgb/OpenRGB.json', 'etc/openrgb/Configuration.json',
    'etc/openrgb/profiles/cyan.json', 'etc/openrgb/profiles/friday.json',
)
ALLOWED = {'home/' + p for p in HOME_FILES} | set(SYSTEM_FILES)


def stamp():
    return datetime.datetime.now().strftime('%Y%m%d-%H%M%S-%f')


def atomic_private_write(destination, data):
    destination.parent.mkdir(parents=True, exist_ok=True)
    # Parent symlinks could otherwise redirect private restores into the repository.
    if destination.parent.resolve() != destination.parent.absolute():
        raise ValueError(f'Refusing restore through a symlinked parent: {destination}')
    fd, temporary = tempfile.mkstemp(dir=destination.parent, prefix='.desktop-restore-')
    try:
        with os.fdopen(fd, 'wb') as output:
            output.write(data)
        if os.path.lexists(destination):
            destination.rename(destination.with_name(destination.name + '.backup-' + stamp()))
        os.replace(temporary, destination)
    finally:
        if os.path.exists(temporary):
            os.unlink(temporary)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--restore', type=Path, metavar='ARCHIVE')
    parser.add_argument('--output', type=Path, help='New archive path; default is private local state directory')
    args = parser.parse_args()
    home = Path.home()
    state = Path(os.environ.get('XDG_STATE_HOME', str(home / '.local/state')))
    if args.restore:
        if args.output:
            parser.error('--output cannot be combined with --restore')
        staged = state / ('desktop-restored-system/' + stamp())
        with tarfile.open(args.restore, 'r:gz') as archive:
            members = archive.getmembers()
            names = [m.name for m in members]
            if len(set(names)) != len(names):
                raise ValueError('Duplicate archive members')
            payloads = []
            for member in members:
                if member.name not in ALLOWED or not member.isfile() or member.size > 16 * 1024 * 1024:
                    raise ValueError(f'Unexpected archive member: {member.name}')
                payloads.append((member.name, archive.extractfile(member).read()))
        for name, data in payloads:
            destination = home / name[5:] if name.startswith('home/') else staged / name
            if not name.startswith('home/'):
                staged.mkdir(parents=True, exist_ok=True, mode=0o700)
            atomic_private_write(destination, data)
        print('Restored private home configuration; previous files were backed up.')
        if any(not n.startswith('home/') for n, _ in payloads):
            print(f'System files staged privately for review, not applied: {staged}')
        return
    output = args.output or state / ('desktop-backups/desktop-' + stamp() + '.tar.gz')
    output = output.expanduser().absolute()
    output.parent.mkdir(parents=True, exist_ok=True, mode=0o700)
    count = 0
    fd = os.open(output, os.O_CREAT | os.O_EXCL | os.O_WRONLY, 0o600)
    try:
        with os.fdopen(fd, 'wb') as stream, tarfile.open(fileobj=stream, mode='w:gz') as archive:
            for name in sorted(ALLOWED):
                source = home / name[5:] if name.startswith('home/') else Path('/') / name
                if not source.is_file():
                    continue
                data = source.read_bytes()
                member = tarfile.TarInfo(name)
                member.mode = 0o600
                member.size = len(data)
                archive.addfile(member, io.BytesIO(data))
                count += 1
    except BaseException:
        output.unlink(missing_ok=True)
        raise
    print(f'Saved {count} private state files: {output}')


if __name__ == '__main__':
    try:
        main()
    except (OSError, ValueError, tarfile.TarError) as error:
        raise SystemExit(f'desktop-backup: {error}')
