import importlib.util
from pathlib import Path
import shutil
import sys
import tempfile
from types import SimpleNamespace as Args
import unittest
from unittest.mock import patch
import wave

from test_playlist import Isolated, document, m

spec = importlib.util.spec_from_file_location('audio_analysis', Path(__file__).parents[1] / 'audio_analysis.py')
audio = importlib.util.module_from_spec(spec)
spec.loader.exec_module(audio)


class Favorites(Isolated):
    def test_all_pages_and_unavailable_identifiers(self):
        first = document([{'id': 'a'}], '/userCollectionTracks/me/relationships/items?page=2')
        second = document([{'id': 'b'}])
        second['data'].append({'type': 'tracks', 'id': 'missing'})
        with patch.object(m, 'api', side_effect=[first, second]):
            self.assertEqual([r['id'] for r in m.favorite_tracks()], ['a', 'b', 'missing'])

    def test_missing_scope_reports_reauthorization(self):
        with patch.object(m, 'api', side_effect=m.APIError(403, 'scope')):
            with self.assertRaisesRegex(m.Error, 'collection.read.*login'):
                m.favorite_tracks()

    def test_favorites_as_discovery_seeds(self):
        args = Args(source=None, from_favorites=True, exclude_favorites=False, country='GB', exclude_playlist=[],
                    allow_previous=True, seed_limit=1, pages=1, count=1, max_per_artist=1, name='From favorites', output=None)
        with patch.object(m, 'favorite_tracks', return_value=[{'id': 'favorite', 'title': 'Seed'}]):
            with patch.object(m, 'api', return_value=document([{'id': 'new'}])):
                m.discover(args)
        self.assertEqual(m.load(self.output.call_args.args[0]['plan'])['source_playlist'], 'favorites')

    def test_favorites_excluded_from_playlist_discovery(self):
        args = Args(source='s', from_favorites=False, exclude_favorites=True, country='GB', exclude_playlist=[],
                    allow_previous=True, seed_limit=1, pages=1, count=1, max_per_artist=1, name='Exclude favorites', output=None)
        with patch.object(m, 'playlist_id', return_value='s'):
            with patch.object(m, 'playlist_tracks', return_value=[{'id': 'seed'}]):
                with patch.object(m, 'favorite_tracks', return_value=[{'id': 'favorite'}]):
                    with patch.object(m, 'api', return_value=document([{'id': 'favorite'}, {'id': 'new', 'artist': 'New'}])):
                        m.discover(args)
        self.assertEqual(self.output.call_args.args[0]['tracks'][0]['id'], 'new')


class Metadata(Isolated):
    def test_catalog_fields_unknowns_and_nonfinite_bpm(self):
        actual = m.catalog_features({'bpm': 123, 'key': 'FSharp', 'keyScale': 'MINOR', 'toneTags': ['Happy']})
        self.assertEqual(actual, {'bpm': 123, 'key': 'FSharp', 'scale': 'MINOR', 'moods': ['Happy'], 'source': 'tidal_metadata'})
        for bpm in (float('nan'), float('inf'), 0, -1, True, '120'):
            self.assertIsNone(m.catalog_features({'bpm': bpm})['bpm'])
        self.assertIsNone(m.catalog_features({'key': 'UNKNOWN'})['key'])

    def test_filters_never_guess_missing_features(self):
        row = {'id': '1', 'audio_features': m.catalog_features({'bpm': 110, 'key': 'C', 'keyScale': 'MAJOR', 'toneTags': ['Happy']})}
        self.assertTrue(m.matches_features(row, Args(bpm_min=100, bpm_max=120, key='C', scale='MAJOR', mood=['happy'])))
        self.assertFalse(m.matches_features(row, Args(bpm_min=120)))
        self.assertFalse(m.matches_features({'id': 'missing'}, Args(bpm_min=100)))
        self.assertFalse(m.matches_features(row, Args(mood=['sad'])))

    def test_linked_audio_takes_precedence_but_missing_estimates_fall_back(self):
        row = {'id': '1', 'audio_features': m.catalog_features({'bpm': 90, 'key': 'C', 'keyScale': 'MAJOR', 'toneTags': ['Happy']})}
        m.save(m.STATE_DIR / 'audio' / (m.digest('1') + '.json'),
               {'bpm': 120, 'key': None, 'scale': None, 'moods': ['energetic'], 'source': 'local_audio'})
        values = m.effective_features(row)
        self.assertEqual(values['bpm'], 120)
        self.assertEqual(values['key'], 'C')
        self.assertEqual(values['sources']['key'], 'tidal_metadata')
        self.assertEqual(values['moods'], ['energetic'])

    def test_discovery_filter_excludes_candidates_with_unknown_bpm(self):
        args = Args(source='s', from_favorites=False, exclude_favorites=False, country='GB', exclude_playlist=[],
                    allow_previous=True, seed_limit=1, pages=1, count=1, max_per_artist=1, name='Filtered', output=None,
                    bpm_min=100, bpm_max=130)
        doc = document([{'id': 'missing'}, {'id': 'match', 'artist': 'Other'}])
        for r in doc['included']:
            if r['type'] == 'tracks' and r['id'] == 'match': r['attributes']['bpm'] = 120
        with patch.object(m, 'playlist_id', return_value='s'):
            with patch.object(m, 'playlist_tracks', return_value=[{'id': 'seed'}]):
                with patch.object(m, 'api', return_value=doc):
                    m.discover(args)
        self.assertEqual(self.output.call_args.args[0]['tracks'][0]['id'], 'match')


@unittest.skipUnless(importlib.util.find_spec('numpy'), 'NumPy is optional')
class Audio(Isolated):
    def test_silence_and_invalid_audio(self):
        import numpy as np
        result = audio.measurements(np.zeros(22050 * 6))
        self.assertIsNone(result['bpm'])
        self.assertIsNone(result['key'])
        self.assertEqual(result['moods'], [])
        with self.assertRaises(ValueError): audio.measurements(np.zeros(100))
        y = np.zeros(22050 * 6); y[0] = np.nan
        with self.assertRaises(ValueError): audio.measurements(y)

    def test_known_120_bpm_attacks(self):
        import numpy as np
        t = np.arange(22050 * 20) / 22050
        y = .1 * (np.sin(2*np.pi*261.626*t) + np.sin(2*np.pi*329.628*t) + np.sin(2*np.pi*391.995*t))
        y *= .15 + np.exp(-(t % .5) * 25)
        result = audio.measurements(y)
        self.assertAlmostEqual(result['bpm'], 120, delta=2)
        self.assertIn('energetic', result['moods'])

    def test_tonal_profile_detects_key_without_inventing_a_beat(self):
        import numpy as np
        t = np.arange(22050 * 12) / 22050
        y = sum(np.sqrt(w) * np.sin(2*np.pi*(261.625565*2**(n/12))*t) for n,w in enumerate(audio.MAJOR)) * .02
        result = audio.measurements(y)
        self.assertEqual((result['key'], result['scale']), ('C', 'MAJOR'))
        self.assertIsNone(result['bpm'])

    @unittest.skipUnless(shutil.which('ffmpeg'), 'FFmpeg is optional')
    def test_real_wav_decode_cli_and_linked_cache(self):
        import numpy as np
        path = self.root / 'silence.wav'
        with wave.open(str(path), 'wb') as wav:
            wav.setnchannels(1); wav.setsampwidth(2); wav.setframerate(22050)
            wav.writeframes(np.zeros(22050*6, dtype='<i2').tobytes())
        with patch.dict(sys.modules, {'audio_analysis': audio}):
            m.analyze_audio(Args(file=path, seconds=6, track_id='test-track', output=self.root / 'features.json'))
        result = m.local_features('test-track')
        self.assertEqual(result['source'], 'local_audio')
        self.assertEqual(len(result['audio_segment_sha256']), 64)
        self.assertIsNone(result['bpm'])
        for seconds in (1, 301, float('nan')):
            with self.assertRaises(ValueError): audio.analyze_file(path, seconds)


if __name__ == '__main__':
    unittest.main()
