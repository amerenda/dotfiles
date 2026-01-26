#!/usr/bin/env bash
# game-wrapper.sh
# Usage in Steam: game-wrapper.sh %command%
set -euo pipefail

TV_OUTPUT="${TV_OUTPUT:-HDMI-A-1}"

# Check if the TV output is enabled via kscreen-doctor (KDE Plasma)
# We look for the output name and check if it's enabled.
if kscreen-doctor -o 2>/dev/null | grep -A 10 "$TV_OUTPUT" | grep -q "enabled: true"; then
    # TV is active. 
    # Use gamescope with:
    # -f: fullscreen
    # -r 60: cap at 60Hz (matching the TV)
    # --expose-wayland: allow wayland apps to run
    # --: separator for the command to run
    echo "[game-wrapper] TV active ($TV_OUTPUT), launching with gamescope..." >&2
    exec gamescope -f -r 60 --expose-wayland --steam -- "$@"
else
    # TV not active (desktop mode or output disabled)
    exec "$@"
fi
