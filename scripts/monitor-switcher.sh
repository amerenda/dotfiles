#!/usr/bin/env bash
set -euo pipefail

# ===================== CONFIG =====================
DEBUG_MODE=false    # true = no real actions, only log + notify
# ==================================================

# Wayland/KDE session env
export XDG_SESSION_TYPE=wayland
export DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$(id -u)/bus"
export WAYLAND_DISPLAY="${WAYLAND_DISPLAY:-wayland-0}"

# --- single-instance guard (user service safe) ---
RUNDIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
LOCK_RUN="$RUNDIR/monitor-switcher.instance.lock"
exec 9> "$LOCK_RUN"
if ! flock -n 9; then
  echo "monitor-switcher: already running (lock: $LOCK_RUN)" >&2
  exit 0
fi

LOG=/tmp/joystick-events.log          # produced by your other process
LOCK=/tmp/joystick-owner.lock
LAUNCHER="/usr/local/bin/steam-bigpicture-primary.sh"
WATCHLOG=/tmp/joystick-watcher.log

# ---------- deps ----------
need_cmds=(kscreen-doctor jq pactl tail flock kwriteconfig6)
QDBUS_BIN="${QDBUS_BIN:-$(command -v qdbus || command -v qdbus6 || command -v qdbus-qt5 || true)}"
for c in "${need_cmds[@]}"; do command -v "$c" >/dev/null || { echo "missing: $c" >&2; exit 1; }; done
[ -n "${QDBUS_BIN:-}" ] || { echo "missing: qdbus (qt5/qt6)"; exit 1; }

# --- logging helpers ---
ts()  { date -Is; }
log() { ( umask 0; [ -e "$WATCHLOG" ] || { : >"$WATCHLOG"; chmod 666 "$WATCHLOG"; }; printf '%s %s\n' "$(ts)" "$*" >> "$WATCHLOG" ); }
note(){ notify-send "$@"; }

# ---------- Audio (prefer pactl stable sink names) ----------
HEADSET_SINK="alsa_output.usb-SteelSeries_Arctis_Nova_7X-00.iec958-stereo"
TV_SINK="alsa_output.pci-0000_03_00.1.hdmi-stereo-extra3"

resolve_sink() {
  # exact match first
  if pactl list short sinks | awk '{print $2}' | grep -Fxq "$1"; then
    echo "$1"; return 0
  fi
  # pattern fallbacks (tweak as needed)
  case "$1" in
    *hdmi-stereo*)    pactl list short sinks | awk '$2 ~ /hdmi-stereo/ {print $2}'    | tail -1; return 0;;
    *iec958-stereo*)  pactl list short sinks | awk '$2 ~ /iec958-stereo/ {print $2}'  | head -1; return 0;;
  esac
  return 1
}

set_default_sink() {
  local want="$1" sink
  sink="$(resolve_sink "$want" || true)"
  if [ -n "${sink:-}" ]; then
    pactl set-default-sink "$sink" && log "audio: default -> $sink" || log "audio: set-default failed for $sink"
  else
    log "audio: could not resolve sink for pattern '$want'"
  fi
}

# ---------- Display + Audio wrappers ----------
mouse_bottom_right() {
  local pad="${1:-6}"
  local geo x y
  geo="$(kscreen-doctor -j)"
  x="$(jq -r '[.[] | select(.enabled==true) | (.pos.x + .mode.size.width  - 1)] | max' <<<"$geo")"
  y="$(jq -r '[.[] | select(.enabled==true) | (.pos.y + .mode.size.height - 1)] | max' <<<"$geo")"
  x=$((x - pad)); y=$((y - pad))

  if [[ "${XDG_SESSION_TYPE:-}" == "wayland" ]]; then
    local js f s
    js='workspace.cursorPos = Qt.point('"$x,$y"');'
    f="$(mktemp --suffix=.js)"
    printf '%s\n' "$js" > "$f"
    if ! s="$("$QDBUS_BIN" org.kde.KWin /Scripting org.kde.kwin.Scripting.loadScript "$f" 2>/dev/null)"; then
      log "kwin scripting unavailable"; rm -f "$f"; return 1
    fi
    "$QDBUS_BIN" org.kde.KWin "/Scripting/Script${s}" org.kde.kwin.Script.run  >/dev/null 2>&1 || true
    "$QDBUS_BIN" org.kde.KWin "/Scripting/Script${s}" org.kde.kwin.Script.stop >/dev/null 2>&1 || true
    rm -f "$f"
  else
    command -v xdotool >/dev/null || { log "xdotool required for X11 fallback"; return 1; }
    xdotool mousemove "$x" "$y"
  fi
}

hide_cursor_on() {
  # Native KWin desktop effect: "Hide Cursor"
  kwriteconfig6 --file kwinrc --group Plugins --key hidecursorEnabled true
  "$QDBUS_BIN" org.kde.KWin /KWin reconfigure >/dev/null 2>&1 || true
  log "cursor: hidecursor effect enabled"
}

hide_cursor_off() {
  kwriteconfig6 --file kwinrc --group Plugins --key hidecursorEnabled false
  "$QDBUS_BIN" org.kde.KWin /KWin reconfigure >/dev/null 2>&1 || true
  log "cursor: hidecursor effect disabled"
}

make_desk_primary() {
  log "begin: make_desk_primary"
  if $DEBUG_MODE; then
    note "🧪 DEBUG" "make_desk_primary (HDMI-A-1 primary; audio -> Headset)"
    set_default_sink "$HEADSET_SINK"
  else
    hide_cursor_off || true
    # Enable A-1 first, then disable A-2 to avoid 'no outputs'
    kscreen-doctor \
      output.HDMI-A-1.enable \
      output.HDMI-A-1.mode.2560x1440@144 \
      output.HDMI-A-1.position.0,0 \
      output.HDMI-A-2.disable 2>/dev/null || true
    mouse_bottom_right || true
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
    hide_cursor_on || true
    kscreen-doctor \
      output.HDMI-A-2.enable \
      output.HDMI-A-2.mode.3840x2160@60 \
      output.HDMI-A-2.position.2560,0 \
      output.HDMI-A-1.disable 2>/dev/null || true
    sleep 0.5
    set_default_sink "$TV_SINK"
  fi
  log "end: make_tv_primary"
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

cleanup() {
  # if owner is still present, tear down nicely
  if [ -n "$(lock_owner)" ]; then
    make_desk_primary || true
    rm -f "$LOCK" || true
  fi
  log "exiting"
}
trap cleanup EXIT INT TERM

# If lock exists but device is gone (stale), clear it
if [ -f "$LOCK" ] && [ ! -e "/dev/input/$(cat "$LOCK")" ]; then log "lock: stale ($(cat "$LOCK")) -> clearing"; rm -f "$LOCK"; fi

# ---------- helpers ----------
any_js_present() { compgen -G "/dev/input/js*" >/dev/null; }

# Wait until events file exists (systemd-tmpfiles or udev creates it)
while [ ! -e "$LOG" ]; do log "waiting for $LOG to appear..."; sleep 0.5; done
log "watcher started, tailing $LOG"

# Start at EOF; only new lines trigger. --pid ties tail to our PID.
while read -r ts act dev _; do
  case "${act:-}" in
    add)
      log "event: add ${dev:-?}"
      if acquire_lock "${dev:-?}"; then
        make_tv_primary
        if $DEBUG_MODE; then
          log "DEBUG: would launch Steam Big Picture"
          note "🧪 DEBUG" "Would launch Steam Big Picture"
        else
          sleep 1
          log "action: launch steam big picture"
          "$LAUNCHER" >/dev/null 2>&1 &
        fi
        note "🎮 Controller Connected" "${dev:-?} (owner)"
      else
        log "info: add ignored (owner=$(lock_owner))"
      fi
      ;;
    remove)
      log "event: remove ${dev:-?}"
      if [ "$(lock_owner)" = "${dev:-}" ] || ! any_js_present; then
        log "teardown: triggered by ${dev:-none} (owner=$(lock_owner))"
        make_desk_primary
        rm -f "$LOCK" || true
        note "🛑 Controller Disconnected" "${dev:-all gone} (teardown)"
      else
        log "info: remove ignored (non-owner; owner=$(lock_owner))"
      fi
      ;;
    *) : ;;
  esac
done < <(tail --pid="$$" -F -n0 "$LOG")

