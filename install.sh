#!/usr/bin/env bash

set -euo pipefail

DOTS_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

backup_path() {
    local destination="$1"
    local timestamp backup suffix

    timestamp="$(date +%Y%m%d-%H%M%S)"
    backup="${destination}.backup-${timestamp}"
    suffix=1

    while [[ -e "$backup" || -L "$backup" ]]; do
        backup="${destination}.backup-${timestamp}-${suffix}"
        ((suffix += 1))
    done

    mv -- "$destination" "$backup"
    printf 'Backed up %s to %s\n' "$destination" "$backup"
}

link_path() {
    local source="$1"
    local destination="$2"
    local destination_dir

    if [[ ! -e "$source" ]]; then
        printf 'Source does not exist: %s\n' "$source" >&2
        return 1
    fi

    if [[ -L "$destination" && "$(readlink -f -- "$destination")" == "$(readlink -f -- "$source")" ]]; then
        printf 'Already linked: %s\n' "$destination"
        return 0
    fi

    destination_dir="$(dirname -- "$destination")"
    mkdir -p -- "$destination_dir"

    if [[ -e "$destination" || -L "$destination" ]]; then
        backup_path "$destination"
    fi

    ln -s -- "$source" "$destination"
    printf 'Linked %s -> %s\n' "$destination" "$source"
}

link_repo_path() {
    local repository_path="$1"
    local home_path="$2"

    link_path "$DOTS_DIR/$repository_path" "$HOME/$home_path"
}

install_tmux() {
    local destination="$HOME/.tmux"
    local plugins=""
    local name

    # Keep TPM and downloaded plugins in a real home directory. Linking the
    # whole directory would back up the plugins installed by packages.sh.
    if [[ -L "$destination" ]]; then
        if [[ -d "$destination/plugins" ]]; then
            plugins="$(readlink -f -- "$destination/plugins")"
        fi
        backup_path "$destination"
    elif [[ -e "$destination" && ! -d "$destination" ]]; then
        backup_path "$destination"
    fi
    mkdir -p -- "$destination"
    if [[ -n "$plugins" ]]; then
        link_path "$plugins" "$destination/plugins"
    fi
    for name in tmux.conf clipboard-copy.sh tmuxp; do
        link_repo_path "tmux/$name" ".tmux/$name"
    done
}

install_desktop() {
    local name

    # Link configuration files individually: keep session state and local files
    # outside the repository, and let HyprMod edit its linked settings file.
    for name in hyprland.lua hyprland.conf hyprpaper.conf hyprland-gui.lua; do
        link_repo_path "hypr/$name" ".config/hypr/$name"
    done
    link_repo_path hypr/wallpapers .config/hypr/wallpapers
    # Includes the active futuristic Retro bar, its helper scripts, and the
    # saved cyan Retro preset. Hyprland starts it with `qs -n -c retro`.
    link_repo_path config/quickshell .config/quickshell
    link_repo_path config/mako/config .config/mako/config
    link_repo_path bin/pomodoro .local/bin/pomodoro
    for name in launcher system networkmenu vpn; do
        link_repo_path "config/rofi/$name.rasi" ".config/rofi/$name.rasi"
    done
    for name in system networkmenu vpnmenu checkupdates; do
        link_repo_path "config/waybar/scripts/$name.sh" ".config/waybar/scripts/$name.sh"
    done
}

case "${1:-}" in
    --desktop-only)
        if (( $# != 1 )); then
            printf 'Usage: %s [--desktop-only]\n' "$0" >&2
            exit 2
        fi
        install_desktop
        exit 0
        ;;
    '') ;;
    *)
        printf 'Usage: %s [--desktop-only]\n' "$0" >&2
        exit 2
        ;;
esac

# Directory configurations
link_repo_path vim .vim
link_repo_path zsh .zsh
link_repo_path bin bin
install_tmux

# Application configurations
link_repo_path codex/skills/desktop-troubleshooting .codex/skills/desktop-troubleshooting
link_repo_path codex/skills/shell-scripting .codex/skills/shell-scripting
link_repo_path codex/skills/systemd-troubleshooting .codex/skills/systemd-troubleshooting
link_repo_path codex/skills/dotfile-management .codex/skills/dotfile-management
link_repo_path i3/config .config/i3/config
link_repo_path config/doublecmd .config/doublecmd
link_repo_path config/nvim .config/nvim
install_desktop

# Individual dotfiles
declare -a FILES_TO_SYMLINK=(
    'zprezto/runcoms/zlogin:.zlogin'
    'zprezto/runcoms/zlogout:.zlogout'
    'zprezto/runcoms/zpreztorc:.zpreztorc'
    'zprezto/runcoms/zprofile:.zprofile'
    'zprezto/runcoms/zshenv:.zshenv'
    'zprezto/runcoms/zshrc:.zshrc'
    'fzf.sh:.fzf.sh'
    'vimrc:.vimrc'
    'tmux/tmux.conf:.tmux.conf'
    'git/gitconfig:.gitconfig'
    'git/gitignore:.gitignore'
    'config/starship.toml:.starship.toml'
    'codex/AGENTS.md:.codex/AGENTS.md'
)

for entry in "${FILES_TO_SYMLINK[@]}"; do
    repository_path="${entry%%:*}"
    home_path="${entry#*:}"
    link_repo_path "$repository_path" "$home_path"
done

# fzf's shell integrations are copied into its generated setup directory.
mkdir -p -- "$HOME/.fzf"
cp -- "$DOTS_DIR"/fzf/*.zsh "$HOME/.fzf/"
