# One cartoon at a time

Run `looney-next` to play the oldest unmarked video under
`/run/media/bertold/Media/Video/TV/Looney Tunes`, recursively.
It reads `<aired>` from the same-basename `.nfo` sidecar. Equal dates are ordered
by relative filename. Missing or invalid dates stop selection rather than
silently choosing a potentially later episode.

## Checking metadata

`looney-next --check` scans all videos, including those already prefixed with `_`,
and reports all missing, malformed or invalid aired dates together. It returns
status 1 if any problems were found, otherwise 0. It does not play, rename or
create state files. Previously marked videos whose NFO still has the original
unprefixed name are also supported. Directory-access failures count as problems.
`--dry-run` previews only the next selection; it is mutually exclusive with `--check`.

## Haruna playback

Playback uses a separate fullscreen Haruna instance with temporary settings,
your current audio/video preferences and shortcuts, and sibling loading disabled.
Normal Haruna configuration and playback history are untouched. A temporary mpv
Lua hook inside Haruna reports completion; the launcher then closes its instance.

Compatible custom commands are copied to the temporary configuration, retaining
their startup/shortcut settings. Simple `set` commands for audio, subtitles,
video presentation, volume, speed, filters and hardware decoding are supported.
Commands affecting playlists, looping, file loading, scripts or application exit,
compound commands and unknown commands are omitted with a warning naming the group.
This conservative filter may omit harmless commands; the original configuration
is never edited. The completion hook is added separately.

Normal early close exits successfully without marking. Player failures and a
missing completion-hook readiness signal (20-second startup timeout) return an
error. Ctrl+C and SIGTERM close the owned Haruna instance before releasing the
lock; they exit with status 130 and 143 respectively. The timeout only applies
to hook startup, not playback or pausing. SIGKILL cannot be cleaned up.

## Watched filenames

Only reaching the end of the file marks it watched: the video filename receives
a leading underscore. Seeking to the end also counts as completion. Closing the
player early or a playback failure leaves its name unchanged.

Matching NFOs, artwork and subtitles are renamed by default (`cartoon.nfo`,
`cartoon-thumb.jpg`, `cartoon.en.srt`, etc.). Shared files such as `tvshow.nfo`
and `poster.jpg` are left alone. Use `--no-rename-sidecars` for video-only
renaming; explicit `--rename-sidecars` remains accepted.

All destination names are checked before playback. Existing names are never
overwritten. On a rename failure, completed renames are rolled back. If rollback
fails or the process is forcibly killed during renaming, a `.pending.json` file
under `${XDG_STATE_HOME:-~/.local/state}/looney-next` records source/destination
paths and blocks further playback for that collection. Check those paths,
restore the originals or finish the renames, then remove the pending file.
A per-directory lock prevents concurrent runs from playing the same episode.

```sh
looney-next --check
looney-next --dry-run
looney-next
looney-next --no-rename-sidecars
looney-next --directory /another/collection
```

## Implementation and tests

`bin/looney-next` is a small Bash launcher for `bin/looney_next.py`. It resolves
its symlink before locating the Python module. `install.sh` already links the
entire `bin` directory into `~/bin`, so no extra installation mapping is needed.
Requires Bash, Python 3 and Haruna on Linux.

Run the permanent regression suite without opening a player or touching your collection:

```sh
PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s bin/tests -p test_looney_next.py -v
```
