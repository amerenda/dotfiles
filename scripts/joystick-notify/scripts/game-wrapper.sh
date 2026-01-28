#!/usr/bin/env bash
# game-wrapper.sh
# Usage in Steam: game-wrapper.sh %command%
# No set -e; we want to handle failures gracefully.

TV_OUTPUT="${TV_OUTPUT:-HDMI-A-1}"
LOG="/tmp/game-wrapper.log"
WRAPPER_DEBUG="${WRAPPER_DEBUG:-false}"

# Configuration for resolution
OUT_W="${OUT_W:-3840}"
OUT_H="${OUT_H:-2160}"
GAME_W="${GAME_W:-$OUT_W}"
GAME_H="${GAME_H:-$OUT_H}"

log_msg() {
    [ "$WRAPPER_DEBUG" = "true" ] || return 0
    echo "$(date -Is) [game-wrapper] $*" >> "$LOG"
}

# Ensure log exists if debug is enabled
if [ "$WRAPPER_DEBUG" = "true" ]; then
    : > "$LOG"
    chmod 666 "$LOG" || true
fi

# Check if the TV output is enabled via kscreen-doctor (KDE Plasma)
# We capture the output in debug mode to help troubleshoot "sometimes works"
KSCREEN_OUT=$(kscreen-doctor -o 2>/dev/null || true)
log_msg "Captured kscreen-doctor output."

if grep -A 10 "$TV_OUTPUT" <<<"$KSCREEN_OUT" | grep -q "enabled: true"; then
    log_msg "TV active ($TV_OUTPUT), launching with gamescope..."
    log_msg "Arguments: $*"
    
    # AMD Optimized Flags:
    # ...
    
    if [ "$WRAPPER_DEBUG" = "true" ]; then
        exec gamescope \
            -W "$OUT_W" -H "$OUT_H" \
            -w "$GAME_W" -h "$GAME_H" \
            -f -r 60 \
            -e \
            --adaptive-sync \
            --rt \
            --force-grab-cursor \
            --borderless \
            --expose-wayland \
            -- "$@" 2>> "$LOG"
    else
        exec gamescope \
            -W "$OUT_W" -H "$OUT_H" \
            -w "$GAME_W" -h "$GAME_H" \
            -f -r 60 \
            -e \
            --adaptive-sync \
            --rt \
            --force-grab-cursor \
            --borderless \
            --expose-wayland \
            -- "$@"
    fi
else
    log_msg "TV not active or output detection failed, launching game normally."
    exec "$@"
fi
