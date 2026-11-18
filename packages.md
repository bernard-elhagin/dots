# Desktop package installation

Run as your regular user on an Arch/CachyOS installation with the necessary
repositories configured. The script uses sudo for pacman and runs AUR builds
as the regular user. It does not configure repositories, enable services,
restore accounts, or install your dotfile links; use `install.sh` separately.

```sh
./packages.sh --list          # Preview the default all profile without changes
./packages.sh                # Install all profiles
./packages.sh core desktop   # Shell/terminal tools and desktop environment
./packages.sh development
./packages.sh gaming media
```

- `core`: shell, terminal tools, editors, Starship and tmuxp; bootstrap Prezto and TPM.
- `desktop`: Hyprland, Quickshell, networking/audio, notifications and sounds,
  Flameshot, OpenRGB, the update utility, Thunderbird, Discord and Bibata cursors.
- `development`: compiler/build tools, Java/Node dependencies, Codex, Arduino CLI
  and language server, debugger and ShellCheck; bootstrap Neovim language servers.
- `gaming`: Steam.
- `media`: Haruna, mpv, FFmpeg, yt-dlp, TIDAL Hi-Fi, and Perl and curl for the playlist generator.

Profiles can be combined; duplicate packages are removed. `all` is the default.
Java/Node build dependencies and Neovim language-server setup now belong to the
development profile rather than core. Steam and Haruna belong to gaming and media
rather than desktop. Existing default `all` usage includes all of them.

Repository packages are installed with a full `pacman -Syu --needed` transaction.
Package names are checked against local repository databases first. Missing names
produce an error before installation; check database freshness and repository
configuration rather than silently skipping requirements. Steam needs multilib.
The desktop update command and the selected AUR helper, yay, are supplied by
CachyOS repositories on this machine. Plain Arch needs those sources or an
appropriate adaptation; the script does not silently add repositories.

Bibata (`bibata-cursor-theme-bin`) and TIDAL (`tidal-hifi-bin`) are fetched through
yay when unavailable in configured repositories. Both desktop and media include
Git/base-devel/yay prerequisites. Repository versions are preferred when available.
Normal transaction and AUR review prompts remain enabled.

Package installation alone does not reconstruct the complete desktop. OpenRGB
profiles and service setup, application preferences, session state and private
credentials remain separate restoration steps. TPM is bootstrapped, but its
configured plugins still need installation (prefix + I after loading your tmux
configuration). See desktop-restore.md for the separate configuration, service and private-backup workflow.
