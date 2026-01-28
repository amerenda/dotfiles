#!/usr/bin/env bash
# force-desk-primary.sh
# Enforces the desk monitor as primary AND DISABLES the TV if couch-mode is not active.
set -euo pipefail

LOCK="/tmp/joystick-owner.lock"
DESK_OUTPUT="${DESK_OUTPUT:-HDMI-A-2}"
TV_OUTPUT="${TV_OUTPUT:-HDMI-A-1}"

# Check if couch-mode is active
if [ -f "$LOCK" ]; then
    # Couch mode is active, do nothing.
    exit 0
fi

# Ensure correct runtime directory (usually /run/user/1000)
export XDG_RUNTIME_DIR="/run/user/$(id -u)"
export DBUS_SESSION_BUS_ADDRESS="unix:path=${XDG_RUNTIME_DIR}/bus"

# Enforce desk monitor as primary (priority 1) and DISABLE the TV
kscreen-doctor \
    "output.${DESK_OUTPUT}.enable" \
    "output.${DESK_OUTPUT}.priority.1" \
    "output.${DESK_OUTPUT}.mode.2560x1440@144" \
    "output.${DESK_OUTPUT}.position.0,0" \
    "output.${TV_OUTPUT}.disable" 2>/dev/null || true

echo "[force-desk-primary] Desk monitor enforced; TV disabled." >&2
