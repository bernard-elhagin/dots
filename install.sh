#!/usr/bin/env bash

set -euo pipefail

DOTS_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
check_only=0
desktop_only=0
check_ok=0
check_issues=0
check_skipped=0

report_check() {
    local status="$1" path="$2" detail="${3:-}"
    printf '%-14s %s%s\n' "$status" "$path" "${detail:+ ($detail)}"
    case "$status" in
        OK) ((check_ok += 1)) ;;
        SKIPPED) ((check_skipped += 1)) ;;
        *) ((check_issues += 1)) ;;
    esac
}

report_pending() {
    local source="$1" destination="$2" action="$3"
    local parent detail
    parent="$(dirname -- "$destination")"
    detail="copy $source"
    if [[ "$action" == link ]]; then
        detail="link to $source"
    fi

    while [[ ! -d "$parent" ]]; do
        if [[ -e "$parent" || -L "$parent" ]]; then
            report_check 'BLOCKED' "$destination" "parent is not a directory: $parent"
            return
        fi
        parent="$(dirname -- "$parent")"
    done

    if [[ -L "$destination" && ! -e "$destination" ]]; then
        report_check 'BROKEN LINK' "$destination" "would back up the link and $detail"
    elif [[ -L "$destination" && "$action" == link ]]; then
        report_check 'WRONG TARGET' "$destination" "points to $(readlink -- "$destination"); would back up the link and $detail"
    elif [[ -e "$destination" || -L "$destination" ]]; then
        report_check 'WOULD BACK UP' "$destination" "then $detail"
    else
        report_check 'MISSING' "$destination" "would $detail"
    fi
}

finish_check() {
    if (( check_only )); then
        printf '\nCheck summary: %d OK, %d need attention, %d skipped.\n' "$check_ok" "$check_issues" "$check_skipped"
        if (( check_issues )); then
            exit 1
        fi
    fi
}

backup_path() {
    local destination="$1"
    local backup_base="$destination"
    local timestamp backup suffix

    if [[ "$destination" == "$HOME/.codex/skills/"* ]]; then
        # Keep a backup from being discovered as a second copy of the skill.
        backup_base="$HOME/.codex/skill-backups/${destination##*/}"
        mkdir -p -- "$(dirname -- "$backup_base")"
    fi

    timestamp="$(date +%Y%m%d-%H%M%S)"
    backup="${backup_base}.backup-${timestamp}"
    suffix=1

    while [[ -e "$backup" || -L "$backup" ]]; do
        backup="${backup_base}.backup-${timestamp}-${suffix}"
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
        if (( check_only )); then
            report_check 'MISSING SOURCE' "$destination" "expected $source"
            return
        fi
        printf 'Source does not exist: %s\n' "$source" >&2
        return 1
    fi

    if [[ -L "$destination" && "$(readlink -f -- "$destination")" == "$(readlink -f -- "$source")" ]]; then
        if (( check_only )); then
            report_check OK "$destination" "link to $source"
        else
            printf 'Already linked: %s\n' "$destination"
        fi
        return 0
    fi

    if (( check_only )); then
        report_pending "$source" "$destination" link
        return
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

copy_repo_config() {
    local source="$DOTS_DIR/$1" destination="$HOME/$2"
    if (( check_only )) && [[ ! -f "$source" ]]; then
        report_check 'MISSING SOURCE' "$destination" "expected $source"
        return
    fi
    if [[ -f "$destination" && ! -L "$destination" ]] && cmp -s -- "$source" "$destination"; then
        if (( check_only )); then
            report_check OK "$destination" "copy matches $source"
        fi
        return
    fi
    if (( check_only )); then
        report_pending "$source" "$destination" copy
        return
    fi
    mkdir -p -- "$(dirname -- "$destination")"
    if [[ -e "$destination" || -L "$destination" ]]; then
        backup_path "$destination"
    fi
    # Applications add history/state to these files: never write that into Git.
    install -m 600 -- "$source" "$destination"
}

install_tmux() {
    local destination="$HOME/.tmux"
    local plugins=""
    local name

    # Keep TPM and downloaded plugins in a real home directory. Linking the
    # whole directory would back up the plugins installed by packages.sh.
    if [[ -L "$destination" || ( -e "$destination" && ! -d "$destination" ) ]]; then
        if (( check_only )); then
            report_check 'WOULD BACK UP' "$destination" 'then recreate it as a directory and install the tmux links'
            link_repo_path tmux/tmuxp .tmuxp
            return
        fi
        if [[ -L "$destination" && -d "$destination/plugins" ]]; then
            plugins="$(readlink -f -- "$destination/plugins")"
        fi
        backup_path "$destination"
    fi
    if (( ! check_only )); then
        mkdir -p -- "$destination"
    fi
    if [[ -n "$plugins" ]]; then
        link_path "$plugins" "$destination/plugins"
    fi
    for name in tmux.conf clipboard-copy.sh tmuxp; do
        link_repo_path "tmux/$name" ".tmux/$name"
    done
    link_repo_path tmux/tmuxp .tmuxp
}

install_firefox_stylesheet() {
    local root profile
    local found=0
    for root in "${XDG_CONFIG_HOME:-$HOME/.config}/mozilla/firefox" "$HOME/.mozilla/firefox"; do
        [[ -r "$root/profiles.ini" ]] || continue
        while IFS= read -r profile; do
            [[ "$profile" == /* ]] || profile="$root/$profile"
            [[ -d "$profile" ]] || continue
            found=1
            link_path "$DOTS_DIR/config/firefox/userContent.css" "$profile/chrome/userContent.css"
        done < <(awk '
            function save_profile() {
                if (section ~ /^\[Profile[0-9]+\]$/ && selected && path != "")
                    fallback = path
            }
            { sub(/\r$/, "") }
            /^\[/ { save_profile(); section = $0; path = ""; selected = 0; next }
            section ~ /^\[Install[^]]+\]$/ && /^Default=./ { installs[substr($0, 9)] = 1 }
            /^Path=/ { path = substr($0, 6) }
            /^Default=1$/ { selected = 1 }
            END {
                save_profile()
                if (length(installs)) {
                    for (profile in installs) print profile
                } else if (fallback != "") print fallback
            }
        ' "$root/profiles.ini")
    done
    if (( check_only && ! found )); then
        report_check 'SKIPPED' 'Firefox stylesheet' 'no registered default profile found'
    fi
}

install_desktop() {
    local name
    link_repo_path bin bin

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
    link_repo_path bin/openrgb-keyboard-startup .local/bin/openrgb-keyboard-startup
    link_repo_path bin/desktop-session-startup .local/bin/desktop-session-startup
    link_repo_path config/openrgb/profiles .config/openrgb/profiles
    copy_repo_config config/haruna/haruna.conf .config/haruna/haruna.conf
    copy_repo_config config/haruna/shortcuts.conf .config/haruna/shortcuts.conf
    copy_repo_config config/flameshot/flameshot.ini .config/flameshot/flameshot.ini
    for name in arch-update.timer codex-quota-nice.service codex-quota-nice.timer; do
        link_repo_path "config/systemd/user/$name" ".config/systemd/user/$name"
    done
    for name in launcher system networkmenu vpn; do
        link_repo_path "config/rofi/$name.rasi" ".config/rofi/$name.rasi"
    done
    for name in system networkmenu vpnmenu checkupdates; do
        link_repo_path "config/waybar/scripts/$name.sh" ".config/waybar/scripts/$name.sh"
    done
    install_firefox_stylesheet
}

for option in "$@"; do
    case "$option" in
        --check) check_only=1 ;;
        --desktop-only) desktop_only=1 ;;
        *)
            printf 'Usage: %s [--check] [--desktop-only]\n' "$0" >&2
            exit 2
            ;;
    esac
done

if (( desktop_only )); then
    install_desktop
    finish_check
    exit 0
fi

# Directory configurations
link_repo_path vim .vim
# This directory link also installs zsh/my-completions/codex_completion.zsh.
link_repo_path zsh .zsh
install_tmux

# Application configurations
link_repo_path bin/tidal-playlist .local/bin/tidal-playlist
link_repo_path codex/skills/desktop-troubleshooting .codex/skills/desktop-troubleshooting
link_repo_path codex/skills/shell-scripting .codex/skills/shell-scripting
link_repo_path codex/skills/systemd-troubleshooting .codex/skills/systemd-troubleshooting
link_repo_path codex/skills/dotfile-management .codex/skills/dotfile-management
link_repo_path codex/skills/perl-patterns .codex/skills/perl-patterns
link_repo_path codex/skills/purchase-recommendations .codex/skills/purchase-recommendations
link_repo_path codex/skills/skill-shopping .codex/skills/skill-shopping
link_repo_path codex/skills/java-development .codex/skills/java-development
link_repo_path codex/skills/ak .codex/skills/ak
link_repo_path i3/config .config/i3/config
link_repo_path config/doublecmd .config/doublecmd
link_repo_path config/nvim .config/nvim
link_repo_path config/ranger/rc.conf .config/ranger/rc.conf
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
    'fzf/completion.zsh:.fzf/completion.zsh'
    'fzf/key-bindings.zsh:.fzf/key-bindings.zsh'
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
finish_check
