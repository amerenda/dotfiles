#!/usr/bin/env bash
set -euo pipefail

# ===================== CONFIG =====================
# Set to "true" to skip real actions (only log + notify).
# You can also override via systemd: Environment=DEBUG_MODE=true
DEBUG_MODE="${DEBUG_MODE:-false}"
# ==================================================

# Wayland/KDE session env
export XDG_SESSION_TYPE=wayland
export DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$(id -u)/bus"
export WAYLAND_DISPLAY="${WAYLAND_DISPLAY:-wayland-0}"

LOG=/tmp/joystick-events.log
LOCK=/tmp/joystick-owner.lock
LAUNCHER="/usr/local/bin/steam-bigpicture-primary.sh"
WATCHLOG=/tmp/joystick-watcher.log

# --- logging helpers ---
ts()  { date -Is; }
log() { ( umask 0; [ -e "$WATCHLOG" ] || { : >"$WATCHLOG"; chmod 666 "$WATCHLOG"; }; printf '%s %s\n' "$(ts)" "$*" >> "$WATCHLOG" ); }
note(){ notify-send "$@"; }

# ---------- Audio (prefer pactl stable sink names) ----------
HEADSET_SINK="alsa_output.usb-SteelSeries_Arctis_Nova_7X-00.iec958-stereo"

# TV sink auto-detection (stable across extra2/extra3 churn)
# Your TV is ALSA card=2 device=9 (S90D). Override via env if needed.
TV_ALSA_CARD="${TV_ALSA_CARD:-2}"
TV_ALSA_DEVICE="${TV_ALSA_DEVICE:-9}"

resolve_sink_by_alsa() {
  local want_card="${1:-}"
  local want_dev="${2:-}"
  local fallback="${3:-}"
  command -v pactl >/dev/null 2>&1 || { echo -n "$fallback"; return 0; }

  # Parse: match sinks by alsa.card + alsa.device, return sink Name.
  local found
  found="$(
    pactl list sinks 2>/dev/null | awk -v want_card="$want_card" -v want_dev="$want_dev" '
      $1=="Sink" && $2 ~ /^#/ { name=""; card=""; dev=""; next }
      $1=="Name:" { name=$2; next }
      $1=="alsa.card" && $2=="=" { gsub(/"/,"",$3); card=$3; next }
      $1=="alsa.device" && $2=="=" { gsub(/"/,"",$3); dev=$3; next }
      name!="" && card==want_card && dev==want_dev { print name; exit 0 }
    '
  )"

  if [ -n "${found:-}" ]; then
    echo -n "$found"
  else
    echo -n "$fallback"
  fi
}

tv_sink_name() {
  # Prefer env override TV_SINK if provided; otherwise resolve from ALSA mapping.
  if [ -n "${TV_SINK:-}" ]; then
    echo -n "$TV_SINK"
  else
    resolve_sink_by_alsa "$TV_ALSA_CARD" "$TV_ALSA_DEVICE" ""
  fi
}

set_default_sink() {
  local sink="${1:-}"
  command -v pactl >/dev/null 2>&1 || return 0
  [ -n "$sink" ] || return 0
  pactl set-default-sink "$sink" >/dev/null 2>&1 || true
  log "audio: default -> $sink"
}

# ---------- Display + Audio wrappers ----------
make_desk_primary() {
  log "begin: make_desk_primary"
  if $DEBUG_MODE; then
    note "🧪 DEBUG" "make_desk_primary (HDMI-A-1 primary; audio -> Headset)"
  else
    # Enable A-1 first, then disable A-2 to avoid 'no outputs'
    set_default_sink "$HEADSET_SINK"
    kscreen-doctor \
      output.HDMI-A-1.enable \
      output.HDMI-A-1.mode.2560x1440@144 \
      output.HDMI-A-1.position.0,0 \
      output.HDMI-A-2.disable 2>/dev/null || true
  fi
  log "end: make_desk_primary"
}

make_tv_primary() {
  log "begin: make_tv_primary"
  if $DEBUG_MODE; then
    note "🧪 DEBUG" "make_tv_primary (HDMI-A-2 primary; audio -> TV)"
  else
    # Enable A-2 first, then disable A-1
    set_default_sink "$(tv_sink_name)"
    kscreen-doctor \
      output.HDMI-A-2.enable \
      output.HDMI-A-2.mode.3840x2160@60 \
      output.HDMI-A-2.position.2560,0 \
      output.HDMI-A-1.disable 2>/dev/null || true
  fi
  log "end: make_tv_primary"
}

# ---------- lock helpers ----------
lock_owner() { [ -f "$LOCK" ] && cat "$LOCK" || true; }
norm_id() { tr 'A-F' 'a-f' <<<"${1:-}"; }
acquire_lock() {
  local dev
  dev="$(norm_id "${1:-}")"
  ( umask 0; set -o noclobber; echo -n "$dev" > "$LOCK" ) 2>/dev/null || { log "lock: already owned by $(lock_owner)"; return 1; }
  chmod 666 "$LOCK" || true
  log "lock: acquired by $dev"
}
release_lock_if_owner() {
  local dev
  dev="$(norm_id "${1:-}")"
  if [ "$(lock_owner)" = "$dev" ]; then rm -f "$LOCK"; log "lock: released by $dev"; else log "lock: release skipped (owner=$(lock_owner), dev=$dev)"; fi
}

# ---------- HID presence helpers ----------
# We key devices by HID_UNIQ (Bluetooth MAC) to avoid churn in /dev/input/eventN.
hid_uniq_present() {
  local mac
  mac="$(norm_id "${1:-}")"
  [ -n "$mac" ] || return 1
  local f
  for f in /sys/bus/hid/devices/*/uevent; do
    [ -e "$f" ] || continue
    if grep -qi "^HID_UNIQ=${mac}$" "$f" 2>/dev/null; then
      return 0
    fi
  done
  return 1
}

any_controller_present() {
  local f name uniq
  for f in /sys/bus/hid/devices/*/uevent; do
    [ -e "$f" ] || continue
    name="$(grep -m1 '^HID_NAME=' "$f" 2>/dev/null | cut -d= -f2- || true)"
    uniq="$(grep -m1 '^HID_UNIQ=' "$f" 2>/dev/null | cut -d= -f2- || true)"
    [[ "$name" == *Controller* ]] || continue
    [[ "$uniq" == *:* ]] || continue
    return 0
  done
  return 1
}

# If lock exists but owner is gone (stale), clear it
if [ -f "$LOCK" ]; then
  owner="$(lock_owner)"
  if [ -n "$owner" ] && ! hid_uniq_present "$owner"; then
    log "lock: stale ($owner) -> clearing"
    rm -f "$LOCK"
  fi
fi

# ---------- helpers ----------
launcher_exists() { [ -x "$LAUNCHER" ]; }

# Wait until events file exists (systemd-tmpfiles or udev creates it)
while [ ! -e "$LOG" ]; do log "waiting for $LOG to appear..."; sleep 0.5; done
log "watcher started, tailing $LOG"

# Start at EOF; only new lines trigger
stdbuf -oL -eL tail -F -n 0 "$LOG" | while IFS= read -r line; do
  ACT="$(awk '{print $2}' <<<"$line" 2>/dev/null || echo)"
  DEV="$(norm_id "$(awk '{print $3}' <<<"$line" 2>/dev/null || echo)")"
  [ -n "${ACT:-}" ] && [ -n "${DEV:-}" ] || continue
  log "event: $ACT $DEV"

  case "$ACT" in
    add)
      if acquire_lock "$DEV"; then
        make_tv_primary
        if $DEBUG_MODE; then
          log "DEBUG: would launch Steam Big Picture"
          note "🧪 DEBUG" "Would launch Steam Big Picture"
        else
          sleep 1
          if launcher_exists; then
            log "action: launch steam big picture ($LAUNCHER)"
            "$LAUNCHER" >/dev/null 2>&1 &
          else
            log "warn: launcher missing/not executable: $LAUNCHER"
          fi
        fi
        note "🎮 Controller Connected" "$DEV (owner)"
      else
        log "info: add ignored (owner=$(lock_owner))"
      fi
      ;;
    remove)
      # Teardown if the *owner* disconnected OR there are no controllers left at all.
      if [ "$(lock_owner)" = "$DEV" ] || ! any_controller_present; then
        log "teardown: triggered by ${DEV:-none} (owner=$(lock_owner))"
        make_desk_primary
        rm -f "$LOCK" || true
        note "🛑 Controller Disconnected" "${DEV:-all gone} (teardown)"
      else
        log "info: remove ignored (non-owner; owner=$(lock_owner))"
      fi
      ;;
  esac
done
