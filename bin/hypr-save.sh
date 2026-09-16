#!/bin/bash

STATE_FILE="$HOME/.config/hypr/saved_session.txt"

# clear previous state file
> "$STATE_FILE"

hyprctl -j clients | jq -c '.[]' | while read -r window; do
    WORKSPACE=$(echo "$window" | jq -r '.workspace.id')

    CLASS=$(echo "$window" | jq -r '.initialClass' | tr '[:upper:]' '[:lower:]')

    if [ -n "$CLASS" ] && [ "$CLASS" != "null" ] && [ "$CLASS" != "waybar" ]; then
        echo "$WORKSPACE:$CLASS" >> "$STATE_FILE"
    fi

done

echo "Session saved to $STATE_FILE"
