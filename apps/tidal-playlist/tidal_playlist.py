#!/usr/bin/env python3
"""Match suggestions, discover music, and manage TIDAL playlists."""
import argparse
import base64
from contextlib import contextmanager
from datetime import datetime, timezone
from email.utils import parsedate_to_datetime
import fcntl
import hashlib
from http.server import BaseHTTPRequestHandler, HTTPServer
import json
import math
import os
from pathlib import Path
import re
import secrets
import sys
import time
import unicodedata
from urllib.error import HTTPError, URLError
from urllib.parse import parse_qs, quote, urlencode, urlparse
from urllib.request import Request, urlopen
import uuid

CLIENT_ID = 'OJ1xYPEKAPDjLC7r'
CALLBACK = 'http://127.0.0.1:8765/callback'
SCOPES = 'playlists.read playlists.write search.read collection.read'
API = 'https://openapi.tidal.com/v2'
TOKEN_URL = 'https://auth.tidal.com/v1/oauth2/token'
STATE_DIR = Path(os.environ.get('XDG_STATE_HOME', str(Path.home() / '.local/state'))) / 'tidal-playlist'
DEFAULT_COUNTRY = 'GB'
JSON_OUTPUT = False


class Error(Exception):
    pass


class APIError(Error):
    def __init__(self, status, detail):
        self.status = status
        super().__init__(f'TIDAL HTTP {status}: {detail}')


def emit(data):
    if JSON_OUTPUT:
        print(json.dumps(data, ensure_ascii=False))
    elif isinstance(data, str):
        print(data)
    else:
        print(json.dumps(data, ensure_ascii=False, indent=2))


def progress(message):
    print(message, file=sys.stderr, flush=True)


def save(path, data):
    path = Path(path)
    path.parent.mkdir(parents=True, exist_ok=True)
    temp = path.with_name(path.name + '.' + secrets.token_hex(6) + '.tmp')
    fd = os.open(temp, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600)
    try:
        with os.fdopen(fd, 'w') as output:
            json.dump(data, output, indent=2, ensure_ascii=False)
            output.write('\n')
        os.replace(temp, path)
    finally:
        temp.unlink(missing_ok=True)


def load(path):
    try:
        return json.loads(Path(path).read_text())
    except (OSError, ValueError) as exc:
        raise Error(f'Cannot read {path}: {exc}') from exc


def digest(data):
    return hashlib.sha256(json.dumps(data, sort_keys=True).encode()).hexdigest()


@contextmanager
def state_lock():
    """Serialize this tool's local operations, including token refreshes."""
    STATE_DIR.mkdir(parents=True, exist_ok=True)
    fd = os.open(STATE_DIR / 'operation.lock', os.O_CREAT | os.O_RDWR, 0o600)
    with os.fdopen(fd, 'w') as lock:
        try:
            fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError:
            raise Error('Another tidal-playlist operation is running.') from None
        yield


def retry_delay(value, attempt):
    if value:
        try:
            seconds = float(value)
        except ValueError:
            try:
                seconds = parsedate_to_datetime(value).timestamp() - time.time()
            except (ValueError, TypeError, OverflowError):
                seconds = 2 ** attempt
        if math.isfinite(seconds):
            return max(0, seconds)
    return 2 ** attempt


def request(method, url, payload=None, token=None, form=False, key=None, deadline=None):
    headers = {'Accept': 'application/json' if form else 'application/vnd.api+json'}
    if token:
        headers['Authorization'] = 'Bearer ' + token
    if key:
        headers['Idempotency-Key'] = key
    body = None
    if payload is not None:
        body = (urlencode(payload) if form else json.dumps(payload)).encode()
        headers['Content-Type'] = ('application/x-www-form-urlencoded' if form
                                   else 'application/vnd.api+json')
    retryable = not form and (method == 'GET' or bool(key))
    for attempt in range(3):
        if deadline is not None and time.time() + 30 >= deadline:
            raise Error('Write recovery deadline reached; inspect the saved operation before retrying.')
        try:
            with urlopen(Request(url, data=body, headers=headers, method=method), timeout=30) as response:
                raw = response.read()
                try:
                    return json.loads(raw) if raw else {}
                except ValueError:
                    raise Error('TIDAL returned invalid JSON; saved write keys are retained.') from None
        except HTTPError as exc:
            if retryable and exc.code in (429, 500, 502, 503, 504) and attempt < 2:
                delay = retry_delay(exc.headers.get('Retry-After'), attempt)
                exc.close()
                if delay > 30:
                    raise APIError(exc.code, f'Retry after {math.ceil(delay)} seconds; no automatic long wait.') from None
                time.sleep(delay)
                continue
            if form:
                # Never echo OAuth response bodies, request headers, or tokens.
                raise APIError(exc.code, 'OAuth failed. Check scopes/callback or run login again.') from None
            detail = ''
            try:
                errors = json.loads(exc.read()).get('errors', [])
                detail = '; '.join(str(e.get('detail') or e.get('title') or e.get('code', '')) for e in errors)[:700]
            except (ValueError, AttributeError, TypeError):
                pass
            finally:
                exc.close()
            if token:
                detail = detail.replace(token, '[redacted]')
            raise APIError(exc.code, detail or str(exc.reason)) from None
        except (URLError, TimeoutError, OSError) as exc:
            if retryable and attempt < 2:
                time.sleep(2 ** attempt)
                continue
            raise Error('Network request failed; retry the same command. Saved write keys are retained.') from None


def store_tokens(response, client_id, previous=None):
    if not response.get('access_token'):
        raise Error('OAuth response did not contain an access token.')
    previous = previous or {}
    response['refresh_token'] = response.get('refresh_token', previous.get('refresh_token'))
    response['scope'] = response.get('scope', previous.get('scope', ''))
    response['client_id'] = client_id
    response['expires_at'] = time.time() + int(response.get('expires_in', 3600))
    save(STATE_DIR / 'tokens.json', response)
    return response


def access_token(force_refresh=False):
    path = STATE_DIR / 'tokens.json'
    if not path.exists():
        raise Error('Run tidal-playlist login first.')
    tokens = load(path)
    if force_refresh or tokens.get('expires_at', 0) < time.time() + 60:
        if not tokens.get('refresh_token'):
            raise Error('Login expired; run tidal-playlist login again.')
        tokens = store_tokens(request('POST', TOKEN_URL, {
            'grant_type': 'refresh_token', 'refresh_token': tokens['refresh_token'],
            'client_id': tokens['client_id'],
        }, form=True), tokens['client_id'], tokens)
    return tokens['access_token']


def callback_result(path, state):
    parsed = urlparse(path)
    params = parse_qs(parsed.query)
    if parsed.path != '/callback' or not secrets.compare_digest(params.get('state', [''])[0], state):
        raise Error('Invalid callback or state')
    if params.get('error'):
        return {'error': params['error'][0]}
    if not params.get('code'):
        raise Error('Missing authorization code')
    return {'code': params['code'][0]}


def login(args):
    verifier = secrets.token_urlsafe(64)
    challenge = base64.urlsafe_b64encode(hashlib.sha256(verifier.encode()).digest()).rstrip(b'=').decode()
    state = secrets.token_urlsafe(32)
    result = {}

    class Callback(BaseHTTPRequestHandler):
        def log_message(self, *_):
            pass

        def do_GET(self):
            try:
                parsed = callback_result(self.path, state)
            except Error as exc:
                self.send_error(400, str(exc))
                return
            result.update(parsed)
            self.send_response(200)
            self.send_header('Content-Type', 'text/plain; charset=utf-8')
            self.send_header('Cache-Control', 'no-store')
            self.end_headers()
            self.wfile.write(b'Login response received. Return to your terminal; you may close this tab.')

    try:
        server = HTTPServer(('127.0.0.1', 8765), Callback)
    except OSError as exc:
        raise Error(f'Cannot listen on callback port 8765: {exc}') from None
    with server:
        server.timeout = 1
        url = 'https://login.tidal.com/authorize?' + urlencode({
            'response_type': 'code', 'client_id': args.client_id, 'redirect_uri': CALLBACK,
            'scope': SCOPES, 'code_challenge_method': 'S256', 'code_challenge': challenge, 'state': state,
        })
        progress('Open this URL in a browser on this computer and approve access:\n' + url)
        deadline = time.monotonic() + 300
        while not result and time.monotonic() < deadline:
            server.handle_request()
    if 'error' in result:
        raise Error('TIDAL declined authorization. Check your app settings and try login again.')
    if not result.get('code'):
        raise Error('Login timed out after five minutes; run login again.')
    store_tokens(request('POST', TOKEN_URL, {
        'grant_type': 'authorization_code', 'client_id': args.client_id,
        'code': result['code'], 'redirect_uri': CALLBACK, 'code_verifier': verifier,
    }, form=True), args.client_id)
    emit({'connected': True})


def api_path(value):
    """Only accept pagination on this API origin; never send tokens elsewhere."""
    parsed = urlparse(value)
    if parsed.fragment or (parsed.netloc and (parsed.scheme != 'https' or parsed.netloc != 'openapi.tidal.com')):
        raise Error('Refusing pagination outside the TIDAL API.')
    path = parsed.path
    if path.startswith('/v2/'):
        path = path[3:]
    if not path.startswith('/') or path.startswith('//') or '/..' in path:
        raise Error('Invalid API path.')
    return path + ('?' + parsed.query if parsed.query else '')


def api(method, path, payload=None, key=None, deadline=None):
    url = API + api_path(path)
    try:
        return request(method, url, payload, token=access_token(), key=key, deadline=deadline)
    except APIError as exc:
        if exc.status != 401:
            raise
    # One refresh and replay, retaining the same idempotency key for writes.
    return request(method, url, payload, token=access_token(force_refresh=True), key=key, deadline=deadline)


def pages(path, limit=100, bounded=False):
    visited = set()
    for _ in range(limit):
        path = api_path(path)
        if path in visited:
            raise Error('TIDAL returned a repeated pagination link.')
        visited.add(path)
        doc = api('GET', path)
        yield doc
        nxt = doc.get('links', {}).get('next')
        if isinstance(nxt, dict):
            nxt = nxt.get('href')
        if not nxt:
            return
        path = api_path(nxt)
    if not bounded:
        raise Error(f'Pagination exceeded {limit} pages; refusing an incomplete result.')


def data_list(doc):
    data = doc.get('data', [])
    return [data] if isinstance(data, dict) else data or []


def normalize(text):
    text = unicodedata.normalize('NFKD', str(text)).casefold()
    return ''.join(c for c in text if not unicodedata.combining(c) and (c.isalnum() or c == '!'))


VARIANTS = re.compile(r'\b(live|remix(?:ed)?|mix|karaoke|tribute|instrumental|acoustic|edit|demo|radio|rerecord(?:ed|ing)?|re-record(?:ed|ing)?)\b', re.I)
REMASTER = re.compile(r'\bremaster(?:ed)?\b', re.I)


def title_base(title):
    # Remove only identifiable edition suffixes, never arbitrary parentheses.
    def strip(match):
        return '' if REMASTER.search(match.group()) else match.group()
    value = re.sub(r'\([^)]*\)|\[[^]]*\]', strip, title)
    value = re.sub(r'\s*[-–—]\s*(?:(?:\d{4})\s+)?remaster(?:ed)?(?:\s+\d{4})?\s*$', '', value, flags=re.I)
    return normalize(value)


def track_rows(doc):
    included = {(r['type'], str(r['id'])): r for r in doc.get('included', [])}
    rows = []
    for ref in data_list(doc):
        if ref.get('type') != 'tracks':
            continue
        track = included.get(('tracks', str(ref['id'])), ref)
        a = track.get('attributes', {})
        if not a.get('title'):
            continue
        names = [included.get(('artists', str(r['id'])), {}).get('attributes', {}).get('name', '')
                 for r in track.get('relationships', {}).get('artists', {}).get('data', [])]
        names = [n for n in names if n]
        availability = a.get('availability')
        rows.append({'id': str(track['id']), 'artist': ', '.join(names), 'artists': names,
                     'title': a['title'], 'version': a.get('version') or '', 'isrc': a.get('isrc'),
                     'popularity': a.get('popularity', 0) or 0,
                     'audio_features': catalog_features(a),
                     'available': availability is None or 'STREAM' in availability})
    return rows


def catalog_features(attributes):
    bpm = attributes.get('bpm')
    if isinstance(bpm, bool) or not isinstance(bpm, (int, float)) or not math.isfinite(bpm) or bpm <= 0:
        bpm = None
    key = attributes.get('key')
    scale = attributes.get('keyScale')
    return {'bpm': bpm, 'key': None if key in (None, 'UNKNOWN') else key,
            'scale': None if scale in (None, 'UNKNOWN') else scale,
            'moods': [v for v in attributes.get('toneTags', []) or [] if isinstance(v, str)],
            'source': 'tidal_metadata'}


def favorite_tracks():
    path = '/userCollectionTracks/me/relationships/items?include=items.artists'
    result = []
    try:
        for doc in pages(path):
            rows = {r['id']: r for r in track_rows(doc)}
            for ref in data_list(doc):
                if ref.get('type') == 'tracks':
                    result.append(rows.get(str(ref['id']), {'id': str(ref['id']), 'title': '', 'artists': []}))
    except APIError as exc:
        if exc.status == 403:
            raise Error('Favorites need collection.read. Enable it in your TIDAL developer app, then run login again.') from None
        raise
    return result


def favorites(args):
    emit({'tracks': favorite_tracks()})


def local_features(track_id):
    path = STATE_DIR / 'audio' / (digest(str(track_id)) + '.json')
    return load(path) if path.exists() else None


def effective_features(row):
    catalog = row.get('audio_features', catalog_features({}))
    local = local_features(row['id'])
    if not local:
        return catalog
    combined = dict(local)
    combined['sources'] = {}
    for field in ('bpm', 'key', 'scale', 'moods'):
        use_local = local.get(field) is not None and local.get(field) != []
        combined[field] = local.get(field) if use_local else catalog.get(field)
        combined['sources'][field] = 'local_audio' if use_local else 'tidal_metadata'
    combined['source'] = 'local_audio_with_catalog_fallback'
    return combined


def analyze_audio(args):
    # Import only for this optional feature; the rest of the CLI stays stdlib-only.
    import audio_analysis
    result = audio_analysis.analyze_file(args.file, args.seconds)
    if args.track_id:
        result['track_id'] = args.track_id
        result['association'] = 'user-supplied; recording identity not independently verified'
        save(STATE_DIR / 'audio' / (digest(args.track_id) + '.json'), result)
    if args.output:
        save(args.output, result)
    emit(result)


def features(args):
    if args.playlist:
        rows = playlist_tracks(playlist_id(args.target, args.country), args.country)
    else:
        doc = api('GET', '/tracks/' + quote(args.target, safe='') + '?' + urlencode({
            'countryCode': args.country, 'include': 'artists'}))
        rows = track_rows(doc)
    emit({'tracks': [{**r, 'effective_features': effective_features(r)} for r in rows]})


def matches_features(row, args):
    values = effective_features(row)
    minimum, maximum = getattr(args, 'bpm_min', None), getattr(args, 'bpm_max', None)
    bpm = values.get('bpm')
    if minimum is not None and (bpm is None or bpm < minimum):
        return False
    if maximum is not None and (bpm is None or bpm > maximum):
        return False
    if getattr(args, 'key', None) and normalize(values.get('key') or '') != normalize(args.key):
        return False
    if getattr(args, 'scale', None) and values.get('scale') != args.scale:
        return False
    moods = {normalize(v) for v in values.get('moods', [])}
    if getattr(args, 'mood', []) and not moods.intersection(normalize(v) for v in args.mood):
        return False
    row['effective_features'] = values
    return True


def candidates(doc, wanted):
    rows = track_rows(doc)
    for row in rows:
        version = row['version']
        expected = wanted.get('version', '')
        explicitly_versioned = bool(expected or VARIANTS.search(wanted['title']))
        if explicitly_versioned:
            title_ok = normalize(row['title']) == normalize(wanted['title'])
            version_ok = normalize(version) == normalize(expected)
        else:
            title_ok = title_base(row['title']) == title_base(wanted['title'])
            version_ok = not VARIANTS.search(row['title'] + ' ' + version)
            # Unlabelled mix names are not automatically original recordings.
            if version and not REMASTER.search(version) and version.casefold() not in ('original', 'original version', 'album version'):
                version_ok = False
        artist_ok = any(normalize(n) == normalize(wanted['artist']) for n in row['artists'])
        row['safe'] = bool(title_ok and version_ok and artist_ok and row['available'])
        row['edition_rank'] = int(bool(REMASTER.search(row['title'] + ' ' + version)))
    return sorted(rows, key=lambda c: (not c['safe'], c['edition_rank'], -c['popularity']))


def choose(rows):
    good = [r for r in rows if r['safe']]
    if not good:
        return None
    best_rank = min(r.get('edition_rank', 0) for r in good)
    preferred = [r for r in good if r.get('edition_rank', 0) == best_rank]
    recordings = {r['isrc'] or 'id:' + r['id'] for r in preferred}
    return preferred[0] if len(recordings) == 1 else None


def search(wanted, country, max_pages=3):
    rows = {}
    # Always finish the bounded search for a query before accepting a match.
    queries = list(dict.fromkeys([wanted['artist'] + ' ' + wanted['title'], wanted['title'], wanted['artist']]))
    for query in queries:
        doc = api('GET', '/searchResults?' + urlencode({'filter[query]': query, 'countryCode': country}))
        roots = data_list(doc)
        if not roots:
            continue
        path = '/searchResults/' + quote(str(roots[0]['id']), safe='') + '/relationships/tracks?' + urlencode({
            'countryCode': country, 'include': 'tracks.artists'})
        for doc in pages(path, max_pages, bounded=True):
            for row in candidates(doc, wanted):
                rows[row['id']] = row
        selected = choose(list(rows.values()))
        if selected:
            return selected, list(rows.values())
    return None, sorted(rows.values(), key=lambda c: (not c['safe'], c['edition_rank'], -c['popularity']))


def identities(row):
    keys = {('id', str(row['id']))}
    if row.get('isrc'):
        keys.add(('isrc', row['isrc']))
    artists = row.get('artists') or [row.get('artist', '')]
    if row.get('title'):
        keys.update(('name', normalize(a), title_base(row['title'])) for a in artists if a)
    return keys


def plan_path(output, name):
    if output:
        return Path(output)
    slug = re.sub(r'[^a-z0-9]+', '-', name.casefold()).strip('-')[:60] or 'playlist'
    return STATE_DIR / 'plans' / (slug + '-' + uuid.uuid4().hex[:8] + '.json')


def new_plan(name, entries, country, description=''):
    if not isinstance(name, str) or not 1 <= len(name.strip()) <= 250:
        raise Error('Playlist name must contain 1–250 characters.')
    if not isinstance(description, str) or len(description) > 500:
        raise Error('Description must contain at most 500 characters.')
    return {'name': name, 'description': description, 'country': country, 'entries': entries,
            'write': {'create_key': str(uuid.uuid4()), 'add_key': str(uuid.uuid4())}}


def archive_plan(plan):
    key = plan['write']['create_key']
    save(STATE_DIR / 'plans' / ('record-' + key + '.json'), plan)


def checkpoint(path, document):
    # Persist recovery state outside /tmp before updating a user-supplied plan.
    if 'entries' in document:
        archive_plan(document)
    save(path, document)


def recommended_keys():
    keys = set()
    for directory in ('plans', 'records'):
        for path in (STATE_DIR / directory).glob('*.json'):
            doc = load(path)
            for entry in doc.get('entries', []):
                if entry.get('selected'):
                    keys.update(identities(entry['selected']))
            for row in doc.get('tracks', []):
                keys.update(identities(row))
    return keys


def resolve(args):
    source = load(args.input)
    tracks = source.get('tracks', [])
    if not isinstance(tracks, list) or not 1 <= len(tracks) <= 1000:
        raise Error('Supply 1–1000 tracks.')
    # Validate before any network calls.
    for track in tracks:
        if not isinstance(track, dict) or not all(isinstance(track.get(k), str) and track[k].strip() for k in ('artist', 'title')):
            raise Error('Each track needs a nonempty artist and title.')
    plan = new_plan(source.get('name'), [], args.country, source.get('description', ''))
    plan['expected_tracks'] = len(tracks)
    plan['resolution_complete'] = False
    path = plan_path(args.output, plan['name'])
    if path.exists():
        raise Error('Output already exists; choose another path to preserve the existing plan.')
    seen = set()
    for track in tracks:
        selected, rows = search(track, args.country, args.pages)
        if selected and seen.intersection(identities(selected)):
            selected = None
        if selected:
            seen.update(identities(selected))
        plan['entries'].append({'requested': track, 'selected': selected, 'candidates': rows[:20]})
        save(path, plan)
        progress(('OK ' if selected else 'REVIEW ') + track['artist'] + ' — ' + track['title'])
    plan['resolution_complete'] = True
    save(path, plan)
    archive_plan(plan)
    emit({'plan': str(path), 'review': sum(not e['selected'] for e in plan['entries']), 'created': False})


def playlist_id(value, country=DEFAULT_COUNTRY):
    if value.startswith(('http://', 'https://')):
        parsed = urlparse(value)
        if parsed.hostname not in ('tidal.com', 'www.tidal.com', 'listen.tidal.com'):
            raise Error('Not a TIDAL playlist URL.')
        match = re.search(r'/playlist/([^/]+)', parsed.path)
        if not match:
            raise Error('Not a TIDAL playlist URL.')
        return match.group(1)
    try:
        return str(uuid.UUID(value))
    except ValueError:
        matches = [p for p in owned_playlists(country) if p['name'].casefold() == value.casefold()]
        if len(matches) != 1:
            raise Error(f'Playlist name matched {len(matches)} owned playlists. Use an exact ID or URL.')
        return matches[0]['id']


def owned_playlists(country):
    result = []
    path = '/playlists?' + urlencode({'filter[owners.id]': 'me', 'countryCode': country})
    for doc in pages(path):
        for row in data_list(doc):
            result.append({'id': str(row['id']), 'name': row.get('attributes', {}).get('name', '')})
    return result


def playlist_tracks(pid, country):
    result = []
    path = '/playlists/' + quote(pid, safe='') + '/relationships/items?' + urlencode({
        'countryCode': country, 'include': 'items.artists'})
    for doc in pages(path):
        included = {r['id']: r for r in track_rows(doc)}
        for ref in data_list(doc):
            if ref.get('type') != 'tracks':
                raise Error('Playlist contains non-track items; this operation supports music tracks only.')
            result.append(included.get(str(ref['id']), {'id': str(ref['id']), 'title': '', 'artist': '', 'artists': []}))
    return result


def list_playlists(args):
    emit(owned_playlists(args.country))


def show_tracks(args):
    pid = playlist_id(args.playlist, args.country)
    emit({'id': pid, 'tracks': playlist_tracks(pid, args.country)})


def checked_entries(plan):
    if plan.get('resolution_complete') is False:
        raise Error('Resolution was interrupted. Finish resolving the input before creating a playlist.')
    entries = plan.get('entries', [])
    if not entries or any(not e.get('selected') for e in entries):
        raise Error('Resolve every track first. Review candidates in the plan or remove unresolved entries.')
    rows = [e['selected'] for e in entries]
    ids = [str(r['id']) for r in rows]
    if not 1 <= len(ids) <= 1000 or len(set(ids)) != len(ids):
        raise Error('Plan must contain 1–1000 distinct track IDs.')
    return rows


def remember(kind, key, tracks, **fields):
    save(STATE_DIR / 'records' / (key + '.json'), {
        'kind': kind, 'tracks': tracks, 'recorded_at': datetime.now(timezone.utc).isoformat(), **fields})


def guard_write(write, fingerprint):
    if write.get('fingerprint') and write['fingerprint'] != fingerprint:
        raise Error('Plan changed after a write attempt. Restore it; do not reuse write keys.')
    if write.get('attempted_at') and time.time() - write['attempted_at'] > 3500:
        raise Error('Write recovery window expired. Inspect TIDAL before starting another operation.')
    write.setdefault('attempted_at', time.time())
    write['fingerprint'] = fingerprint


def add_batches(pid, rows, write, path, document):
    """Persist one key per batch before sending; acknowledgement advances the cursor."""
    write.setdefault('batches', {})
    for offset in range(write.get('added', 0), len(rows), 50):
        key = write['batches'].setdefault(str(offset), write.get('add_key') if offset == 0 and write.get('add_key') else str(uuid.uuid4()))
        checkpoint(path, document)
        ids = [str(r['id']) for r in rows[offset:offset + 50]]
        added = api('POST', '/playlists/' + quote(pid, safe='') + '/relationships/items',
                    {'data': [{'type': 'tracks', 'id': i} for i in ids]}, key=key,
                    deadline=write['attempted_at'] + 3500)
        if [str(item['id']) for item in data_list(added)] != ids:
            raise Error('TIDAL did not acknowledge the full batch in order. Inspect the saved playlist before retrying.')
        write['added'] = offset + len(ids)
        checkpoint(path, document)


def verify_order(pid, expected, country):
    actual = [r['id'] for r in playlist_tracks(pid, country)]
    if actual != expected:
        raise Error('Saved playlist differs from the expected order (possibly edited concurrently). Inspect before retrying.')


def create(args):
    plan = load(args.plan)
    rows = checked_entries(plan)
    if not args.yes:
        raise Error('Review the plan, then pass --yes to create the playlist.')
    ids = [str(r['id']) for r in rows]
    fingerprint = digest({'name': plan['name'], 'description': plan.get('description', ''), 'ids': ids})
    archive = STATE_DIR / 'plans' / ('record-' + plan['write']['create_key'] + '.json')
    if archive.exists():
        durable = load(archive)
        if durable['write'].get('attempted_at'):
            if durable['write'].get('fingerprint') != fingerprint:
                raise Error('Plan changed after a write attempt. Restore it before retrying.')
            plan = durable
            rows = checked_entries(plan)
    write = plan['write']
    if write.get('fingerprint') and write['fingerprint'] != fingerprint:
        raise Error('Plan changed after a write attempt. Restore it before retrying.')
    if not write.get('complete'):
        guard_write(write, fingerprint)
        checkpoint(args.plan, plan)
        if not write.get('playlist_id'):
            doc = api('POST', '/playlists', {'data': {'type': 'playlists', 'attributes': {
                'name': plan['name'], 'description': plan.get('description', ''), 'accessType': 'UNLISTED',
            }}}, key=write['create_key'], deadline=write['attempted_at'] + 3500)
            write['playlist_id'] = str(doc['data']['id'])
            checkpoint(args.plan, plan)
        progress(f'Playlist recovery plan: {args.plan}')
        add_batches(write['playlist_id'], rows, write, args.plan, plan)
        verify_order(write['playlist_id'], ids, plan.get('country', DEFAULT_COUNTRY))
        write['complete'] = True
        checkpoint(args.plan, plan)
    # Also repair a missing record if a prior run exited just after completing.
    archive_plan(plan)
    remember('create', write['create_key'], rows, playlist_id=write['playlist_id'], name=plan['name'])
    emit({'playlist': 'https://tidal.com/playlist/' + write['playlist_id'], 'tracks': len(rows), 'complete': True})


def append(args):
    if args.resume:
        path = args.resume
        operation = load(path)
        if operation.get('kind') != 'append':
            raise Error('Not an append operation record.')
    else:
        if not args.source or not args.destination:
            raise Error('Specify source and destination, or --resume OPERATION.json.')
        source = playlist_id(args.source, args.country)
        destination = playlist_id(args.destination, args.country)
        before = playlist_tracks(destination, args.country)
        seen = set().union(*(identities(r) for r in before)) if before else set()
        additions = []
        for row in playlist_tracks(source, args.country):
            keys = identities(row)
            if not seen.intersection(keys):
                additions.append(row)
                seen.update(keys)
        operation = {'kind': 'append', 'source': source, 'destination': destination,
                     'country': args.country, 'before': [r['id'] for r in before], 'tracks': additions,
                     'write': {'create_key': str(uuid.uuid4()), 'add_key': str(uuid.uuid4())}}
        if not args.yes:
            emit({'destination': destination, 'append': additions, 'write': False})
            return
        path = STATE_DIR / 'operations' / ('append-' + operation['write']['create_key'] + '.json')
    if not args.yes:
        raise Error('Pass --yes to resume the append operation.')
    write = operation['write']
    fingerprint = digest({k: operation[k] for k in ('source', 'destination', 'country', 'before', 'tracks')})
    if not write.get('complete'):
        guard_write(write, fingerprint)
        save(path, operation)
        progress(f'Append recovery record: {path}')
        # No pre-write equality check on retries: an unacknowledged batch may have
        # succeeded. Its stable key replays safely; final verification detects edits.
        add_batches(operation['destination'], operation['tracks'], write, path, operation)
        verify_order(operation['destination'], operation['before'] + [r['id'] for r in operation['tracks']], operation['country'])
        write['complete'] = True
        save(path, operation)
    remember('append', write['create_key'], operation['tracks'], playlist_id=operation['destination'])
    emit({'playlist': operation['destination'], 'appended': len(operation['tracks']), 'operation': str(path)})


def delete(args):
    if args.resume:
        path = args.resume
        operation = load(path)
        if operation.get('kind') != 'delete':
            raise Error('Not a delete operation record.')
    else:
        if not args.playlist:
            raise Error('Specify a playlist, or --resume OPERATION.json.')
        pid = playlist_id(args.playlist, args.country)
        doc = api('GET', '/playlists/' + quote(pid, safe=''))
        operation = {'kind': 'delete', 'playlist_id': pid,
                     'name': doc['data']['attributes']['name'],
                     'tracks': playlist_tracks(pid, args.country),
                     'write': {'create_key': str(uuid.uuid4())}}
        if not args.yes:
            emit({'delete': pid, 'name': operation['name'], 'tracks': len(operation['tracks']), 'write': False})
            return
        path = STATE_DIR / 'operations' / ('delete-' + operation['write']['create_key'] + '.json')
    if not args.yes:
        raise Error('Pass --yes to resume deletion.')
    write = operation['write']
    fingerprint = digest({k: operation[k] for k in ('playlist_id', 'name', 'tracks')})
    if not write.get('complete'):
        guard_write(write, fingerprint)
        save(path, operation)
        progress(f'Deletion backup/recovery record: {path}')
        try:
            api('DELETE', '/playlists/' + quote(operation['playlist_id'], safe=''),
                key=write['create_key'], deadline=write['attempted_at'] + 3500)
        except APIError as exc:
            if exc.status != 404:
                raise
        try:
            api('GET', '/playlists/' + quote(operation['playlist_id'], safe=''))
        except APIError as exc:
            if exc.status != 404:
                raise
        else:
            raise Error('Playlist remains visible; retry this saved deletion operation to verify.')
        write['complete'] = True
        save(path, operation)
    remember('delete', write['create_key'], operation['tracks'], playlist_id=operation['playlist_id'], name=operation['name'])
    emit({'deleted': operation['playlist_id'], 'name': operation['name'], 'backup': str(path)})


def discover(args):
    if getattr(args, 'bpm_min', None) is not None and getattr(args, 'bpm_max', None) is not None and args.bpm_min > args.bpm_max:
        raise Error('--bpm-min must not exceed --bpm-max.')
    source = 'favorites' if getattr(args, 'from_favorites', False) else playlist_id(args.source, args.country)
    seeds = favorite_tracks() if source == 'favorites' else playlist_tracks(source, args.country)
    if not seeds:
        raise Error('Seed playlist is empty.')
    excluded = set().union(*(identities(r) for r in seeds))
    if getattr(args, 'exclude_favorites', False) and source != 'favorites':
        for row in favorite_tracks():
            excluded.update(identities(row))
    for value in args.exclude_playlist:
        rows = playlist_tracks(playlist_id(value, args.country), args.country)
        for row in rows:
            excluded.update(identities(row))
    if not args.allow_previous:
        excluded.update(recommended_keys())
    # Evenly sample the full playlist instead of always taking its first tracks.
    count = min(args.seed_limit, len(seeds))
    sampled = [seeds[(i * len(seeds)) // count] for i in range(count)]
    pool = {}
    unavailable = []
    for index, seed in enumerate(sampled):
        path = '/tracks/' + quote(seed['id'], safe='') + '/relationships/similarTracks?' + urlencode({
            'countryCode': args.country, 'include': 'similarTracks.artists'})
        try:
            rank = 0
            for doc in pages(path, args.pages, bounded=True):
                for row in track_rows(doc):
                    rank += 1
                    if not row['available'] or not row['artists'] or excluded.intersection(identities(row)):
                        continue
                    if not matches_features(row, args):
                        continue
                    row.setdefault('score', 0)
                    item = pool.setdefault(row['id'], {**row, 'score': 0, 'seeds': [], 'seed_position': index})
                    item['score'] += 1 / (rank + 2)
                    if seed['id'] not in item['seeds']:
                        item['seeds'].append(seed['id'])
        except APIError as exc:
            if exc.status not in (404, 410):
                raise
            unavailable.append(seed['id'])
            progress(f'Skipping unavailable seed: {seed["id"]}')
        progress(f'Discovery seed {index + 1}/{count}')
    selected = []
    seen = set(excluded)
    artist_counts = {}
    for row in sorted(pool.values(), key=lambda r: (-r['score'], -r['popularity'], r['id'])):
        keys = identities(row)
        names = {normalize(a) for a in row['artists']}
        if seen.intersection(keys) or any(artist_counts.get(a, 0) >= args.max_per_artist for a in names):
            continue
        selected.append(row)
        seen.update(keys)
        for artist in names:
            artist_counts[artist] = artist_counts.get(artist, 0) + 1
        if len(selected) == args.count:
            break
    if len(selected) < args.count:
        raise Error(f'Only {len(selected)} candidates meet the constraints; request fewer tracks or expand seeds/pages. Missing requested audio metadata is excluded.')
    # Follow the source's broad progression; use stable relevance order within
    # each seed region. This is not BPM, key, or audio-feature mixing.
    selected.sort(key=lambda r: (r['seed_position'], -r['score']))
    entries = [{'requested': {'artist': r['artist'], 'title': r['title']}, 'selected': r,
                'seed_track_ids': r['seeds']} for r in selected]
    plan = new_plan(args.name, entries, args.country, 'Discovery based on a seed playlist; excludes seed and previously recommended recordings.')
    plan.update({'source_playlist': source, 'unavailable_seeds': unavailable})
    path = plan_path(args.output, args.name)
    if path.exists():
        raise Error('Output already exists; choose another path.')
    save(path, plan)
    archive_plan(plan)
    emit({'plan': str(path), 'tracks': [e['selected'] for e in entries], 'unavailable_seeds': unavailable, 'created': False})


def import_plan(args):
    plan = load(args.plan)
    checked_entries(plan)
    if not isinstance(plan.get('write', {}).get('create_key'), str):
        raise Error('Not a supported saved plan.')
    destination = STATE_DIR / 'plans' / ('record-' + plan['write']['create_key'] + '.json')
    if destination.exists():
        existing = load(destination)
        if existing['write'].get('attempted_at') and existing != plan:
            raise Error('A newer durable operation already exists; refusing to replace its recovery state.')
    archive_plan(plan)
    emit({'imported': str(args.plan), 'history_updated': True})


def positive(value):
    number = int(value)
    if number < 1:
        raise argparse.ArgumentTypeError('Must be positive.')
    return number


def positive_float(value):
    number = float(value)
    if not math.isfinite(number) or number <= 0:
        raise argparse.ArgumentTypeError('Must be a finite positive number.')
    return number


def country_code(value):
    value = value.upper()
    if value == 'UK':
        value = 'GB'
    if not re.fullmatch('[A-Z]{2}', value):
        raise argparse.ArgumentTypeError('Use a two-letter country code, e.g. GB.')
    return value


def parser():
    root = argparse.ArgumentParser(description=__doc__)
    root.add_argument('--json', action='store_true', help='Machine-readable output (progress stays on stderr)')
    commands = root.add_subparsers(dest='command', required=True)
    def command(name, function, help_text, country=True):
        sub = commands.add_parser(name, help=help_text)
        sub.set_defaults(run=function)
        if country:
            sub.add_argument('--country', type=country_code, default=DEFAULT_COUNTRY, help='Catalog country (default GB; UK accepted)')
        return sub
    auth = command('login', login, 'Authorize through a local callback', False)
    auth.add_argument('--client-id', default=CLIENT_ID)
    match = command('resolve', resolve, 'Match artist/title suggestions; save a plan')
    match.add_argument('input', type=Path)
    match.add_argument('--output', type=Path, help='Defaults to a durable state-directory plan')
    match.add_argument('--pages', type=positive, default=3, help='Maximum pages per search query')
    publish = command('create', create, 'Create an unlisted playlist from a plan', False)
    publish.add_argument('plan', type=Path)
    publish.add_argument('--yes', action='store_true')
    command('playlists', list_playlists, 'List your owned playlists')
    command('favorites', favorites, 'Read your favorite tracks', False)
    inspect = command('features', features, 'Read BPM/key/mood metadata and linked local estimates')
    inspect.add_argument('target', help='Track ID, or playlist name/ID with --playlist')
    inspect.add_argument('--playlist', action='store_true')
    audio = command('analyze-audio', analyze_audio, 'Estimate tempo/key and mood descriptors from a local audio file', False)
    audio.add_argument('file', type=Path)
    audio.add_argument('--seconds', type=positive_float, default=120)
    audio.add_argument('--track-id', help='Associate this file with a TIDAL track for discovery filters')
    audio.add_argument('--output', type=Path)
    tracks = command('tracks', show_tracks, 'Read all tracks in a playlist')
    tracks.add_argument('playlist', help='Exact owned name, ID, or TIDAL URL')
    add = command('append', append, 'Append one playlist to another without duplicate recordings')
    add.add_argument('source', nargs='?')
    add.add_argument('destination', nargs='?')
    add.add_argument('--resume', type=Path)
    add.add_argument('--yes', action='store_true', help='Without this, preview only')
    remove = command('delete', delete, 'Delete a playlist, preserving a local track backup')
    remove.add_argument('playlist', nargs='?')
    remove.add_argument('--resume', type=Path)
    remove.add_argument('--yes', action='store_true', help='Without this, preview only')
    discovery = command('discover', discover, 'Generate a discovery plan from a playlist')
    discovery.add_argument('source', nargs='?', help='Exact owned name, ID, or TIDAL URL')
    discovery.add_argument('--from-favorites', action='store_true', help='Use favorite tracks instead of a playlist')
    discovery.add_argument('--exclude-favorites', action='store_true')
    discovery.add_argument('--bpm-min', type=positive_float)
    discovery.add_argument('--bpm-max', type=positive_float)
    discovery.add_argument('--key', choices=['C', 'CSharp', 'D', 'Eb', 'E', 'F', 'FSharp', 'G', 'Ab', 'A', 'Bb', 'B'])
    discovery.add_argument('--scale', type=str.upper, choices=['MAJOR', 'MINOR', 'AEOLIAN', 'BLUES', 'DORIAN', 'HARMONIC_MINOR', 'LOCRIAN', 'LYDIAN', 'MIXOLYDIAN', 'PENTATONIC_MAJOR', 'PHRYGIAN', 'MELODIC_MINOR', 'PENTATONIC_MINOR'])
    discovery.add_argument('--mood', action='append', default=[], help='Match any requested mood tag; repeat for alternatives')
    discovery.add_argument('--name', required=True)
    discovery.add_argument('--count', type=positive, default=20)
    discovery.add_argument('--seed-limit', type=positive, default=12)
    discovery.add_argument('--pages', type=positive, default=2)
    discovery.add_argument('--max-per-artist', type=positive, default=1)
    discovery.add_argument('--exclude-playlist', action='append', default=[])
    discovery.add_argument('--allow-previous', action='store_true')
    discovery.add_argument('--output', type=Path)
    imported = command('import-plan', import_plan, 'Preserve a legacy plan and recommendation history', False)
    imported.add_argument('plan', type=Path)
    return root


def main():
    global JSON_OUTPUT
    args = parser().parse_args()
    if args.command == 'discover' and bool(args.source) == bool(args.from_favorites):
        parser().error('discover requires either a source playlist or --from-favorites, not both.')
    JSON_OUTPUT = args.json
    try:
        with state_lock():
            args.run(args)
    except (Error, KeyError, ValueError, TypeError, OSError) as exc:
        if JSON_OUTPUT:
            print(json.dumps({'error': str(exc)}), file=sys.stderr)
        else:
            print(f'Error: {exc}', file=sys.stderr)
        return 1
    except KeyboardInterrupt:
        progress('Cancelled. Saved plans and operation records are retained.')
        return 130
    return 0


if __name__ == '__main__':
    sys.exit(main())
