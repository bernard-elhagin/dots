#!/usr/bin/env bash

set -euo pipefail

DOTS_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

declare -a CORE_PACKAGES=(
    'gvim'
    'neovim'
    'python-pynvim'
    'perl'
    'jdk25-openjdk'
    'nodejs'
    'npm'
    'pnpm'
    'curl'
    'ctags'
    'git'
    'fzf'
    'fasd'
    'git-delta'
    'ranger'
    'make'
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
    'steam'
    'ttf-jetbrains-mono-nerd'
    # Also required when selecting desktop without the core profile.
    'neovim'
    'perl'
    'python'
    'fzf'
    'wl-clipboard'
    'doublecmd-qt6'
    'gparted'
    'haruna'
)

usage() {
    printf 'Usage: %s [all|core|desktop]\n' "$0"
}

if (( $# > 1 )); then
    usage >&2
    exit 2
fi

declare -a PACKAGES_TO_INSTALL

case "${1:-all}" in
    all)
        PACKAGES_TO_INSTALL=("${CORE_PACKAGES[@]}" "${DESKTOP_PACKAGES[@]}")
        ;;
    core)
        PACKAGES_TO_INSTALL=("${CORE_PACKAGES[@]}")
        ;;
    desktop)
        PACKAGES_TO_INSTALL=("${DESKTOP_PACKAGES[@]}")
        ;;
    -h|--help)
        usage
        exit 0
        ;;
    *)
        usage >&2
        exit 2
        ;;
esac

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

printf "Installing %s package(s) in the %s profile. Review pacman's transaction before confirming.\n" \
    "${#PACKAGES_TO_INSTALL[@]}" "${1:-all}"
"${PACMAN[@]}" -Syu --needed "${PACKAGES_TO_INSTALL[@]}"

if [[ "${1:-all}" != desktop ]]; then
    if ! command -v git >/dev/null 2>&1; then
        printf 'Error: git is required to clone Prezto and TPM.\n' >&2
        exit 1
    fi

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

    bash "$DOTS_DIR/bin/install_nvim_servers.sh"
fi
