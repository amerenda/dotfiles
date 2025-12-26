#!/usr/bin/env bash
set -euo pipefail

# ===================== CONFIG =====================
DEBUG_MODE=false    # true = no real actions, only log + notify
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
TV_SINK="alsa_output.pci-0000_03_00.1.hdmi-stereo-extra3"
set_default_sink() { pactl set-default-sink "$1"; log "audio: default -> $1"; }

# ---------- Display + Audio wrappers ----------
make_desk_primary() {
  log "begin: make_desk_primary"
  if $DEBUG_MODE; then
    note "🧪 DEBUG" "make_desk_primary (HDMI-A-1 primary; audio -> Headset)"
    set_default_sink "$HEADSET_SINK"
  else
    # Enable A-1 first, then disable A-2 to avoid 'no outputs'
    kscreen-doctor \
      output.HDMI-A-1.enable \
      output.HDMI-A-1.mode.2560x1440@144 \
      output.HDMI-A-1.position.0,0 \
      output.HDMI-A-2.disable 2>/dev/null
    mouse_bottom_right
    sleep 0.5
    set_default_sink "$HEADSET_SINK"
  fi
  log "end: make_desk_primary"
}

make_tv_primary() {
  log "begin: make_tv_primary"
  if $DEBUG_MODE; then
    note "🧪 DEBUG" "make_tv_primary (HDMI-A-2 primary; audio -> TV)"
    set_default_sink "$TV_SINK"
  else
    # Enable A-2 first, then disable A-1
    kscreen-doctor \
      output.HDMI-A-2.enable \
      output.HDMI-A-2.mode.3840x2160@60 \
      output.HDMI-A-2.position.2560,0 \
      output.HDMI-A-1.disable 2>/dev/null
    sleep 0.5
    set_default_sink "$TV_SINK"
  fi
  log "end: make_tv_primary"
}


# ----------- Mouse Hider ----------
# deps: kscreen-doctor, jq, qdbus (qdbus-qt5), kwin_wayland running
mouse_bottom_right() {
  local pad="${1:-6}"

  # Compute bottom-right of the combined layout via kscreen-doctor JSON
  local geo
  geo="$(kscreen-doctor -j)"
  local x y
  x="$(jq -r '[.[] | select(.enabled==true) | (.pos.x + .mode.size.width - 1)] | max' <<<"$geo")"
  y="$(jq -r '[.[] | select(.enabled==true) | (.pos.y + .mode.size.height - 1)] | max' <<<"$geo")"
  x=$((x - pad)); y=$((y - pad))

  if [[ "${XDG_SESSION_TYPE:-}" == "wayland" ]]; then
    # Wayland/Plasma: set workspace.cursorPos via a one-shot KWin script
    local js f s
    js='workspace.cursorPos = Qt.point('"$x,$y"');'
    f="$(mktemp --suffix=.js)"
    printf '%s\n' "$js" > "$f"
    s="$(qdbus org.kde.KWin /Scripting org.kde.kwin.Scripting.loadScript "$f" 2>/dev/null)" || {
      echo "kwin scripting not available"; rm -f "$f"; return 1; }
    qdbus org.kde.KWin "/Scripting/Script${s}" org.kde.kwin.Script.run >/dev/null 2>&1
    qdbus org.kde.KWin "/Scripting/Script${s}" org.kde.kwin.Script.stop >/dev/null 2>&1
    rm -f "$f"
  else
    # X11 fallback
    command -v xdotool >/dev/null || { echo "xdotool required"; return 1; }
    xdotool mousemove "$x" "$y"
  fi
}



# ---------- lock helpers ----------
lock_owner() { [ -f "$LOCK" ] && cat "$LOCK" || true; }
acquire_lock() {
  local dev="$1"
  ( umask 0; set -o noclobber; echo -n "$dev" > "$LOCK" ) 2>/dev/null || { log "lock: already owned by $(lock_owner)"; return 1; }
  chmod 666 "$LOCK" || true
  log "lock: acquired by $dev"
}
release_lock_if_owner() {
  local dev="$1"
  if [ "$(lock_owner)" = "$dev" ]; then rm -f "$LOCK"; log "lock: released by $dev"; else log "lock: release skipped (owner=$(lock_owner), dev=$dev)"; fi
}

# If lock exists but device is gone (stale), clear it
if [ -f "$LOCK" ] && [ ! -e "/dev/input/$(cat "$LOCK")" ]; then log "lock: stale ($(cat "$LOCK")) -> clearing"; rm -f "$LOCK"; fi

# ---------- helpers ----------
any_js_present() { compgen -G "/dev/input/js*" >/dev/null; }

# Wait until events file exists (systemd-tmpfiles or udev creates it)
while [ ! -e "$LOG" ]; do log "waiting for $LOG to appear..."; sleep 0.5; done
log "watcher started, tailing $LOG"

# Start at EOF; only new lines trigger
stdbuf -oL -eL tail -F -n 0 "$LOG" | while IFS= read -r line; do
  ACT="$(awk '{print $2}' <<<"$line" 2>/dev/null || echo)"
  DEV="$(awk '{print $3}' <<<"$line" 2>/dev/null || echo)"
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
          log "action: launch steam big picture"
          "$LAUNCHER" >/dev/null 2>&1 &
        fi
        note "🎮 Controller Connected" "$DEV (owner)"
      else
        log "info: add ignored (owner=$(lock_owner))"
      fi
      ;;
    remove)
      # Teardown if the *owner* disconnected OR there are no js* left at all.
      if [ "$(lock_owner)" = "$DEV" ] || ! any_js_present; then
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


