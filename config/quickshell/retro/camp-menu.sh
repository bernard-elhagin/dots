#!/usr/bin/env bash
set -euo pipefail

choice="$(printf '%s\n' 'Start Pomodoro' 'Pause / resume Pomodoro' 'Play / pause music' 'Next track' 'Previous track' \
    | rofi -dmenu -i -no-custom -p 'Camp' \
        -theme "$HOME/.config/rofi/launcher.rasi" \
        -theme-str 'window { width: 350px; background-color: #111827; border-color: #E7D39B; } listview { columns: 1; lines: 5; } element selected { background-color: #293655; text-color: #D8D6EE; }')" || exit 0

pomodoro="$HOME/.local/bin/pomodoro"
case "$choice" in
    'Start Pomodoro') xfce4-terminal --title=Pomodoro -x "$pomodoro" ;;
    'Pause / resume Pomodoro') "$pomodoro" --toggle ;;
    'Play / pause music') playerctl play-pause ;;
    'Next track') playerctl next ;;
    'Previous track') playerctl previous ;;
esac
