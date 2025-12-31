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
LAUNCHER="/usr/local/bin/launch-bigpicture.sh"
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

resolve_sink_by_description() {
  local want_desc="${1:-}"
  [ -n "$want_desc" ] || return 1
  command -v pactl >/dev/null 2>&1 || return 1

  pactl list sinks 2>/dev/null | awk -v want="$want_desc" '
    $1=="Sink" && $2 ~ /^#/ { name=""; desc=""; next }
    $1=="Name:" { name=$2; next }
    $1=="Description:" { desc=$2; for (i=3;i<=NF;i++) desc=desc " " $i; next }
    name!="" && desc==want { print name; exit 0 }
  ' | head -n 1
}

resolve_tv_sink_with_wait() {
  # The HDMI sink can appear a moment after enabling the output / hotplug.
  # Wait a bit and retry resolution.
  local sink i
  for i in {1..40}; do
    sink="$(tv_sink_name)"
    if [ -n "${sink:-}" ]; then
      echo -n "$sink"
      return 0
    fi

    # Fallback: if your PipeWire description is literally "TV" (as shown earlier), use it.
    sink="$(resolve_sink_by_description "TV" || true)"
    if [ -n "${sink:-}" ]; then
      echo -n "$sink"
      return 0
    fi

    sleep 0.25
  done
  return 1
}

set_default_sink() {
  local sink="${1:-}"
  command -v pactl >/dev/null 2>&1 || return 0
  [ -n "$sink" ] || return 0
  pactl set-default-sink "$sink" >/dev/null 2>&1 || true
  log "audio: default -> $sink"
}

move_all_sink_inputs_to() {
  local sink="${1:-}"
  command -v pactl >/dev/null 2>&1 || return 0
  [ -n "$sink" ] || return 0

  # Move any currently-playing streams to the target sink. This fixes the common case where
  # changing the default sink doesn't affect already-running apps (e.g. Steam).
  local ids moved=0 id
  ids="$(pactl list short sink-inputs 2>/dev/null | awk '{print $1}' || true)"
  for id in $ids; do
    pactl move-sink-input "$id" "$sink" >/dev/null 2>&1 && moved=$((moved + 1)) || true
  done
  log "audio: moved ${moved} sink-input(s) -> $sink"
}

set_audio_to_sink() {
  local sink="${1:-}"
  set_default_sink "$sink"
  move_all_sink_inputs_to "$sink"
}

# ---------- Display + Audio wrappers ----------
make_desk_primary() {
  log "begin: make_desk_primary"
  if $DEBUG_MODE; then
    note "🧪 DEBUG" "make_desk_primary (HDMI-A-1 primary; audio -> Headset)"
  else
    # Enable A-1 first, then disable A-2 to avoid 'no outputs'
    set_audio_to_sink "$HEADSET_SINK"
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
    # Enable A-2 first, then disable A-1 (helps ensure the HDMI audio device exists).
    kscreen-doctor \
      output.HDMI-A-2.enable \
      output.HDMI-A-2.mode.3840x2160@60 \
      output.HDMI-A-2.position.2560,0 \
      output.HDMI-A-1.disable 2>/dev/null || true

    # Now that the output is enabled, resolve the TV sink and switch audio (default + move streams).
    if tv_sink="$(resolve_tv_sink_with_wait)"; then
      log "audio: resolved tv sink -> $tv_sink"
      set_audio_to_sink "$tv_sink"
    else
      log "audio: warn: could not resolve TV sink after waiting (TV_ALSA_CARD=$TV_ALSA_CARD TV_ALSA_DEVICE=$TV_ALSA_DEVICE)"
    fi
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

usb_vidpid_present() {
  # Check for presence of a USB device by vendor/product hex ids (lowercase).
  local vid="${1:-}"
  local pid="${2:-}"
  [ -n "$vid" ] && [ -n "$pid" ] || return 1
  local d
  for d in /sys/bus/usb/devices/*; do
    [ -e "$d/idVendor" ] || continue
    [ -e "$d/idProduct" ] || continue
    if [ "$(tr 'A-F' 'a-f' <"$d/idVendor" 2>/dev/null)" = "$vid" ] && \
       [ "$(tr 'A-F' 'a-f' <"$d/idProduct" 2>/dev/null)" = "$pid" ]; then
      return 0
    fi
  done
  return 1
}

id_present() {
  # Supported IDs:
  # - Bluetooth HID_UNIQ MAC: aa:bb:cc:dd:ee:ff
  # - USB VID/PID: usb:2dc8:3106
  # - USB joydev: js0
  # - USB evdev: event26
  local id
  id="$(norm_id "${1:-}")"
  [ -n "$id" ] || return 1

  if [[ "$id" == event* ]]; then
    [ -e "/dev/input/$id" ]
    return $?
  fi

  if [[ "$id" == js* ]]; then
    [ -e "/dev/input/$id" ]
    return $?
  fi

  if [[ "$id" == usb:*:* ]]; then
    local vid pid
    vid="$(cut -d: -f2 <<<"$id" 2>/dev/null || true)"
    pid="$(cut -d: -f3 <<<"$id" 2>/dev/null || true)"
    usb_vidpid_present "$vid" "$pid"
    return $?
  fi

  # Default: treat as MAC HID_UNIQ
  hid_uniq_present "$id"
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

  # Also consider any USB joystick devices present (legacy joydev nodes).
  compgen -G "/dev/input/js*" >/dev/null && return 0

  # And USB evdev joystick-only devices (like the 8BitDo dongle which has event* but no js*).
  local ev
  for ev in /dev/input/event*; do
    [ -e "$ev" ] || continue
    if udevadm info --query=property --name="$ev" 2>/dev/null | grep -q '^ID_INPUT_JOYSTICK=1$'; then
      return 0
    fi
  done

  return 1
}

# If lock exists but owner is gone (stale), clear it
if [ -f "$LOCK" ]; then
  owner="$(lock_owner)"
  if [ -n "$owner" ] && ! id_present "$owner"; then
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

            # Steam/PipeWire can race and restore streams back to the old device;
            # re-assert the TV sink after launch and move streams again.
            (
              sleep 2
              tv_sink="$(tv_sink_name)"
              [ -n "${tv_sink:-}" ] || exit 0
              set_audio_to_sink "$tv_sink"
            ) >/dev/null 2>&1 &
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


