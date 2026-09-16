#!/bin/bash

STATE_FILE="$HOME/.config/hypr/saved_session.txt"

if [ ! -f "$STATE_FILE" ]; then
    echo "No saved session found at $STATE_FILE"
    exit 1
fi

while IFS=":" read -r workspace command; do
    if [ -n "$workspace" ] && [ -n "$command" ]; then
        echo "Launching $command on workspace $workspace...\n"

        # Switch focus to target workspace
        hyprctl dispatch workspace "$workspace"

        # Launch the application in the background
        $command &

        sleep 0.5
    fi
done < "$STATE_FILE"

echo "Session restoration complete."
