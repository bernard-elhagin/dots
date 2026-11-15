# tmux installation

Run `packages.sh` before `install.sh`. The package script clones TPM to
`~/.tmux/plugins/tpm`; the installer keeps `~/.tmux` as a real directory and
links `tmux.conf`, `clipboard-copy.sh`, and `tmuxp` individually, preserving
downloaded plugins. The main configuration is also linked as `~/.tmux.conf`.

If a previous installation linked the entire `~/.tmux` directory, the installer
backs up that symlink and preserves access to its existing plugins directory.
Repeated installation leaves correct links and existing plugins alone.

TPM's additional plugins still require installation using prefix + `I` in tmux
(uppercase I). This change fixes preservation of TPM; it does not automatically
download every plugin.

## Save and restore layouts

`tmux-resurrect` saves sessions, windows, pane layouts, working directories,
and the active pane. With the configured prefix:

- **Ctrl+Q, then Ctrl+S** saves the current tmux environment.
- **Ctrl+Q, then Ctrl+R** restores the latest snapshot.

Snapshots live in `~/.local/state/tmux/resurrect/`; `last` points to the latest
save. Start tmux after a reboot, then use the restore shortcut. Restore does
not overwrite existing windows, so use a fresh tmux server/session when
recreating a complete environment. Layouts adapt to the available terminal size.
Only Codex and the bundled Pomodoro app are automatically restarted. Codex uses
`codex resume`, which opens its conversation picker; Pomodoro uses the installed
`pomodoro` launcher. Other panes reopen as shells in their saved directories.
Scrollback is not saved, and restarting Pomodoro is not a snapshot of an
in-progress countdown.
