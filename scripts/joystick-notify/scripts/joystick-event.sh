#!/usr/bin/env bash
set -euo pipefail

LOG=/tmp/joystick-events.log
LOCK=/tmp/joystick-events.lock   # flock file

# udev normally sets ACTION, but we also override it in the udev rule to map bind/unbind -> add/remove.
ACT="${ACTION:-add}"

# We treat the arg as an opaque device identifier (typically HID_UNIQ / Bluetooth MAC).
DEV="${1:-unknown}"

# Ensure events log exists and is writable
if [ ! -e "$LOG" ]; then
  : >"$LOG"
  chown root:root "$LOG" || true
  chmod 666 "$LOG" || true
fi

# Append-only write with lock
{
  flock -n 9 || exit 0
  printf '%s %s %s\n' "$(date -Is)" "$ACT" "$DEV" >> "$LOG"
} 9>"$LOCK"



