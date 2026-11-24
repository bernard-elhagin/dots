# TIDAL playlist tool

A Perl CLI for importing suggested tracks, generating similar-track discovery
plans, and managing TIDAL playlists. It requires Perl 5.36 or later and curl.
Local audio analysis additionally requires FFmpeg and the Linux `timeout` command.
The bundled
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
cover versions. Before accepting a remaster it checks the fallback queries for
an original. It rejects unrequested live, mix, remix,
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

`append-current` reads the playing track URL from TIDAL Hi-Fi using `playerctl`
and applies the same duplicate checks. It previews by default. Use `--yes`
to append, and `--notify` to show the outcome with the track title and artist.

```bash
./bin/tidal-playlist append-current ugotocooked --yes --notify
```

## Discovery

```bash
./bin/tidal-playlist discover Cooked --name 'Cooked — Third Helping' --count 20 --exclude-playlist 'Ghosts in the Rhythm'
./bin/tidal-playlist discover --artist "Angine de Poitrine" --name "Angine de Poitrine discoveries"
./bin/tidal-playlist discover --track "King Crimson - 21st Century Schizoid Man" --name "Schizoid discoveries" --count 10
```

This creates a **local plan only**. Review it, then run `create PLAN.json --yes`.
Discovery samples evenly across the source playlist (12 seeds by default),
queries TIDAL's similar-track recommendations, scores repeated recommendations,
and limits artist repetition. It excludes seed tracks, explicit excluded
playlists, and previously recommended recordings by ID, ISRC, and normalized
artist/title. Favorites can optionally be excluded or used as seeds; they are
not a complete listening history.

`--artist` accepts a single exact artist name (case and accents are ignored).
Ambiguous matches are rejected. It gathers playable tracks credited to the matched
TIDAL artist from up to 12 releases, deduplicates recordings, then uses the same
discovery options and seed limit as playlist mode. Choose exactly one seed source:
a playlist, `--artist`, `--track`, `--covers`, or `--from-favorites`.

`--track` accepts a numeric TIDAL track ID, a TIDAL track URL, or
`"Artist - Track title"`. Use an ID or URL to pick a specific edition or
when the text search cannot identify a single playable recording.

Combine `--track` and `--artist` to use the track as the seed and keep only
recommendations that credit the specified TIDAL artist. Collaborations can
qualify. This mode returns up to `--count` tracks, and an explicit
`--max-per-artist` still applies.

```bash
./bin/tidal-playlist discover --track 68714378 --artist "Talking Heads" --name "Similar Talking Heads"
```

Useful options:

- `--seed-limit N`: maximum representative seed tracks.
- `--pages N`: recommendation pages per seed (default 2).
- `--max-per-artist N`: cap per artist, including credited collaborators (default 1, or `--count` with `--track` plus `--artist`).
- `--exclude-playlist NAME_OR_ID`: repeat for multiple playlists.
- `--allow-previous`: permit earlier recommendations, keeping other exclusions.
- `--country GB` and `--output PATH`: override catalog or plan location.
- `--from-favorites`: use favorite tracks instead of a source playlist.
- `--exclude-favorites`: omit your favorite tracks from recommendations.
- `--bpm-min N`, `--bpm-max N`, `--key C`, `--scale MAJOR`: require audio features.
- `--mood TAG`: match any supplied mood tag (repeat for alternatives).

Unavailable seeds are reported and skipped, including seeds whose recommendation
requests return 404/410. The tool tries other seeds to fill the available slots
and keeps unavailable track IDs in the exclusion list. Other API failures stop
the operation. Similar-track discovery without an artist filter requires the
requested count. Sequencing follows the source's broad
seed order and relevance within each region; it does not analyze BPM, musical
key, or mood for sequencing. Requested audio-feature filters use catalog
metadata or explicitly linked local analysis; missing values fail the filter.
Planned suggestions count as previously recommended even if you
haven't published them. Deletion backups are separate from recommendation history.
To repeat past suggestions, use `--allow-previous`.

### Covers of a song

```bash
./bin/tidal-playlist discover --covers 22717450 --name "Watchtower Covers" --count 12
```

`--covers` accepts the same input as `--track`. It uses the seed's ISRC to
identify the composition in [MusicBrainz](https://musicbrainz.org/doc/How_to_Use_Works),
then matches recordings marked as covers to playable TIDAL tracks by ISRC.
It excludes the seed recording, karaoke, medleys, and partial performances.
The plan records the MusicBrainz work and recording IDs.

The result contains up to `--count` tracks and can be shorter when cover
credits, recording IDs, or regional catalog availability are limited.
`--pages` controls how many MusicBrainz recording pages to check, with up
to 100 recordings per page. Discovery exclusions and audio filters also apply.

## Ignoring artists

```bash
./bin/tidal-playlist --ignore "Artist One" --ignore "Artist Two"
./bin/tidal-playlist ignore
./bin/tidal-playlist discover Cooked --name "Cooked Discoveries" --ignore "Artist Three"
```

Repeat `--ignore` for each artist. You can save names separately or pass
them to `discover`, `resolve`, or `create`. Names are matched against individual
artist credits, including guest artists, with case and accent differences
ignored. Discovery and cover plans can still use an ignored artist as a seed.
With an ignore list, the tool rechecks missing artist credits against the catalog.
`create` stops before issuing playlist writes if any track credits an ignored
artist or its full credits cannot be verified.

The list lives in `$XDG_STATE_HOME/tidal-playlist/ignored-artists.json`,
defaulting to `~/.local/state/tidal-playlist/ignored-artists.json`. To remove a
name, delete it from that JSON array while the tool is idle. Saved preferences
apply to the Perl launcher.

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

The audio analysis runs in Perl after FFmpeg decodes the input.

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

Stable idempotency keys are saved **before** each write. If an interrupted batch
needs to be replayed, it uses its original key. After roughly
58 minutes, unfinished operations stop for manual reconciliation because TIDAL
only retains idempotency responses for one hour. Do not change in-progress
operation files or reuse keys for other requests. Before each append batch the
tool checks the destination against the checkpoint. On resume it accepts an
already visible pending batch in the expected order and stops on conflicting
edits. Other TIDAL clients can still edit during a request, so final order
verification still runs. Avoid running another playlist editor during a mutation.

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

The Perl launcher uses the same state directory, login tokens, plan files,
recommendation history and linked audio metadata as the original Python CLI.
The original Python entry point remains available for rollback and old recovery
records. If an unchanged Python append or delete record fails fingerprint
validation in Perl due to JSON number formatting, use the original command
within the existing recovery window:

```sh
python3 apps/tidal-playlist/tidal_playlist.py append --resume OPERATION.json --yes
python3 apps/tidal-playlist/tidal_playlist.py delete --resume OPERATION.json --yes
```

Use the Perl launcher for writes first attempted by Perl.

## Automation and checks

Place `--json` before the subcommand for machine-readable results. Progress
is printed to stderr; errors return a nonzero exit status. Login success alone
is not a live API permission test.

```bash
./bin/tidal-playlist --json playlists
prove -v apps/tidal-playlist/t/port.t
bash -n bin/tidal-playlist
```

The Perl tests use temporary state, mocked API responses and synthetic audio.
The original Python regression suite remains in `tests/` for the legacy CLI.
The installer links the launcher into `~/.local/bin/tidal-playlist`.

API contract: https://tidal-music.github.io/tidal-api-reference/
Authorization: https://developer.tidal.com/documentation/api-sdk/api-sdk-authorization
