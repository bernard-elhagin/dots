#!/usr/bin/env bash
set -euo pipefail

choice="$(printf '%s\n' 'Shut down' 'Restart' 'Sleep' \
  | rofi -dmenu -i -no-custom -hover-select -p 'Power' \
      -theme "$HOME/.config/rofi/launcher.rasi" \
      -theme-str '* { font: "JetBrains Mono 11"; text-color: #FFB000; } window { location: northwest; anchor: northwest; width: 260px; background-color: #11100D; border-color: #6E4A00; } mainbox { padding: 8px; spacing: 6px; } inputbar { padding: 6px 8px; } listview { columns: 1; lines: 3; fixed-columns: false; layout: vertical; spacing: 4px; } element { orientation: horizontal; children: [ element-text ]; text-color: #FFB000; padding: 6px; } element selected { background-color: #FFB000; text-color: #11100D; } element-text { text-color: #FFB000; } element-text selected { text-color: #11100D; } prompt { text-color: #FFB000; }')"

case "$choice" in
  'Shut down') systemctl poweroff ;;
  'Restart') systemctl reboot ;;
  'Sleep') systemctl suspend ;;
  *) exit 0 ;;
esac
