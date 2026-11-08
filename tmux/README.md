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
