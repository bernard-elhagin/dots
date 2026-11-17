#!/usr/bin/env bash

set -euo pipefail

DOTS_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

declare -a CORE_PACKAGES=(
    'gvim'
    'neovim'
    'python-pynvim'
    'perl'
    'curl'
    'git'
    'fzf'
    'fasd'
    'git-delta'
    'ranger'
    'ripgrep'
    'xsel'
    'wl-clipboard'
    'fd'
    'tree'
    'unzip'
    'zoxide'
    'tmux'
    'zsh'
    'bat'
    'translate-shell'
    'btop'
    'starship'
    'tmuxp'
)

declare -a DESKTOP_PACKAGES=(
    'i3-wm'
    'hyprland'
    'quickshell'
    'rofi'
    'hyprpaper'
    'xdg-desktop-portal-hyprland'
    'xdg-desktop-portal-gtk'

    # Taskbar status, tray applet, network menus and Bluetooth controls.
    'networkmanager'
    'network-manager-applet'
    'bluez'
    'bluez-utils'
    'blueman'
    'upower'
    'jq'
    'libnotify'
    'brightnessctl'
    'pacman-contrib'

    # PipeWire audio controls and media-player shortcuts.
    'pipewire'
    'pipewire-pulse'
    'wireplumber'
    'pavucontrol'
    'playerctl'

    # Applications launched by Hyprland and the taskbar.
    'xfce4-terminal'
    'firefox'
    'yazi'
    'dolphin'
    'ttf-jetbrains-mono-nerd'

    # Also required when selecting desktop without the core profile.
    'neovim'
    'perl'
    'python'
    'fzf'
    'wl-clipboard'
    'doublecmd-qt6'
    'gparted'

    # Active startup commands, notifications, lighting and update controls.
    'flameshot'
    'mako'
    'sound-theme-freedesktop'
    'openrgb'
    'cachy-update'
    'yay'
    'base-devel'
    'git'
    'thunderbird'
    'discord'
    'cliphist'
    'hyprland-guiutils'
)

# Development dependencies also support the Neovim language-server bootstrap.
declare -a DEVELOPMENT_PACKAGES=(
    'base-devel' 'jdk25-openjdk' 'nodejs' 'npm' 'pnpm' 'ctags'
    'neovim' 'python-pynvim' 'perl' 'git' 'curl' 'unzip'
    'openai-codex' 'arduino-cli' 'arduino-language-server' 'gdb' 'shellcheck'
)
declare -a GAMING_PACKAGES=('steam')
declare -a MEDIA_PACKAGES=('haruna' 'mpv' 'ffmpeg' 'yt-dlp' 'python-numpy')
declare -a DESKTOP_AUR_PACKAGES=('bibata-cursor-theme-bin')
declare -a MEDIA_AUR_PACKAGES=('tidal-hifi-bin')

usage() {
    printf 'Usage: %s [--list] [all|core|desktop|development|gaming|media ...]\n' "$0"
    printf 'Default: all. Profiles can be combined. --list only prints package names.\n'
    printf 'Targets configured Arch/CachyOS repositories; desktop needs CachyOS packages.\n'
}

declare -a PACKAGES_TO_INSTALL=() AUR_PACKAGES=() profiles=()

list_only=false
setup_core=false
setup_development=false

for argument in "$@"; do
    case "$argument" in
        --list) list_only=true ;;
        -h|--help) usage; exit 0 ;;
        all|core|desktop|development|gaming|media) profiles+=("$argument") ;;
        *) usage >&2; exit 2 ;;
    esac
done

if (( ${#profiles[@]} == 0 )); then
    profiles=(all)
fi

for profile in "${profiles[@]}"; do
    case "$profile" in
        all)
            PACKAGES_TO_INSTALL+=("${CORE_PACKAGES[@]}" "${DESKTOP_PACKAGES[@]}"
                "${DEVELOPMENT_PACKAGES[@]}" "${GAMING_PACKAGES[@]}" "${MEDIA_PACKAGES[@]}")
            AUR_PACKAGES+=("${DESKTOP_AUR_PACKAGES[@]}" "${MEDIA_AUR_PACKAGES[@]}")
            setup_core=true
            setup_development=true
            ;;
        core) PACKAGES_TO_INSTALL+=("${CORE_PACKAGES[@]}"); setup_core=true ;;
        desktop)
            PACKAGES_TO_INSTALL+=("${DESKTOP_PACKAGES[@]}")
            AUR_PACKAGES+=("${DESKTOP_AUR_PACKAGES[@]}")
            ;;
        development) PACKAGES_TO_INSTALL+=("${DEVELOPMENT_PACKAGES[@]}"); setup_development=true ;;
        gaming) PACKAGES_TO_INSTALL+=("${GAMING_PACKAGES[@]}") ;;
        media)
            PACKAGES_TO_INSTALL+=("${MEDIA_PACKAGES[@]}" git base-devel yay)
            AUR_PACKAGES+=("${MEDIA_AUR_PACKAGES[@]}")
            ;;
    esac
done

# The all profile shares a few utilities with desktop; request each only once.
declare -A seen_packages=()
declare -a unique_packages=()

for package in "${PACKAGES_TO_INSTALL[@]}"; do
    if [[ -z "${seen_packages[$package]:-}" ]]; then
        unique_packages+=("$package")
        seen_packages[$package]=1
    fi
done

PACKAGES_TO_INSTALL=("${unique_packages[@]}")

# Prefer configured repositories for these packages if they become available there.
declare -A seen_aur=()
declare -a unique_aur=()
for package in "${AUR_PACKAGES[@]}"; do
    if [[ -z "${seen_aur[$package]:-}" ]]; then
        unique_aur+=("$package")
        seen_aur[$package]=1
    fi
done

AUR_PACKAGES=("${unique_aur[@]}")

if "$list_only"; then
    printf 'Repository packages:\n'
    printf '  %s\n' "${PACKAGES_TO_INSTALL[@]}"
    if (( ${#AUR_PACKAGES[@]} )); then
        printf 'Repository-preferred / AUR fallback:\n'
        printf '  %s\n' "${AUR_PACKAGES[@]}"
    fi
    exit 0
fi

if ! command -v pacman >/dev/null 2>&1; then
    printf 'Error: pacman was not found; this installer is for Arch Linux.\n' >&2
    exit 1
fi

if (( EUID == 0 )); then
    PACMAN=(pacman)
else
    if ! command -v sudo >/dev/null 2>&1; then
        printf 'Error: sudo is required to install packages.\n' >&2
        exit 1
    fi
    PACMAN=(sudo pacman)
fi

# Validate names against configured databases before making system changes.
missing=()
for package in "${PACKAGES_TO_INSTALL[@]}"; do
    if ! pacman -Si "$package" >/dev/null 2>&1; then
        missing+=("$package")
    fi
done

if (( ${#missing[@]} )); then
    printf 'Missing from configured package databases:\n' >&2
    printf '  %s\n' "${missing[@]}" >&2
    printf 'Check repository configuration/database freshness before retrying. Steam requires multilib.\n' >&2
    exit 1
fi

remaining_aur=()

for package in "${AUR_PACKAGES[@]}"; do
    if pacman -Si "$package" >/dev/null 2>&1; then
        PACKAGES_TO_INSTALL+=("$package")
    else
        remaining_aur+=("$package")
    fi
done

AUR_PACKAGES=("${remaining_aur[@]}")

if (( EUID == 0 && ${#AUR_PACKAGES[@]} > 0 )); then
    printf 'Run this script as your regular user: AUR builds must not run as root.\n' >&2
    exit 1
fi

printf 'Installing profiles: %s. Review each transaction before confirming.\n' "${profiles[*]}"

"${PACMAN[@]}" -Syu --needed "${PACKAGES_TO_INSTALL[@]}"
if (( ${#AUR_PACKAGES[@]} )); then
    if ! command -v yay >/dev/null 2>&1; then
        printf 'yay is required for AUR packages; install/configure it before retrying.\n' >&2
        exit 1
    fi
    yay -S --needed "${AUR_PACKAGES[@]}"
fi

if "$setup_core"; then
    PREZTO_DIR="${ZDOTDIR:-$HOME}/.zprezto"
    if [[ -d "$PREZTO_DIR/.git" ]]; then
        printf 'Prezto already installed at %s; skipping.\n' "$PREZTO_DIR"
    elif [[ -e "$PREZTO_DIR" || -L "$PREZTO_DIR" ]]; then
        printf 'Prezto destination exists and is not a Git checkout; skipping: %s\n' "$PREZTO_DIR" >&2
    else
        git clone --recursive https://github.com/sorin-ionescu/prezto.git "$PREZTO_DIR"
    fi

    TPM_DIR="$HOME/.tmux/plugins/tpm"
    if [[ -d "$TPM_DIR/.git" ]]; then
        printf 'TPM already installed at %s; skipping.\n' "$TPM_DIR"
    elif [[ -e "$TPM_DIR" || -L "$TPM_DIR" ]]; then
        printf 'TPM destination exists and is not a Git checkout; skipping: %s\n' "$TPM_DIR" >&2
    else
        mkdir -p -- "$(dirname -- "$TPM_DIR")"
        git clone https://github.com/tmux-plugins/tpm "$TPM_DIR"
    fi

fi

if "$setup_development"; then
    bash "$DOTS_DIR/bin/install_nvim_servers.sh"
fi
