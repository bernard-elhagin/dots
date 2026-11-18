"""Isolated installer rehearsal: no packages, live services or real home mutations."""
import json
import os
from pathlib import Path
import shutil
import subprocess
import tarfile
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]


class DesktopRestoreTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix='desktop-rehearsal-')
        self.addCleanup(self.temp.cleanup)
        self.base = Path(self.temp.name)
        self.repo = self.base / 'dots'
        self.repo.mkdir()
        paths = subprocess.check_output(['git', 'ls-files', '-z', '--cached', '--others', '--exclude-standard'], cwd=ROOT).split(b'\0')
        for raw in paths:
            if not raw:
                continue
            source = ROOT / os.fsdecode(raw)
            if not source.is_file():
                continue
            target = self.repo / os.fsdecode(raw)
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(source, target, follow_symlinks=False)
        self.home = self.base / 'home'
        self.home.mkdir()
        self.env = dict(os.environ, HOME=str(self.home), XDG_CONFIG_HOME=str(self.home / '.config'),
                        XDG_DATA_HOME=str(self.home / '.local/share'), XDG_STATE_HOME=str(self.home / '.local/state'))

    def run_command(self, *args, **kwargs):
        return subprocess.run(args, cwd=self.repo, env=self.env, text=True, capture_output=True, check=True, **kwargs)

    def test_full_install_twice_and_preserve_local_plugin_directory(self):
        plugins = self.home / '.tmux/plugins/tpm'
        plugins.mkdir(parents=True)
        (plugins / 'keep').write_text('existing plugin')
        conflict = self.home / '.config/haruna/haruna.conf'
        conflict.parent.mkdir(parents=True)
        conflict.write_text('previous settings')
        self.run_command('bash', 'install.sh')
        backups = list(self.home.rglob('*.backup-*'))
        self.assertTrue(any(p.read_text() == 'previous settings' for p in backups if p.is_file()))
        self.run_command('bash', 'install.sh')
        self.assertEqual(backups, list(self.home.rglob('*.backup-*')))
        self.assertEqual((plugins / 'keep').read_text(), 'existing plugin')
        self.assertEqual((self.home / '.config/openrgb/profiles').resolve(), self.repo / 'config/openrgb/profiles')
        self.assertEqual((self.home / '.local/bin/desktop-session-startup').resolve(), self.repo / 'bin/desktop-session-startup')
        self.assertFalse(conflict.is_symlink())
        self.assertNotIn('LastPlayedFile', conflict.read_text())
        self.assertEqual(conflict.stat().st_mode & 0o777, 0o600)
        broken = [p for p in self.home.rglob('*') if p.is_symlink() and not p.exists()]
        self.assertEqual(broken, [])

    def test_desktop_only_includes_helper_bin_and_application_preferences(self):
        self.run_command('bash', 'install.sh', '--desktop-only')
        self.assertTrue((self.home / 'bin/steam_launcher.sh').is_file())
        self.assertTrue((self.home / '.config/flameshot/flameshot.ini').is_file())
        self.assertTrue((self.home / '.config/haruna/shortcuts.conf').is_file())
        self.assertFalse((self.home / '.zshrc').exists())

    def test_private_backup_restore_and_reject_unexpected_archive(self):
        session = self.home / '.config/hypr/session.json'
        session.parent.mkdir(parents=True)
        session.write_text(json.dumps({'version': 2, 'windows': []}))
        original = session.read_bytes()
        archive = self.base / 'private.tar.gz'
        self.run_command('bash', 'bin/desktop-backup', '--output', str(archive))
        self.assertEqual(archive.stat().st_mode & 0o777, 0o600)
        session.write_text('changed')
        self.run_command('bash', 'bin/desktop-backup', '--restore', str(archive))
        self.assertEqual(original, session.read_bytes())
        self.assertTrue(list(session.parent.glob('session.json.backup-*')))
        bad = self.base / 'bad.tar.gz'
        with tarfile.open(bad, 'w:gz') as output:
            output.addfile(tarfile.TarInfo('../escape'))
        result = subprocess.run(['bash', 'bin/desktop-backup', '--restore', str(bad)], cwd=self.repo, env=self.env, capture_output=True)
        self.assertNotEqual(result.returncode, 0)
        self.assertFalse((self.home.parent / 'escape').exists())

    def test_package_installation_with_mocked_system_commands(self):
        tools = self.base / 'tools'
        tools.mkdir()
        log = self.base / 'transactions'
        stubs = {
            'pacman': 'if [[ $1 == -Si ]]; then case $2 in bibata-cursor-theme-bin|tidal-hifi-bin) exit 1;; esac; exit 0; fi\nprintf "pacman %s\\n" "$*" >> "$TEST_LOG"\n',
            'sudo': 'exec "$@"\n',
            'yay': 'printf "yay %s\\n" "$*" >> "$TEST_LOG"\n',
        }
        for name, body in stubs.items():
            path = tools / name
            path.write_text('#!/bin/bash\n' + body)
            path.chmod(0o755)
        env = dict(self.env, PATH=str(tools) + ':' + os.environ['PATH'], TEST_LOG=str(log))
        subprocess.run(['bash', 'packages.sh', 'desktop', 'media', 'desktop'], cwd=self.repo, env=env, check=True, capture_output=True)
        commands = log.read_text().splitlines()
        self.assertEqual(len(commands), 2)
        self.assertTrue(commands[0].startswith('pacman -Syu --needed'))
        args = commands[0].split()[3:]
        self.assertEqual(len(args), len(set(args)))
        self.assertIn('mako', args)
        self.assertIn('perl', args)
        self.assertIn('curl', args)
        self.assertIn('tidal-hifi-bin', commands[1])

    def test_keyboard_schedule_with_managed_profiles_and_mocked_hardware(self):
        tools = self.base / 'tools'
        tools.mkdir()
        log = self.base / 'rgb-arguments'
        for name, body in {
            'date': 'printf "%s\\n" "$TEST_DAY"\n',
            'openrgb': 'printf "%s\\n" "$@" > "$TEST_LOG"\n',
        }.items():
            path = tools / name
            path.write_text('#!/bin/bash\n' + body)
            path.chmod(0o755)
        for day in range(1, 8):
            env = dict(self.env, PATH=str(tools) + ':' + os.environ['PATH'],
                       OPENRGB_PROFILE_DIR=str(self.repo / 'config/openrgb/profiles'),
                       TEST_DAY=str(day), TEST_LOG=str(log))
            subprocess.run(['bash', 'bin/openrgb-keyboard-startup'], cwd=self.repo, env=env, check=True, capture_output=True)
            arguments = log.read_text().splitlines()
            self.assertIn('--noautoconnect', arguments)
            self.assertIn('SteelSeries Apex 3 TKL', arguments)
            profile = 'cyan' if day <= 4 else 'friday'
            controller = json.loads((self.repo / f'config/openrgb/profiles/{profile}.json').read_text())['controllers'][0]
            expected = ','.join(f'{c & 255:02X}{(c >> 8) & 255:02X}{(c >> 16) & 255:02X}' for c in controller['colors'])
            self.assertEqual(arguments[arguments.index('--color') + 1], expected)

    def test_service_setup_is_opt_in_and_does_not_start_or_restart_services(self):
        tools = self.base / 'tools'
        tools.mkdir()
        log = self.base / 'service-commands'
        for name, body in {
            'systemctl': 'printf "systemctl %s\\n" "$*" >> "$TEST_LOG"\n',
            'sudo': 'printf "sudo %s\\n" "$*" >> "$TEST_LOG"\n',
            'getent': 'exit 0\n',
        }.items():
            path = tools / name
            path.write_text('#!/bin/bash\n' + body)
            path.chmod(0o755)
        env = dict(self.env, PATH=str(tools) + ':' + os.environ['PATH'], TEST_LOG=str(log))
        subprocess.run(['bash', 'bin/desktop-setup'], cwd=self.repo, env=env, check=True, capture_output=True)
        self.assertFalse(log.exists())
        subprocess.run(['bash', 'bin/desktop-setup', '--apply', '--serial'], cwd=self.repo, env=env, check=True, capture_output=True)
        commands = log.read_text()
        self.assertIn('enable NetworkManager.service', commands)
        self.assertIn('usermod -aG uucp', commands)
        self.assertNotIn(' restart ', commands)
        self.assertNotIn(' start ', commands)


if __name__ == '__main__':
    unittest.main()
