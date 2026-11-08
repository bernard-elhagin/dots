"""Run with python3 -m unittest discover -s bin/tests -v; no desktop required."""
import copy
import json
from pathlib import Path
import tempfile
import types
import unittest
from unittest.mock import patch

SCRIPT = Path(__file__).resolve().parents[1] / 'hypr-session.sh'
SOURCE = SCRIPT.read_text().split("<<'PY'\n", 1)[1].rsplit('\nPY', 1)[0]
mod = types.ModuleType('hypr_session')
exec(compile(SOURCE, str(SCRIPT), 'exec'), mod.__dict__)


def window(address, title='editor', ws=5, x=1000, y=0, width=1000, height=1000):
    return dict(address=address, savedAddress=address, initialClass='editor', title=title,
                workspace=dict(id=ws, name=str(ws)), floating=False, fullscreen=0,
                at=[x, y], size=[width, height], argv=['editor'], cwd='/tmp')


class SessionTests(unittest.TestCase):
    def test_steam_helper_snapshot_launches_main_client(self):
        saved = window('old')
        saved.update(initialClass='steam', argv=['./steamwebhelper', '-steampid=3567'])
        opened = window('new', ws=3)
        opened['initialClass'] = 'steam'
        with patch.object(mod, 'clients_now', side_effect=[[], [], [opened]]), patch.object(mod, 'hypr_json', return_value=[]), patch.object(mod, 'dispatch', return_value=True), patch.object(mod.subprocess, 'Popen') as launch, patch.object(mod.time, 'sleep'):
            self.assertEqual(mod.restore_window(saved, set()), 'new')
            self.assertEqual(launch.call_args.args[0], ['steam', 'steam://open/main'])

    def test_other_apps_keep_saved_command(self):
        saved = window('old')
        self.assertEqual(mod.launch_argv(saved), ['editor'])

    def test_duplicate_matching_claims_distinct_windows(self):
        saved = window('old')
        with patch.object(mod, 'clients_now', return_value=[window('a'), window('b')]):
            self.assertEqual(mod.match_existing(saved, {'a'})['address'], 'b')
            self.assertIsNone(mod.match_existing(saved, {'a', 'b'}))

    def test_exact_title_matches_even_on_wrong_workspace(self):
        with patch.object(mod, 'clients_now', return_value=[window('a', ws=2), window('b', title='other')]):
            self.assertEqual(mod.match_existing(window('old'), set())['address'], 'a')

    def test_explicit_workspace_and_floating_geometry(self):
        saved = window('old'); saved['floating'] = True
        calls = []
        with patch.object(mod, 'dispatch', side_effect=lambda *args: calls.append(args) or True):
            claimed = set()
            self.assertEqual(mod.place_window(saved, window('new', ws=2), claimed), 'new')
        self.assertEqual(calls[0], ('movetoworkspace', 'address:new', '5'))
        self.assertIn(('resize', 'address:new 1000 1000'), calls)
        self.assertEqual(claimed, {'new'})

    def test_failed_move_does_not_report_success(self):
        with patch.object(mod, 'dispatch', return_value=False):
            with self.assertRaises(RuntimeError):
                mod.place_window(window('old'), window('new'), set())

    def test_save_records_master_order_and_monitor_name(self):
        clients = [window('master'), window('bottom', x=0, y=500, height=500),
                   window('top', x=0, height=500)]
        for c in clients:
            c['monitor'] = 0
        responses = dict(clients=clients, workspaces=[dict(id=5, name='5', monitor='DP-1', tiledLayout='master')],
                         monitors=[dict(id=0, name='DP-1')], activeworkspace=dict(id=5, name='5'), activewindow={})
        with tempfile.TemporaryDirectory() as directory, patch.object(mod, 'hypr_json', side_effect=responses.__getitem__), patch.object(mod, 'option', return_value='right'):
            target = Path(directory) / 'state.json'
            mod.save_session(target)
            state = json.loads(target.read_text())
            self.assertEqual(state['workspaces'][0]['masterPlacement']['order'], ['master', 'top', 'bottom'])
            self.assertEqual(state['windows'][0]['workspace']['monitor'], 'DP-1')
            self.assertEqual(target.stat().st_mode & 0o777, 0o600)

    def test_master_order_swaps_by_address(self):
        live = [window('a'), window('b', x=0, height=500), window('c', x=0, y=500, height=500)]
        saved = [window('old-a'), window('old-b'), window('old-c')]
        state = dict(workspaces=[dict(id=5, name='5', masterPlacement=dict(
            order=['old-c', 'old-b', 'old-a'], orientation='right', ratio=.6))])
        focused = [None]
        calls = []
        def dispatch(name, parameter='', extra=''):
            calls.append((name, parameter))
            if name == 'focuswindow':
                focused[0] = parameter.removeprefix('address:')
            if name == 'swap':
                a = next(c for c in live if c['address'] == focused[0])
                b = next(c for c in live if c['address'] == parameter.removeprefix('address:'))
                a['at'], b['at'] = b['at'], a['at']
            return True
        with patch.object(mod, 'hypr_json', return_value=[dict(id=5, name='5', tiledLayout='master')]), patch.object(mod, 'clients_now', side_effect=lambda: copy.deepcopy(live)), patch.object(mod, 'dispatch', side_effect=dispatch):
            mod.restore_master_layouts(state, list(zip(saved, ['a', 'b', 'c'])))
        self.assertEqual(next(c for c in live if c['address'] == 'c')['at'], [1000, 0])
        self.assertIn(('layout', 'mfact exact 0.60000'), calls)

    def test_dispatch_uses_lua_window_address(self):
        result = types.SimpleNamespace(returncode=0, stdout='ok', stderr='')
        with patch.object(mod, 'run_hyprctl', return_value=result) as run:
            self.assertTrue(mod.dispatch('movetoworkspace', 'address:0xabc', 'name:work'))
        self.assertEqual(run.call_args.args, ('dispatch',
            'hl.dsp.window.move({ window = "address:0xabc", workspace = "name:work", follow = false })'))

    def test_full_restore_reuses_each_window_once(self):
        saved = [window('old-a', title='first'), window('old-b', title='second')]
        live = [window('a', title='first', ws=2), window('b', title='second', ws=3)]
        state = dict(version=2, windows=saved, workspaces=[], activeWorkspace=dict(id=5, name='5'))
        with tempfile.TemporaryDirectory() as directory, patch.object(mod, 'hypr_json', return_value=[]), patch.object(mod, 'clients_now', return_value=live), patch.object(mod, 'dispatch', return_value=True) as dispatch, patch.object(mod.subprocess, 'Popen') as launch:
            target = Path(directory) / 'state.json'
            target.write_text(json.dumps(state))
            mod.restore_session(target)
            launch.assert_not_called()
            dispatch.assert_any_call('movetoworkspace', 'address:a', '5')
            dispatch.assert_any_call('movetoworkspace', 'address:b', '5')

    def test_delayed_new_window_on_wrong_workspace_gets_placed(self):
        saved = window('old')
        snapshots = iter([[], [], [], [window('new', ws=2)]])
        with patch.object(mod, 'clients_now', side_effect=lambda: next(snapshots)), patch.object(mod, 'hypr_json', return_value=[]), patch.object(mod, 'dispatch', return_value=True) as dispatch, patch.object(mod.subprocess, 'Popen') as launch, patch.object(mod.time, 'sleep'):
            launch.return_value.poll.return_value = None
            self.assertEqual(mod.restore_window(saved, set()), 'new')
            dispatch.assert_any_call('movetoworkspace', 'address:new', '5')


if __name__ == '__main__':
    unittest.main()
