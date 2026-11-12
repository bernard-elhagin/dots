# Hyprland session snapshots

Run `hypr-save.sh` before logging out, then `hypr-restore.sh` after logging in.
Both are wrappers for `hypr-session.sh save|restore`; all accept
`--file /path/to/snapshot.json`. The default is `~/.config/hypr/session.json`.
Run a fresh save to capture placement metadata. Old version-1 JSON snapshots
remain readable; the old `saved_session.txt` format is no longer used.

Saving is atomic and does not modify windows. Snapshots include process
arguments and working directories, workspace/monitor assignments, window
identity, floating geometry and fullscreen state. Snapshot permissions are 600.
Restoring launches saved argument arrays directly, without evaluating shell code.

## Persistent startup commands

Add an optional `startup` object to a window in the JSON snapshot. Its `argv`
replaces the captured process command when that window needs launching. `cwd`
overrides its working directory; an explicit missing directory causes an error.
`class` identifies the newly launched window and should be unique when multiple
terminals are saved. For example:

```json
"startup": {
  "argv": ["xfce4-terminal", "--disable-server", "--class=CodexSession",
           "--title=Codex", "--working-directory=/home/bertold/dots",
           "-x", "zsh", "-ic", "codex resume"],
  "cwd": "/home/bertold/dots",
  "class": "CodexSession"
}
```

These are literal argument arrays, not shell command strings. Only explicitly
invoking a shell (as above) interprets shell syntax. Existing matched windows
are reused without rerunning startup commands. Codex opens its session picker;
changing the last argument to `codex resume --last` resumes the latest session.

Saving preserves startup settings by the live window address/class, then a
unique configured class, then a unique title/class/workspace match. Dynamic
titles therefore work reliably with a unique class. Closed or ambiguous startup
entries are retained with a warning so their settings are not lost; they remain
eligible to launch on restore. Remove the old entry to stop restoring it.
Invalid startup settings prevent overwriting the snapshot. Keep this file
trusted: restore runs the commands it contains with your user permissions.

## Window placement

Restore matches existing windows by application class and title, preferring the
saved workspace. If no exact title exists, it can reuse an unclaimed same-class
window on the target workspace. Each live window can be matched only once.
Missing windows are launched sequentially and polled for up to 15 seconds.
Steam gets up to 180 seconds and must match the saved window title, so startup
and dialog windows do not end the wait early. Its launcher may hand off to an
existing process; reused windows are also checked during this wait.
Every matched window is explicitly moved by its new address to its saved workspace.
Workspace focus at launch time is only a hint, not the placement mechanism.

Floating position/size and fullscreen state are restored. Single-master layouts
also save the master and stack order, orientation and an approximate split ratio
inferred from geometry. Master reconstruction requires all saved tiled windows,
the master layout still configured, and no additional tiled windows. Multi-master,
center-master layouts and exact dwindle split trees are not reconstructed.
Window groups, unequal stack heights, changed monitor geometry, and application
internal state (tabs, documents, terminal programs) are not reconstructed either.

Single-instance applications may reuse a window instead of creating one, and
saved process arguments are not universally sufficient to reopen an application.
Ambiguous multiple new windows are skipped rather than assigned arbitrarily.
Review the restore output for skips or dispatch errors. The restore is best effort,
not a guarantee that every application can reproduce its previous windows.

Tests: `python3 -m unittest discover -s bin/tests -v` from the repository root.
Tests simulate Hyprland; a real save/logout/restore remains necessary to verify
application behavior on the desktop.
