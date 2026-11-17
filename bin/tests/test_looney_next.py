"""Regression tests use temporary collections and a fake Haruna; no desktop needed."""
import contextlib
import importlib.util
import io
import json
import os
from pathlib import Path
import signal
import subprocess
import tempfile
import time
import unittest
from unittest.mock import patch

SCRIPT = Path(__file__).resolve().parents[1] / 'looney-next'
spec = importlib.util.spec_from_file_location('looney_next', SCRIPT.with_name('looney_next.py'))
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)


class LooneyTests(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory(prefix='looney-test-')
        self.addCleanup(self.directory.cleanup)
        self.base = Path(self.directory.name)
        self.root = self.base / 'videos'
        self.root.mkdir()
        tools = self.base / 'bin'
        tools.mkdir()
        player = tools / 'haruna'
        player.write_text('''#!/usr/bin/env python3
import os,time
from pathlib import Path
mode=os.environ.get('TEST_MODE','cancel')
if mode=='fail':raise SystemExit(23)
if mode=='cancel':raise SystemExit(0)
if mode!='nohook':Path(os.environ['LOONEY_NEXT_READY']).touch()
if mode=='finish':Path(os.environ['LOONEY_NEXT_FINISHED']).touch()
if os.environ.get('TEST_PID'):Path(os.environ['TEST_PID']).write_text(str(os.getpid()))
time.sleep(60)
''')
        player.chmod(0o755)
        self.env = dict(os.environ, PATH=str(tools) + ':' + os.environ['PATH'],
                        XDG_STATE_HOME=str(self.base / 'state'), XDG_CONFIG_HOME=str(self.base / 'config'))

    def video(self, name='Episode', date='1930-01-01'):
        path = self.root / (name + '.mkv')
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_bytes(b'video')
        path.with_suffix('.nfo').write_text(f'<episodedetails><aired>{date}</aired></episodedetails>')
        return path

    def run_launcher(self, *args, mode='cancel'):
        return subprocess.run([str(SCRIPT), '--directory', str(self.root), *args],
                              env=dict(self.env, TEST_MODE=mode), text=True, capture_output=True, timeout=8)

    def test_selection_uses_dates_then_filename_and_skips_marked(self):
        self.video('A newer', '1940-01-01')
        self.video('_already seen', '1900-01-01')
        self.video('nested/Z older', '1930-01-01')
        chosen = self.video('nested/B older', '1930-01-01')
        self.assertEqual(mod.select_video(self.root)[-1], chosen)

    def test_check_reports_all_bad_metadata_and_changes_nothing(self):
        self.video('valid')
        self.video('bad date', 'not-a-date')
        self.video('missing').with_suffix('.nfo').unlink()
        self.video('malformed').with_suffix('.nfo').write_text('<broken')
        before = {p.name: p.read_bytes() for p in self.root.iterdir()}
        result = self.run_launcher('--check')
        self.assertEqual(result.returncode, 1)
        self.assertIn('4 videos: 1 valid aired dates; 3 problems', result.stdout)
        self.assertEqual(before, {p.name: p.read_bytes() for p in self.root.iterdir()})
        self.assertFalse((self.base / 'state').exists())

    def test_check_accepts_original_nfo_for_previously_marked_video(self):
        video = self.video()
        video.rename(video.with_name('_' + video.name))
        self.assertEqual(self.run_launcher('--check').returncode, 0)

    def test_missing_metadata_prevents_playing_later_episode(self):
        self.video('bad').with_suffix('.nfo').unlink()
        self.video('later', '1940-01-01')
        self.assertNotEqual(self.run_launcher(mode='finish').returncode, 0)
        self.assertTrue((self.root / 'later.mkv').exists())

    def test_failure_returns_error_but_cancel_does_not(self):
        video = self.video()
        result = self.run_launcher(mode='fail')
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('23', result.stderr)
        self.assertEqual(self.run_launcher().returncode, 0)
        self.assertTrue(video.exists())

    def test_sidecars_are_default_and_shared_artwork_is_untouched(self):
        video = self.video()
        for name in ('Episode.en.srt', 'Episode-thumb.jpg', 'poster.jpg'):
            (self.root / name).write_bytes(b'art')
        result = self.run_launcher(mode='finish')
        self.assertEqual(result.returncode, 0, result.stderr)
        for name in ('Episode.mkv', 'Episode.nfo', 'Episode.en.srt', 'Episode-thumb.jpg'):
            self.assertTrue((self.root / ('_' + name)).exists())
        self.assertTrue((self.root / 'poster.jpg').exists())
        self.assertFalse(video.exists())

    def test_sidecar_renaming_can_be_disabled(self):
        self.video()
        self.assertEqual(self.run_launcher('--no-rename-sidecars', mode='finish').returncode, 0)
        self.assertTrue((self.root / '_Episode.mkv').exists())
        self.assertTrue((self.root / 'Episode.nfo').exists())

    def test_collision_is_not_overwritten(self):
        video = self.video()
        target = self.root / '_Episode.nfo'
        target.write_bytes(b'existing')
        self.assertNotEqual(self.run_launcher(mode='finish').returncode, 0)
        self.assertEqual(target.read_bytes(), b'existing')
        self.assertTrue(video.exists())

    def test_partial_rename_is_rolled_back(self):
        video = self.video()
        plan = mod.rename_plan(video, True)
        real = mod.rename_without_overwrite
        calls = []

        def fail_second(source, destination):
            calls.append(source)
            if len(calls) == 2:
                raise OSError('simulated failure')
            real(source, destination)

        journal = self.base / 'pending.json'
        with patch.object(mod, 'rename_without_overwrite', side_effect=fail_second):
            with self.assertRaises(OSError):
                mod.mark_watched(plan, journal)
        self.assertTrue(all(s.exists() and not d.exists() for s, d, _ in plan))
        self.assertFalse(journal.exists())

    def test_failed_rollback_retains_recovery_paths(self):
        plan = mod.rename_plan(self.video(), True)
        journal = self.base / 'pending.json'
        real = mod.rename_without_overwrite
        calls = []

        def fail_after_first(source, destination):
            calls.append(source)
            if len(calls) > 1:
                raise OSError('simulated failure')
            real(source, destination)

        with patch.object(mod, 'rename_without_overwrite', side_effect=fail_after_first), contextlib.redirect_stderr(io.StringIO()):
            with self.assertRaises(OSError):
                mod.mark_watched(plan, journal)
        self.assertEqual(len(json.loads(journal.read_text())), 2)

    def test_hook_timeout_stops_player(self):
        with patch.dict(os.environ, dict(self.env, TEST_MODE='nohook')), patch.object(mod, 'HOOK_STARTUP_SECONDS', .1):
            with self.assertRaisesRegex(RuntimeError, 'hook did not start'):
                mod.play_video(self.video())

    def test_signals_close_child_and_lock_prevents_duplicate_playback(self):
        video = self.video()
        for sig, status in ((signal.SIGTERM, 143), (signal.SIGINT, 130)):
            with self.subTest(signal=sig):
                pidfile = self.base / f'pid-{sig}'
                process = subprocess.Popen([str(SCRIPT), '--directory', str(self.root)],
                    env=dict(self.env, TEST_MODE='wait', TEST_PID=str(pidfile)),
                    stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
                try:
                    deadline = time.monotonic() + 5
                    while not pidfile.exists() and time.monotonic() < deadline:
                        time.sleep(.02)
                    self.assertTrue(pidfile.exists())
                    child = int(pidfile.read_text())
                    self.assertIn('already playing', self.run_launcher().stderr)
                    process.send_signal(sig)
                    self.assertEqual(process.wait(timeout=8), status)
                    with self.assertRaises(ProcessLookupError):
                        os.kill(child, 0)
                    self.assertTrue(video.exists())
                finally:
                    if process.poll() is None:
                        process.terminate()
                        process.wait(timeout=8)

    def test_custom_commands_preserve_compatible_settings_and_skip_conflicts(self):
        source = self.base / 'commands.conf'
        source.write_text('[Audio]\nType=startup\nCommand=set volume 70\n'
                          '[Subtitle]\nType=shortcut\nCommand=set sub-delay 0.2\n'
                          '[Loop]\nType=startup\nCommand=set loop-file inf\n'
                          '[Compound]\nCommand=set volume 50; quit\n'
                          '[Script]\nCommand=load-script other.lua\n')
        output = self.base / 'result.conf'
        with contextlib.redirect_stderr(io.StringIO()) as warnings:
            mod.write_custom_commands(source, output, self.base / 'hook.lua')
        text = output.read_text()
        self.assertIn('[Audio]', text)
        self.assertIn('Type=shortcut', text)
        self.assertIn('sub-delay 0.2', text)
        self.assertNotIn('loop-file', text)
        self.assertNotIn('other.lua', text)
        self.assertIn('hook.lua', text)
        self.assertIn('Loop', warnings.getvalue())
        self.assertIn('other.lua', source.read_text())


if __name__ == '__main__':
    unittest.main()
