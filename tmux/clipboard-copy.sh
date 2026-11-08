#!/usr/bin/env bash
set -euo pipefail

# Prefer the native clipboard for the current display session.
if [[ -n "${WAYLAND_DISPLAY:-}" ]] && command -v wl-copy >/dev/null 2>&1; then
    exec wl-copy
elif [[ -n "${DISPLAY:-}" ]] && command -v xsel >/dev/null 2>&1; then
    exec xsel -i -b
elif [[ -n "${DISPLAY:-}" ]] && command -v xclip >/dev/null 2>&1; then
    exec xclip -i -selection clipboard
elif command -v pbcopy >/dev/null 2>&1; then
    exec pbcopy
elif command -v clip.exe >/dev/null 2>&1; then
    exec clip.exe
elif [[ -c /dev/clipboard ]]; then
    cat > /dev/clipboard
else
    # tmux still retains the copied text in its paste buffer.
    cat > /dev/null
fi
