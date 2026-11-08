#!/usr/bin/env bash

# Pacman updates
repo=$(checkupdates 2>/dev/null | wc -l)

# AUR updates
if command -v yay >/dev/null 2>&1; then
    aur=$(yay -Qua 2>/dev/null | wc -l)
else
    aur=0
fi

# Flatpak updates
if command -v flatpak >/dev/null 2>&1; then
    flatpak_updates=$(flatpak remote-ls --updates 2>/dev/null | wc -l)
else
    flatpak_updates=0
fi

total=$((repo + aur))

if [ "$total" -lt 45 ]; then
    echo ""
    exit
fi

class="medium"

if [ "$total" -ge 120 ]; then
    class="high"
fi

echo "{\"text\":\"󰚰\",\"tooltip\":\"Pacman: $repo\nAUR: $aur\nFlatpak: $flatpak_updates\",\"class\":\"$class\"}"
