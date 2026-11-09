import importlib.util
import io
import json
from pathlib import Path
import stat
import tempfile
from types import SimpleNamespace as Args
import unittest
from unittest.mock import patch
from urllib.error import HTTPError, URLError

spec = importlib.util.spec_from_file_location('tidal_playlist', Path(__file__).parents[1] / 'tidal_playlist.py')
m = importlib.util.module_from_spec(spec)
spec.loader.exec_module(m)


def document(rows, next_link=None):
    """JSON:API fixture: requested track identifiers plus included tracks/artists."""
    data, included = [], []
    for row in rows:
        tid = row.get('id', '1')
        artist = row.get('artist', 'Can')
        aid = 'artist-' + artist
        data.append({'type': 'tracks', 'id': tid})
        attrs = {'title': row.get('title', 'Moonshake'), 'version': row.get('version', ''),
                 'isrc': row.get('isrc', 'recording-' + tid), 'popularity': row.get('popularity', .5)}
        if 'availability' in row:
            attrs['availability'] = row['availability']
        included.extend([
            {'type': 'tracks', 'id': tid, 'attributes': attrs,
             'relationships': {'artists': {'data': [{'type': 'artists', 'id': aid}]}}},
            {'type': 'artists', 'id': aid, 'attributes': {'name': artist}},
        ])
    return {'data': data, 'included': included, 'links': {'next': next_link}}


class Isolated(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        self.state = patch.object(m, 'STATE_DIR', self.root / 'state')
        self.state.start()
        self.addCleanup(self.state.stop)
        output = patch.object(m, 'emit')
        self.output = output.start()
        self.addCleanup(output.stop)
        quiet = patch.object(m, 'progress')
        quiet.start()
        self.addCleanup(quiet.stop)

    def plan(self, ids=('123',)):
        path = self.root / 'plan.json'
        plan = m.new_plan('Test', [{'selected': {'id': i, 'title': 'Song ' + i, 'artist': 'Artist'}} for i in ids], 'GB')
        m.save(path, plan)
        return path


class Matching(Isolated):
    wanted = {'artist': 'Can', 'title': 'Moonshake'}

    def test_exact_and_wrong_artist(self):
        self.assertIsNotNone(m.choose(m.candidates(document([{}]), self.wanted)))
        self.assertIsNone(m.choose(m.candidates(document([{'artist': 'Tribute Band'}]), self.wanted)))

    def test_versions_are_rejected_unless_requested(self):
        for version in ['Live in Paris', 'Work Mix', 'Wipe Out Mix', 'Radio Edit', 'Acoustic', 'Karaoke', 'Demo']:
            with self.subTest(version=version):
                doc = document([{'version': version}])
                self.assertIsNone(m.choose(m.candidates(doc, self.wanted)))
                requested = {**self.wanted, 'version': version}
                self.assertIsNotNone(m.choose(m.candidates(doc, requested)))

    def test_original_preferred_over_remaster(self):
        doc = document([{'id': 'remaster', 'title': 'Moonshake (2008 Remaster)', 'popularity': 1},
                        {'id': 'original', 'popularity': .1}])
        self.assertEqual(m.choose(m.candidates(doc, self.wanted))['id'], 'original')
        self.assertIsNotNone(m.choose(m.candidates(document([{'title': 'Moonshake - 2008 Remaster'}]), self.wanted)))

    def test_same_isrc_editions_and_ambiguous_recordings(self):
        rows = m.candidates(document([{'id': '1', 'isrc': 'same'}, {'id': '2', 'isrc': 'same'}]), self.wanted)
        self.assertIsNotNone(m.choose(rows))
        rows[1]['isrc'] = 'other'
        self.assertIsNone(m.choose(rows))
        rows[0]['isrc'] = rows[1]['isrc'] = None
        self.assertIsNone(m.choose(rows))

    def test_unavailable_track(self):
        self.assertIsNone(m.choose(m.candidates(document([{'availability': []}]), self.wanted)))

    def test_symbol_artist_and_accents(self):
        self.assertNotEqual(m.normalize('!!!'), m.normalize(''))
        self.assertEqual(m.normalize('Lumière'), m.normalize('Lumiere'))

    def test_fallback_title_search_and_second_page(self):
        first = document([{'artist': 'Wrong'}], {'href': '/v2/searchResults/s/relationships/tracks?page[cursor]=next'})
        second = document([{}])
        with patch.object(m, 'api', side_effect=[{'data': [{'id': 's'}]}, first, second]):
            selected, _ = m.search(self.wanted, 'GB', 3)
        self.assertEqual(selected['id'], '1')
        with patch.object(m, 'api', side_effect=[{'data': []}, {'data': [{'id': 's'}]}, second]) as api:
            selected, _ = m.search(self.wanted, 'GB')
        self.assertIsNotNone(selected)
        self.assertIn('filter%5Bquery%5D=Moonshake', api.call_args_list[1].args[1])


class Pagination(Isolated):
    def test_relative_and_absolute_links(self):
        with patch.object(m, 'api', side_effect=[{'links': {'next': {'href': m.API + '/tracks?page=two'}}}, {'links': {}}]) as api:
            self.assertEqual(len(list(m.pages('/tracks'))), 2)
        self.assertEqual(api.call_args_list[1].args[1], '/tracks?page=two')

    def test_external_link_and_cycles_rejected(self):
        with patch.object(m, 'api', return_value={'links': {'next': 'https://evil.example/tracks'}}):
            with self.assertRaises(m.Error): list(m.pages('/tracks'))
        with patch.object(m, 'api', return_value={'links': {'next': '/tracks'}}):
            with self.assertRaises(m.Error): list(m.pages('/tracks'))

    def test_full_collection_cannot_silently_truncate(self):
        with patch.object(m, 'api', return_value={'links': {'next': '/other'}}):
            with self.assertRaises(m.Error): list(m.pages('/tracks', 1))
            self.assertEqual(len(list(m.pages('/tracks', 1, bounded=True))), 1)

    def test_playlist_tracks_include_every_page(self):
        first = document([{'id': 'a'}], '/v2/playlists/p/relationships/items?page=2')
        second = document([{'id': 'b'}])
        with patch.object(m, 'api', side_effect=[first, second]):
            self.assertEqual([r['id'] for r in m.playlist_tracks('p', 'GB')], ['a', 'b'])


class Authentication(Isolated):
    def test_callback_state_and_error_validation(self):
        self.assertEqual(m.callback_result('/callback?state=good&code=secret', 'good'), {'code': 'secret'})
        self.assertEqual(m.callback_result('/callback?state=good&error=denied', 'good'), {'error': 'denied'})
        for path in ['/callback?state=bad&code=x', '/other?state=good&code=x', '/callback?state=good']:
            with self.assertRaises(m.Error): m.callback_result(path, 'good')

    def test_token_refresh_preserves_refresh_token_and_permissions(self):
        m.save(m.STATE_DIR / 'tokens.json', {'client_id': 'id', 'access_token': 'old',
                                          'refresh_token': 'refresh', 'expires_at': 0, 'scope': 'search.read'})
        with patch.object(m, 'request', return_value={'access_token': 'new', 'expires_in': 60}):
            self.assertEqual(m.access_token(), 'new')
        saved = m.load(m.STATE_DIR / 'tokens.json')
        self.assertEqual(saved['refresh_token'], 'refresh')
        self.assertEqual(stat.S_IMODE((m.STATE_DIR / 'tokens.json').stat().st_mode), 0o600)

    def test_401_refreshes_once_and_retains_mutation_key(self):
        with patch.object(m, 'access_token', side_effect=['old', 'new']) as token:
            with patch.object(m, 'request', side_effect=[m.APIError(401, 'expired'), {'ok': True}]) as req:
                self.assertEqual(m.api('POST', '/playlists', {}, key='key'), {'ok': True})
        self.assertEqual(token.call_args.kwargs, {'force_refresh': True})
        self.assertEqual([c.kwargs['key'] for c in req.call_args_list], ['key', 'key'])
        with patch.object(m, 'access_token', return_value='new'):
            with patch.object(m, 'request', side_effect=m.APIError(401, 'bad')) as req:
                with self.assertRaises(m.APIError): m.api('GET', '/tracks')
                self.assertEqual(req.call_count, 2)


class Network(Isolated):
    def http_error(self, code, headers=None):
        return HTTPError(m.API, code, 'Error', headers or {}, io.BytesIO(b'{"errors":[]}'))

    def success(self):
        response = unittest.mock.MagicMock()
        response.__enter__.return_value.read.return_value = b'{"data":[]}'
        return response

    def test_rate_limit_retry_and_bounded_backoff(self):
        with patch.object(m, 'urlopen', side_effect=[self.http_error(429, {'Retry-After': '2'}), self.success()]) as urlopen:
            with patch.object(m.time, 'sleep') as sleep:
                self.assertEqual(m.request('GET', m.API + '/tracks'), {'data': []})
                sleep.assert_called_once_with(2)
                self.assertEqual(urlopen.call_count, 2)
        with patch.object(m, 'urlopen', side_effect=self.http_error(429, {'Retry-After': '120'})):
            with patch.object(m.time, 'sleep') as sleep:
                with self.assertRaises(m.APIError): m.request('GET', m.API + '/tracks')
                sleep.assert_not_called()

    def test_keyed_write_retries_without_changing_key(self):
        with patch.object(m, 'urlopen', side_effect=[URLError('offline'), self.success()]) as send:
            with patch.object(m.time, 'sleep'):
                m.request('POST', m.API + '/playlists', {}, key='stable')
        self.assertEqual([c.args[0].get_header('Idempotency-key') for c in send.call_args_list], ['stable', 'stable'])

    def test_unkeyed_write_and_oauth_are_not_retried(self):
        for form in (False, True):
            with patch.object(m, 'urlopen', side_effect=URLError('offline')) as send:
                with self.assertRaises(m.Error): m.request('POST', m.TOKEN_URL, {}, form=form)
                self.assertEqual(send.call_count, 1)

    def test_server_retries_stop_after_three_attempts(self):
        with patch.object(m, 'urlopen', side_effect=[self.http_error(503) for _ in range(3)]) as send:
            with patch.object(m.time, 'sleep'):
                with self.assertRaises(m.APIError): m.request('GET', m.API + '/tracks')
                self.assertEqual(send.call_count, 3)

    def test_no_request_crosses_recovery_deadline(self):
        with patch.object(m, 'urlopen') as send:
            with self.assertRaises(m.Error):
                m.request('POST', m.API + '/playlists', {}, key='old', deadline=m.time.time() + 15)
            send.assert_not_called()


class WriteRecovery(Isolated):
    def test_resume_after_failed_add_without_duplicate_playlist(self):
        path = self.plan()
        args = Args(plan=path, yes=True)
        with patch.object(m, 'api', side_effect=[{'data': {'id': 'playlist'}}, m.Error('offline')]):
            with self.assertRaises(m.Error): m.create(args)
        with patch.object(m, 'playlist_tracks', return_value=[{'id': '123'}]):
            with patch.object(m, 'api', return_value={'data': [{'type': 'tracks', 'id': '123'}]}) as api:
                m.create(args)
                self.assertEqual(api.call_count, 1)
        with patch.object(m, 'api') as api:
            m.create(args)
            api.assert_not_called()
        self.assertEqual(len(list((m.STATE_DIR / 'records').glob('*.json'))), 1)
        self.assertIn(('id', '123'), m.recommended_keys())

    def test_changed_plan_and_expired_recovery_block_writes(self):
        for mutation in ('changed', 'expired'):
            path = self.plan()
            args = Args(plan=path, yes=True)
            with patch.object(m, 'api', side_effect=m.Error('offline')):
                with self.assertRaises(m.Error): m.create(args)
            plan = m.load(path)
            if mutation == 'changed': plan['name'] = 'Changed'
            else: plan['write']['attempted_at'] = m.time.time() - 3601
            if mutation == 'expired': m.checkpoint(path, plan)
            else: m.save(path, plan)
            with patch.object(m, 'api') as api:
                with self.assertRaises(m.Error): m.create(args)
                api.assert_not_called()

    def test_partial_acknowledgement_does_not_complete(self):
        path = self.plan(('1', '2'))
        with patch.object(m, 'api', side_effect=[{'data': {'id': 'p'}}, {'data': [{'id': '1'}]}]):
            with self.assertRaises(m.Error): m.create(Args(plan=path, yes=True))
        self.assertFalse(m.load(path)['write'].get('complete', False))

    def test_durable_checkpoint_prevents_duplicate_from_stale_input(self):
        path = self.plan()
        original = m.load(path)
        args = Args(plan=path, yes=True)
        with patch.object(m, 'api', side_effect=[{'data': {'id': 'existing'}}, m.Error('offline')]):
            with self.assertRaises(m.Error): m.create(args)
        m.save(path, original)  # e.g. an old copy recovered from /tmp
        with patch.object(m, 'playlist_tracks', return_value=[{'id': '123'}]):
            with patch.object(m, 'api', return_value={'data': [{'id': '123'}]}) as api:
                m.create(args)
                self.assertEqual(api.call_count, 1)
                self.assertIn('/existing/relationships/items', api.call_args.args[1])

    def test_interrupted_resolution_cannot_be_published(self):
        path = self.plan()
        plan = m.load(path)
        plan['resolution_complete'] = False
        m.save(path, plan)
        with patch.object(m, 'api') as api:
            with self.assertRaises(m.Error): m.create(Args(plan=path, yes=True))
            api.assert_not_called()

    def test_multiple_batches_resume_only_pending_batch(self):
        ids = tuple(str(i) for i in range(51))
        path = self.plan(ids)
        args = Args(plan=path, yes=True)
        with patch.object(m, 'api', side_effect=[{'data': {'id': 'p'}}, {'data': [{'id': i} for i in ids[:50]]}, m.Error('offline')]):
            with self.assertRaises(m.Error): m.create(args)
        self.assertEqual(m.load(path)['write']['added'], 50)
        with patch.object(m, 'playlist_tracks', return_value=[{'id': i} for i in ids]):
            with patch.object(m, 'api', return_value={'data': [{'id': '50'}]}) as api:
                m.create(args)
                self.assertEqual(api.call_count, 1)
                self.assertEqual(api.call_args.args[2]['data'], [{'type': 'tracks', 'id': '50'}])

    def test_unresolved_and_unconfirmed_plans_never_write(self):
        path = self.plan()
        with patch.object(m, 'api') as api:
            with self.assertRaises(m.Error): m.create(Args(plan=path, yes=False))
            p = m.load(path); p['entries'][0]['selected'] = None; m.save(path, p)
            with self.assertRaises(m.Error): m.create(Args(plan=path, yes=True))
            api.assert_not_called()

    def test_server_playlist_order_verified(self):
        path = self.plan()
        with patch.object(m, 'api', side_effect=[{'data': {'id': 'p'}}, {'data': [{'id': '123'}]}]):
            with patch.object(m, 'playlist_tracks', return_value=[{'id': 'wrong'}]):
                with self.assertRaises(m.Error): m.create(Args(plan=path, yes=True))
        self.assertFalse(m.load(path)['write'].get('complete', False))


class Management(Isolated):
    def test_append_excludes_isrc_and_name_duplicates_and_previews(self):
        dest = [{'id': 'a', 'artist': 'Can', 'title': 'Moonshake', 'isrc': 'one'}]
        source = [{'id': 'other', 'artist': 'Can', 'title': 'Moonshake (Remastered)', 'isrc': 'two'},
                  {'id': 'b', 'artist': 'Other', 'title': 'Song', 'isrc': 'three'}]
        args = Args(source='s', destination='d', resume=None, country='GB', yes=False)
        with patch.object(m, 'playlist_id', side_effect=['s', 'd']):
            with patch.object(m, 'playlist_tracks', side_effect=[dest, source]):
                with patch.object(m, 'api') as api:
                    m.append(args)
                    api.assert_not_called()
        self.assertEqual([r['id'] for r in self.output.call_args.args[0]['append']], ['b'])

    def test_append_resume_uses_saved_plan_and_verifies_original_order(self):
        args = Args(source='s', destination='d', resume=None, country='GB', yes=True)
        dest = [{'id': 'a'}]; source = [{'id': 'b'}]
        with patch.object(m, 'playlist_id', side_effect=['s', 'd']):
            with patch.object(m, 'playlist_tracks', side_effect=[dest, source]):
                with patch.object(m, 'api', side_effect=m.Error('offline')):
                    with self.assertRaises(m.Error): m.append(args)
        path = next((m.STATE_DIR / 'operations').glob('append-*.json'))
        with patch.object(m, 'playlist_tracks', return_value=dest + source):
            with patch.object(m, 'api', return_value={'data': [{'id': 'b'}]}) as api:
                m.append(Args(resume=path, yes=True))
                self.assertEqual(api.call_count, 1)
        self.assertTrue(m.load(path)['write']['complete'])

    def test_delete_preview_and_backup_before_failure_then_resume(self):
        args = Args(playlist='p', country='GB', resume=None, yes=False)
        with patch.object(m, 'playlist_id', return_value='p'):
            with patch.object(m, 'playlist_tracks', return_value=[{'id': 'a'}]):
                with patch.object(m, 'api', return_value={'data': {'attributes': {'name': 'Test'}}}) as api:
                    m.delete(args)
                    self.assertEqual(api.call_count, 1)
                args.yes = True
                with patch.object(m, 'api', side_effect=[{'data': {'attributes': {'name': 'Test'}}}, m.Error('offline')]):
                    with self.assertRaises(m.Error): m.delete(args)
        path = next((m.STATE_DIR / 'operations').glob('delete-*.json'))
        self.assertEqual(m.load(path)['tracks'], [{'id': 'a'}])
        with patch.object(m, 'api', side_effect=[{}, m.APIError(404, 'gone')]):
            m.delete(Args(resume=path, yes=True))
        self.assertTrue(m.load(path)['write']['complete'])

    def test_name_ambiguity_requires_id(self):
        with patch.object(m, 'owned_playlists', return_value=[{'id': '1', 'name': 'Cooked'}, {'id': '2', 'name': 'cooked'}]):
            with self.assertRaises(m.Error): m.playlist_id('Cooked')
        self.assertEqual(m.playlist_id('https://tidal.com/browse/playlist/abc'), 'abc')


class Discovery(Isolated):
    def test_constraints_history_unavailable_seed_and_durable_output(self):
        m.remember('create', 'old', [{'id': 'old', 'isrc': 'old-isrc'}])
        seeds = [{'id': 'seed1', 'artist': 'Seed', 'title': 'Seed', 'isrc': 'seed-isrc'},
                 {'id': 'seed2', 'artist': 'Seed2', 'title': 'Seed2'}]
        doc = document([{'id': 'seed1', 'isrc': 'seed-isrc'}, {'id': 'old', 'isrc': 'old-isrc'},
                        {'id': '1', 'artist': 'Artist1'}, {'id': '2', 'artist': 'Artist1'},
                        {'id': '3', 'artist': 'Artist2'}])
        args = Args(source='s', country='GB', exclude_playlist=[], allow_previous=False,
                    seed_limit=2, pages=2, count=2, max_per_artist=1, name='Discovery', output=None)
        with patch.object(m, 'playlist_id', return_value='s'):
            with patch.object(m, 'playlist_tracks', return_value=seeds):
                with patch.object(m, 'api', side_effect=[doc, m.APIError(404, 'unavailable')]):
                    m.discover(args)
        result = self.output.call_args.args[0]
        p = m.load(result['plan'])
        self.assertEqual([e['selected']['id'] for e in p['entries']], ['1', '3'])
        self.assertEqual(p['unavailable_seeds'], ['seed2'])
        self.assertTrue(Path(result['plan']).is_relative_to(m.STATE_DIR))
        self.assertIn(('id', '1'), m.recommended_keys())

    def test_insufficient_candidates_does_not_save_partial_playlist(self):
        args = Args(source='s', country='GB', exclude_playlist=[], allow_previous=True,
                    seed_limit=1, pages=1, count=20, max_per_artist=1, name='Test', output=None)
        with patch.object(m, 'playlist_id', return_value='s'):
            with patch.object(m, 'playlist_tracks', return_value=[{'id': 'seed'}]):
                with patch.object(m, 'api', return_value=document([{}])):
                    with self.assertRaises(m.Error): m.discover(args)
        self.assertFalse((m.STATE_DIR / 'plans').exists())

    def test_import_existing_plan_records_history(self):
        path = self.plan()
        m.import_plan(Args(plan=path))
        self.assertIn(('id', '123'), m.recommended_keys())

    def test_import_cannot_overwrite_newer_recovery_record(self):
        path = self.plan()
        stale = m.load(path)
        updated = m.load(path)
        updated['write']['attempted_at'] = m.time.time()
        updated['write']['playlist_id'] = 'already-created'
        m.archive_plan(updated)
        with self.assertRaises(m.Error): m.import_plan(Args(plan=path))
        record = next((m.STATE_DIR / 'plans').glob('*.json'))
        self.assertEqual(m.load(record)['write']['playlist_id'], 'already-created')


if __name__ == '__main__':
    unittest.main()
