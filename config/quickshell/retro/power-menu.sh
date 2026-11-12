#!/usr/bin/env bash
set -euo pipefail

choice="$(printf '%s\n' 'Shut down' 'Restart' 'Sleep' \
  | rofi -dmenu -i -no-custom -hover-select -p 'Power' \
      -theme "$HOME/.config/rofi/launcher.rasi" \
      -theme-str '* { font: "JetBrains Mono 11"; text-color: #E9C46A; } window { location: northwest; anchor: northwest; width: 260px; background-color: #101D21; border-color: #36565C; } mainbox { padding: 8px; spacing: 6px; } inputbar { padding: 6px 8px; } listview { columns: 1; lines: 3; fixed-columns: false; layout: vertical; spacing: 4px; } element { orientation: horizontal; children: [ element-text ]; text-color: #E9C46A; padding: 6px; } element selected { background-color: #E9C46A; text-color: #101D21; } element-text { text-color: #E9C46A; } element-text selected { text-color: #101D21; } prompt { text-color: #E9C46A; }')"

case "$choice" in
  'Shut down') systemctl poweroff ;;
  'Restart') systemctl reboot ;;
  'Sleep') systemctl suspend ;;
  *) exit 0 ;;
esac
