# TIDAL playlist tool

A Python standard-library CLI for importing suggested tracks, generating
similar-track discovery plans, and managing TIDAL playlists. Core operations
need no AI API key or third-party Python packages; optional local audio analysis
uses NumPy and FFmpeg. The bundled
`ghosts-in-the-rhythm.json` is an example suggestion list.

## Login

Allow `playlists.read`, `playlists.write`, `search.read`, and `collection.read` in your TIDAL
developer application, with `http://127.0.0.1:8765/callback` registered exactly:

```bash
./bin/tidal-playlist login
```

Open the printed link in a browser on this computer and authorize access.
The local callback checks OAuth state and uses PKCE. The default Client ID
identifies the user's developer application; override it with
`login --client-id ID`. No client secret is needed.

Tokens live in `$XDG_STATE_HOME/tidal-playlist/tokens.json`, defaulting to
`~/.local/state/tidal-playlist/tokens.json`. They are saved atomically with
owner-only permissions and never belong in Git. Tokens refresh before expiry;
a server-side 401 triggers one refresh and replay. Rejected refreshes require
login again. Concurrent CLI operations are refused by a local lock to protect
refresh-token rotation and operation records.
After adding `collection.read` to an existing application, run `login` again:
changing allowed scopes does not add permissions to an already-issued token.

## Automatic matching

```bash
./bin/tidal-playlist resolve apps/tidal-playlist/ghosts-in-the-rhythm.json
./bin/tidal-playlist create ~/.local/state/tidal-playlist/plans/PLAN.json --yes
```

The catalog defaults to **GB**. `--country UK` is accepted as an alias for GB.
Override with the relevant account country on commands that read the catalog.
`resolve` reports the saved plan path; `--output PATH` overrides it.

Inputs contain `name`, optional `description`, and `tracks`, each with `artist`
and `title`. Supply an optional `version` to request a particular mix:

```json
{
  "name": "Example",
  "tracks": [
    {"artist": "Can", "title": "Moonshake"},
    {"artist": "A Certain Ratio", "title": "Shack Up", "version": "Work Mix"}
  ]
}
```

Matching searches artist+title, then title alone and artist alone if needed.
It reads up to three pages per query (`--pages N` changes the bound). Exact
artist identity is still required; loose search results cannot silently become
cover versions. It prefers original editions to labelled remasters, allows a
remaster when no original is found, and rejects unrequested live, mix, remix,
edit, acoustic, instrumental, demo, karaoke, and tribute versions. Unknown
version labels are reviewed rather than assumed to be originals. Several
editions sharing one ISRC may resolve automatically; ambiguous distinct
recordings remain unresolved.

Inspect the plan's `candidates` and replace an entry's `selected` object with
the intended candidate, or remove an unwanted entry. Only edit **before** the
first creation attempt. Interrupted resolution is marked incomplete and cannot
be published: rerun resolution into a new output file. Search is bounded, so
unresolved does not prove that a track is absent from TIDAL.

`create` supports up to 1000 distinct track IDs, writes in batches of at most
50, preserves order, and reads back the playlist to verify the complete order.
It creates UNLISTED playlists: unlisted is not private; people with the link
can access them. No external playlist changes happen during `resolve`.

## Read and manage playlists

Use an exact owned playlist name, ID, or TIDAL playlist URL. Duplicate names
require an ID/URL rather than guessing.

```bash
./bin/tidal-playlist playlists
./bin/tidal-playlist tracks Cooked
./bin/tidal-playlist append 'Cooked — Second Helping' Cooked
./bin/tidal-playlist append 'Cooked — Second Helping' Cooked --yes
./bin/tidal-playlist delete 'Cooked — Second Helping'
./bin/tidal-playlist delete 'Cooked — Second Helping' --yes
```

`append` and `delete` **preview by default**; `--yes` performs the operation.
Append skips existing IDs, ISRCs, and artist/base-title duplicates (including
remastered editions), both against the destination and within the source. It
preserves destination order and appends in source order. Name matching is
conservative: different versions of the same song can be skipped as familiar.
Deletion saves the playlist name and track metadata locally before the request,
then checks that the playlist is no longer available. The backup is a track
snapshot, not a restoration of the original playlist ID or sharing settings.

All collection reads follow pagination, failing if their safety limit is
exceeded rather than treating an incomplete read as complete. Mixed playlists
containing videos are rejected by track-management commands.

## Discovery from an existing playlist

```bash
./bin/tidal-playlist discover Cooked --name 'Cooked — Third Helping' --count 20 --exclude-playlist 'Ghosts in the Rhythm'
```

This creates a **local plan only**. Review it, then run `create PLAN.json --yes`.
Discovery samples evenly across the source playlist (12 seeds by default),
queries TIDAL's similar-track recommendations, scores repeated recommendations,
and limits artist repetition. It excludes seed tracks, explicit excluded
playlists, and previously recommended recordings by ID, ISRC, and normalized
artist/title. Favorites can optionally be excluded or used as seeds; they are
not a complete listening history.

Useful options:

- `--seed-limit N`: maximum representative seed tracks.
- `--pages N`: recommendation pages per seed (default 2).
- `--max-per-artist N`: cap per artist, including credited collaborators (default 1).
- `--exclude-playlist NAME_OR_ID`: repeat for multiple playlists.
- `--allow-previous`: permit earlier recommendations, keeping other exclusions.
- `--country GB` and `--output PATH`: override catalog or plan location.
- `--from-favorites`: use favorite tracks instead of a source playlist.
- `--exclude-favorites`: omit your favorite tracks from recommendations.
- `--bpm-min N`, `--bpm-max N`, `--key C`, `--scale MAJOR`: require audio features.
- `--mood TAG`: match any supplied mood tag (repeat for alternatives).

Unavailable seeds (404/410) are reported and skipped. Other API failures stop
the operation. Insufficient eligible candidates cause an explicit error rather
than silently relaxing your constraints. Sequencing follows the source's broad
seed order and relevance within each region; it does not analyze BPM, musical
key, or mood for sequencing. Requested audio-feature filters use catalog
metadata or explicitly linked local analysis; missing values fail the filter.
Planned suggestions count as previously recommended even if you
haven't published them. To repeat them, use `--allow-previous`.

## Favorites and audio features

```bash
./bin/tidal-playlist favorites
./bin/tidal-playlist discover --from-favorites --name 'Favorite-adjacent discoveries' --count 20
./bin/tidal-playlist discover Cooked --name 'New grooves' --exclude-favorites --bpm-min 100 --bpm-max 125
./bin/tidal-playlist features 16025705
./bin/tidal-playlist features Cooked --playlist
```

`favorites` reads all pages of your favorite tracks, preserving unavailable
track IDs for exclusions. It does not add, remove, or change favorites. The
endpoint uses the authenticated user's market. Playlist/catalog queries use
the selected country, GB by default.

`features` exposes TIDAL's optional `bpm`, `key`, `keyScale`, and `toneTags` as
`audio_features`, with `source=tidal_metadata`. Those are supplied metadata,
not measurements made by this tool. Missing, invalid, and UNKNOWN values stay
unknown. A live check found all four missing on one catalog track; do not assume
catalog-wide coverage. Arbitrary mood tags are matched case-insensitively;
there is no synonym translation or inference of emotions from the title.

### Actual local audio analysis

The machine needs NumPy and FFmpeg. If NumPy is unavailable, use a virtual
environment with `requirements-audio.txt` rather than changing system Python:

```bash
python3 -m venv /tmp/tidal-audio-venv
/tmp/tidal-audio-venv/bin/pip install -r apps/tidal-playlist/requirements-audio.txt
/tmp/tidal-audio-venv/bin/python apps/tidal-playlist/tidal_playlist.py analyze-audio /path/to/track.flac
```

With NumPy already installed for the launcher's Python:

```bash
./bin/tidal-playlist analyze-audio /path/to/track.flac --seconds 120 --track-id 16025705
```

This decodes the first 5–300 seconds of a local audio file (default 120), using
bounded FFT blocks. It estimates tempo from spectral-flux autocorrelation and
key/major-minor scale from chroma energy correlations with tonal profiles.
Weak/ambiguous estimates and silence return null. Results include tempo
strength and key correlation/margin; these are diagnostic scores, not calibrated
probabilities. Tempo can be half/double the perceived beat, and songs with
changing key/tempo or non-Western tuning can be poorly represented. Synthetic
beat, tonal, and silent fixtures are tested; accuracy on a real music benchmark
has not been established.

Local `moods` are explicitly **heuristic descriptors**: `bright`/`dark` derive
from spectral brightness; `energetic`/`calm` additionally use tempo and rhythmic
strength. They are not a trained emotion classifier and do not establish that
a track is happy, sad, or appropriate to a particular activity. Catalog mood
tags remain a separate source.

`--track-id` explicitly associates the file with a TIDAL recording for later
discovery filters; the tool cannot independently prove that association. Linked
estimates are saved under `audio/` and preferred when present, falling back to
catalog fields where local estimates are unknown. `effective_features` reports
field-level sources when combined. Without `--track-id`, results are printed
only, unless `--output PATH` is given. The audio segment hash is recorded;
decoded audio is not retained. This tool does not download, decrypt, or record
TIDAL streams for analysis.

## Durable state and recovery

State lives under `$XDG_STATE_HOME/tidal-playlist/` (normally
`~/.local/state/tidal-playlist/`):

- `plans/`: generated plans and durable checkpoints, including user-selected
  output plans originally written elsewhere.
- `operations/`: append/delete recovery records and deletion snapshots.
- `records/`: completed operations and recommendation history metadata.
- `audio/`: explicitly linked local measurements and their source information.
- `tokens.json`: credentials; never include this in shared diagnostics.

The command prints recovery paths before mutation. After interruption, rerun
`create` on the same plan or its durable `plans/record-KEY.json` checkpoint.
Append/delete have explicit recovery commands:

```bash
./bin/tidal-playlist append --resume ~/.local/state/tidal-playlist/operations/append-KEY.json --yes
./bin/tidal-playlist delete --resume ~/.local/state/tidal-playlist/operations/delete-KEY.json --yes
```

Stable idempotency keys are saved **before** each write. Completed batches are
not repeated; interrupted batches replay with their original key. After roughly
58 minutes, unfinished operations stop for manual reconciliation because TIDAL
only retains idempotency responses for one hour. Do not change in-progress
operation files or reuse keys for other requests. Remote concurrent edits are
not locked; final order verification catches conflicts, and never overwrites
them automatically. Avoid running another playlist editor during a mutation.

429 and transient server/network failures have at most two retries, retaining
write keys. `Retry-After` is respected; a delay over 30 seconds is reported to
the user instead of sleeping indefinitely. OAuth requests are not automatically
retried, avoiding ambiguous refresh-token rotation. A lost OAuth response may
require login again. Failed requests can still have succeeded server-side;
always reuse the saved recovery record.

Import older temporary plans into durable history before removing them:

```bash
./bin/tidal-playlist import-plan /tmp/bertold/ghosts-plan-gb.json
```

`import-plan` only saves local state; it never changes a TIDAL playlist. Keep
operation and plan files private: they contain listening-related metadata,
although no OAuth tokens are embedded. No automatic state cleanup is performed.

## Automation and checks

Place `--json` before the subcommand for machine-readable results. Progress
is printed to stderr; errors return a nonzero exit status. Login success alone
is not a live API permission test.

```bash
./bin/tidal-playlist --json playlists
python3 -m unittest discover -s apps/tidal-playlist/tests -v
bash -n bin/tidal-playlist
```

Tests use temporary state and mocked API/transport responses; they never modify
a real TIDAL account. They cover matching/version rules, pagination, OAuth state,
refresh, retries, chunked writes and recovery, append/delete, and discovery
constraints. The installer links the launcher into `~/.local/bin/tidal-playlist`;
it never logs in or changes playlists automatically.

API contract: https://tidal-music.github.io/tidal-api-reference/
Authorization: https://developer.tidal.com/documentation/api-sdk/api-sdk-authorization
