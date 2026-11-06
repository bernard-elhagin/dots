#!/usr/bin/env bash
set -euo pipefail

pgrep -x rofi >/dev/null || exit 0

cursor="$(hyprctl cursorpos -j 2>/dev/null | jq -r '[.x, .y] | @tsv')"
rects="$(hyprctl layers -j 2>/dev/null | jq -r '
  .. | objects
  | select(.namespace? == "rofi")
  | select(.x? and .y? and (.w? or .width?) and (.h? or .height?) and .pid?)
  | [.pid, .x, .y, (.w // .width), (.h // .height)] | @tsv
')"

[[ -n "$rects" && -n "$cursor" ]] || exit 0
read -r cursor_x cursor_y <<<"$cursor"

pids=()
while IFS=$'\t' read -r pid x y width height; do
  [[ -n "${pid:-}" ]] || continue
  pids+=("$pid")
  if (( cursor_x >= x && cursor_x < x + width && cursor_y >= y && cursor_y < y + height )); then
    exit 0
  fi
done <<<"$rects"

# Ignore the click that opened the menu, which can race with its first render.
hz="$(getconf CLK_TCK)"
now_ticks="$(awk -v hz="$hz" '{print int($1 * hz)}' /proc/uptime)"
for pid in "${pids[@]}"; do
  [[ -r "/proc/$pid/stat" ]] || continue
  start_ticks="$(awk '{print $22}' "/proc/$pid/stat")"
  age_ms=$(( (now_ticks - start_ticks) * 1000 / hz ))
  (( age_ms >= 250 )) || exit 0
done

for pid in "${pids[@]}"; do
  kill -TERM "$pid" 2>/dev/null || true
done
