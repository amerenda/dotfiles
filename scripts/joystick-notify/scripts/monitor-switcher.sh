#!/usr/bin/env bash
set -euo pipefail

# ===================== CONFIG =====================
# Set to "true" to skip real actions (only log + notify).
# You can also override via systemd: Environment=DEBUG_MODE=true
DEBUG_MODE="${DEBUG_MODE:-false}"

# Disconnect grace period (seconds) before tearing down couch-mode on controller loss.
# This protects against transient Bluetooth hiccups.
DISCONNECT_GRACE="${DISCONNECT_GRACE:-15}"

# How often (seconds) to poll for Steam exiting while in couch-mode.
STEAM_POLL="${STEAM_POLL:-2}"

# HDMI-CEC (optional): wake TV + switch input when entering couch-mode.
# Requires either `cec-ctl` (preferred; package: v4l-utils on many distros) or `cec-client`
# (package name varies: e.g. libcec).
CEC_ENABLED="${CEC_ENABLED:-true}"
# HDMI port number on the TV that your PC is connected to (1..N). Adjust as needed.
# For your setup: HDMI 3.
CEC_HDMI_PORT="${CEC_HDMI_PORT:-3}"
# Back-compat: older name used in earlier iteration.
CEC_TV_PORT="${CEC_TV_PORT:-$CEC_HDMI_PORT}"
# Optional: explicit adapter device for cec-ctl (e.g. /dev/cec0). Empty = auto.
CEC_ADAPTER="${CEC_ADAPTER:-}"
# If true, send CEC standby (power off) on teardown (best-effort).
CEC_POWER_OFF_ON_TEARDOWN="${CEC_POWER_OFF_ON_TEARDOWN:-true}"

# Virtual desktop isolation (KWin/Plasma). Prefer a desktop named "Couch".
COUCH_DESKTOP_NAME="${COUCH_DESKTOP_NAME:-Couch}"
# Optional numeric override (1..N). If empty, we look up by name or fall back to last desktop.
COUCH_DESKTOP_NUM="${COUCH_DESKTOP_NUM:-}"
# ==================================================

# Wayland/KDE session env
export XDG_SESSION_TYPE=wayland
export DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$(id -u)/bus"
export WAYLAND_DISPLAY="${WAYLAND_DISPLAY:-wayland-0}"

LOG=/tmp/joystick-events.log
EVENTS_LOCK=/tmp/joystick-events.lock
LOCK=/tmp/joystick-owner.lock
LAUNCHER="/usr/local/bin/launch-bigpicture.sh"
WATCHLOG=/tmp/joystick-watcher.log
JOY_EVENT="/usr/local/bin/joystick-event.sh"
DESKTOP_STATE="/tmp/joystick-prev-desktop.$(id -u)"
CEC_STATE="/tmp/joystick-cec-used.$(id -u)"

# --- logging helpers ---
ts()  { date -Is; }
log() { ( umask 0; [ -e "$WATCHLOG" ] || { : >"$WATCHLOG"; chmod 666 "$WATCHLOG"; }; printf '%s %s\n' "$(ts)" "$*" >> "$WATCHLOG" ); }
note(){
  # Notifications are best-effort: never let notify daemon rate limits crash the watcher.
  command -v notify-send >/dev/null 2>&1 || return 0
  # Coalesce repeated notifications when supported by the notification server.
  notify-send -h string:x-canonical-private-synchronous:joystick-notify "$@" >/dev/null 2>&1 || true
}

# ---------- background job helpers ----------
is_pid_alive() { local p="${1:-}"; [ -n "$p" ] && kill -0 "$p" >/dev/null 2>&1; }

PENDING_TIMER_PID=""
STEAM_WATCHER_PID=""

cancel_pending_timer() {
  if is_pid_alive "${PENDING_TIMER_PID:-}"; then
    kill "$PENDING_TIMER_PID" >/dev/null 2>&1 || true
  fi
  PENDING_TIMER_PID=""
}

cancel_steam_watcher() {
  if is_pid_alive "${STEAM_WATCHER_PID:-}"; then
    kill "$STEAM_WATCHER_PID" >/dev/null 2>&1 || true
  fi
  STEAM_WATCHER_PID=""
}

emit_event() {
  # Emit a synthetic event into the same log stream monitor-switcher watches.
  # NOTE: We do NOT rely on joystick-event.sh here because it uses `flock -n` and can
  # silently drop events under contention. For timers/watchers, we want reliable delivery,
  # so we do our own `flock -w` + append.
  local act="${1:-}"
  local dev="${2:-synthetic}"
  [ -n "$act" ] || return 0

  # Ensure events log exists and is writable
  if [ ! -e "$LOG" ]; then
    ( umask 0; : >"$LOG"; chmod 666 "$LOG" ) >/dev/null 2>&1 || true
  fi

  # Append with a short wait on the lock to avoid dropping synthetic events.
  if {
    flock -w 2 9 || exit 1
    printf '%s %s %s\n' "$(date -Is)" "$act" "$dev" >> "$LOG"
  } 9>"$EVENTS_LOCK" 2>/dev/null; then
    return 0
  fi

  # If we can't open/lock the lockfile (e.g. permissions regression), still try to append.
  printf '%s %s %s\n' "$(date -Is)" "$act" "$dev" >> "$LOG" 2>/dev/null || true
}

is_steam_running() {
  pgrep -x steam >/dev/null 2>&1 || pgrep -f '/steam' >/dev/null 2>&1
}

have() { command -v "$1" >/dev/null 2>&1; }

cec_wake_and_select_input_best_effort() {
  # Best-effort HDMI-CEC:
  # - Power on TV
  # - Select the TV input port that the PC is connected to (active source / routing)
  # This is intentionally forgiving: if tools/devices aren't present, it just logs and returns.
  [ "$CEC_ENABLED" = "true" ] || [ "$CEC_ENABLED" = "1" ] || return 0

  # Prefer libcec (cec-client) on systems like yours where the adapter is /dev/ttyACM0
  # and there is no kernel CEC device node (/dev/cec*).
  if have cec-client; then
    # We intentionally do NOT send an explicit `on 0` here.
    # On many TVs, asserting Active Source is enough to power on and switch inputs, and avoids
    # some races where the TV powers on and immediately flips to another device (e.g. Shield).
    # Use -p to advertise the physical HDMI port to the TV.
    local ok=0 attempt
    for attempt in 1 2 3 4 5; do
      if printf 'as\nis\nq\n' | cec-client -s -d 1 -p "$CEC_HDMI_PORT" >/dev/null 2>&1; then
        ok=1
        break
      fi
      sleep 1
    done
    if [ "$ok" -eq 1 ]; then
      log "cec: active-source asserted (cec-client -p $CEC_HDMI_PORT)"
    else
      log "cec: warn: active-source failed (cec-client -p $CEC_HDMI_PORT) — check /dev/ttyACM0 permissions (need uucp group)"
    fi
    ( umask 077; : >"$CEC_STATE" ) 2>/dev/null || true
    return 0
  fi

  # Kernel CEC framework (cec-ctl) is only usable if /dev/cec* exists.
  if have cec-ctl && compgen -G "/dev/cec*" >/dev/null; then
    # Build optional adapter arg.
    local adapter_args=()
    if [ -n "${CEC_ADAPTER:-}" ]; then
      adapter_args+=( -d "$CEC_ADAPTER" )
    fi

    # Power on TV (0 is TV logical address). Ignore errors.
    cec-ctl "${adapter_args[@]}" --to 0 --image-view-on >/dev/null 2>&1 || true
    cec-ctl "${adapter_args[@]}" --to 0 --power-on >/dev/null 2>&1 || true

    # Route to the given port. cec-ctl uses 1-based port numbers with --route-to.
    cec-ctl "${adapter_args[@]}" --route-to "$CEC_TV_PORT" >/dev/null 2>&1 || true
    log "cec: attempted wake + route-to port $CEC_TV_PORT (cec-ctl ${CEC_ADAPTER:-auto})"
    ( umask 077; : >"$CEC_STATE" ) 2>/dev/null || true
    return 0
  fi

  log "cec: skipped (missing cec-ctl/cec-client)"
}

cec_standby_best_effort() {
  [ "$CEC_ENABLED" = "true" ] || [ "$CEC_ENABLED" = "1" ] || return 0
  [ "$CEC_POWER_OFF_ON_TEARDOWN" = "true" ] || [ "$CEC_POWER_OFF_ON_TEARDOWN" = "1" ] || return 0

  # Only power off if we used CEC during this couch-mode session (conservative).
  [ -e "$CEC_STATE" ] || return 0

  if have cec-client; then
    if printf 'standby 0\nq\n' | cec-client -s -d 1 -p "$CEC_HDMI_PORT" >/dev/null 2>&1; then
      log "cec: standby OK (cec-client -p $CEC_HDMI_PORT)"
    else
      log "cec: warn: standby failed (cec-client -p $CEC_HDMI_PORT) — check /dev/ttyACM0 permissions"
    fi
    return 0
  fi

  if have cec-ctl && compgen -G "/dev/cec*" >/dev/null; then
    local adapter_args=()
    if [ -n "${CEC_ADAPTER:-}" ]; then
      adapter_args+=( -d "$CEC_ADAPTER" )
    fi
    cec-ctl "${adapter_args[@]}" --to 0 --standby >/dev/null 2>&1 || true
    log "cec: standby sent (cec-ctl ${CEC_ADAPTER:-auto})"
    return 0
  fi
}

kwin_current_desktop() {
  have qdbus6 || return 1
  qdbus6 org.kde.KWin /KWin org.kde.KWin.currentDesktop 2>/dev/null | head -n 1
}

kwin_set_desktop() {
  local n="${1:-}"
  have qdbus6 || return 1
  [[ "$n" =~ ^[0-9]+$ ]] || return 1
  qdbus6 org.kde.KWin /KWin org.kde.KWin.setCurrentDesktop "$n" >/dev/null 2>&1 || return 1
}

kwin_desktop_count() {
  have kreadconfig6 || return 1
  kreadconfig6 --file kwinrc --group Desktops --key Number 2>/dev/null | head -n 1
}

kwin_desktop_name() {
  local n="${1:-}"
  have kreadconfig6 || return 1
  kreadconfig6 --file kwinrc --group Desktops --key "Name_${n}" 2>/dev/null || true
}

kwin_find_desktop_by_name() {
  local want="${1:-}"
  [ -n "$want" ] || return 1
  local count n name
  count="$(kwin_desktop_count || echo)"
  [[ "${count:-}" =~ ^[0-9]+$ ]] || return 1
  for ((n=1; n<=count; n++)); do
    name="$(kwin_desktop_name "$n" | head -n 1)"
    if [ "${name:-}" = "$want" ]; then
      echo -n "$n"
      return 0
    fi
  done
  return 1
}

save_and_switch_to_couch_desktop_best_effort() {
  local cur target count
  cur="$(kwin_current_desktop || echo)"
  [[ "${cur:-}" =~ ^[0-9]+$ ]] || { log "kwin: skip desktop save/switch (no currentDesktop)"; return 0; }
  ( umask 077; echo -n "$cur" >"$DESKTOP_STATE" ) 2>/dev/null || true

  target=""
  if [[ "${COUCH_DESKTOP_NUM:-}" =~ ^[0-9]+$ ]]; then
    target="$COUCH_DESKTOP_NUM"
  else
    target="$(kwin_find_desktop_by_name "$COUCH_DESKTOP_NAME" || true)"
    if [ -z "${target:-}" ]; then
      count="$(kwin_desktop_count || echo)"
      [[ "${count:-}" =~ ^[0-9]+$ ]] && target="$count" || target=""
    fi
  fi

  if [ -z "${target:-}" ]; then
    log "kwin: warn: could not resolve couch desktop (name=$COUCH_DESKTOP_NAME num=${COUCH_DESKTOP_NUM:-auto})"
    return 0
  fi

  if [ "$target" != "$cur" ]; then
    if kwin_set_desktop "$target"; then
      log "kwin: switched desktop $cur -> $target"
    else
      log "kwin: warn: failed to switch desktop $cur -> $target"
    fi
  else
    log "kwin: couch desktop already active (desktop=$cur)"
  fi
}

restore_previous_desktop_best_effort() {
  local prev
  [ -r "$DESKTOP_STATE" ] || return 0
  prev="$(cat "$DESKTOP_STATE" 2>/dev/null || echo)"
  rm -f "$DESKTOP_STATE" >/dev/null 2>&1 || true
  [[ "${prev:-}" =~ ^[0-9]+$ ]] || return 0
  kwin_set_desktop "$prev" && log "kwin: restored desktop -> $prev" || log "kwin: warn: failed to restore desktop -> $prev"
}

teardown_couch_mode() {
  local why="${1:-}"
  local dev="${2:-}"
  log "teardown: $why ${dev:-}"
  cancel_pending_timer
  # Steam watcher will also exit naturally when the lock disappears, but cancel anyway.
  cancel_steam_watcher
  make_desk_primary
  restore_previous_desktop_best_effort
  cec_standby_best_effort
  rm -f "$CEC_STATE" >/dev/null 2>&1 || true
  rm -f "$LOCK" || true
  note "🛑 Couch-mode Ended" "${why:-ended} ${dev:-}"
}

schedule_disconnect_grace() {
  # Start (or restart) a grace timer. When it fires it emits a grace_timeout event.
  local removed_dev="${1:-}"
  cancel_pending_timer

  (
    sleep "$DISCONNECT_GRACE"
    emit_event "grace_timeout" "${removed_dev:-timeout}"
  ) >/dev/null 2>&1 &
  PENDING_TIMER_PID=$!
  log "grace: scheduled ${DISCONNECT_GRACE}s (pid=$PENDING_TIMER_PID) for ${removed_dev:-unknown}"
}

start_steam_watcher() {
  # Watch Steam while in couch-mode. Only trigger once Steam has been observed running,
  # then later disappears for 2 consecutive polls (avoids startup races).
  if is_pid_alive "${STEAM_WATCHER_PID:-}"; then
    return 0
  fi

  (
    local seen_running=0 misses=0
    while [ -e "$LOCK" ]; do
      if is_steam_running; then
        seen_running=1
        misses=0
      else
        if [ "$seen_running" -eq 1 ]; then
          misses=$((misses + 1))
          if [ "$misses" -ge 2 ]; then
            emit_event "steam_exit" "steam"
            exit 0
          fi
        fi
      fi
      sleep "$STEAM_POLL"
    done
  ) >/dev/null 2>&1 &
  STEAM_WATCHER_PID=$!
  log "steam: watcher started (pid=$STEAM_WATCHER_PID poll=${STEAM_POLL}s)"
}

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
# If we boot into an already-active couch-mode (lock exists), ensure the Steam watcher is running.
[ -e "$LOCK" ] && start_steam_watcher || true

# Use process substitution (not a pipeline) so this loop runs in the current shell.
while IFS= read -r line; do
  ACT="$(awk '{print $2}' <<<"$line" 2>/dev/null || echo)"
  DEV="$(norm_id "$(awk '{print $3}' <<<"$line" 2>/dev/null || echo)")"
  [ -n "${ACT:-}" ] && [ -n "${DEV:-}" ] || continue
  log "event: $ACT $DEV"

  case "$ACT" in
    add)
      cancel_pending_timer
      if acquire_lock "$DEV"; then
        # 1) OPTIONAL isolation: jump to a dedicated couch desktop so your current work isn't shown.
        save_and_switch_to_couch_desktop_best_effort

        # 2/3) Hide cursor + start Steam (launcher keeps running until lock is removed).
        start_steam_watcher
        if $DEBUG_MODE; then
          log "DEBUG: would launch Steam Big Picture"
          note "🧪 DEBUG" "Would launch Steam Big Picture"
        else
          if launcher_exists; then
            log "action: launch steam big picture ($LAUNCHER)"
            "$LAUNCHER" >/dev/null 2>&1 &

            # 4) While Steam starts, wake TV + switch its input to this PC (CEC), in the background.
            ( cec_wake_and_select_input_best_effort ) >/dev/null 2>&1 &

            # 5) Switch output/audio to the TV.
            sleep 0.5
            make_tv_primary

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
      # If we're not in couch-mode, ignore disconnect noise.
      if [ ! -e "$LOCK" ]; then
        log "info: remove ignored (no couch-mode lock)"
        continue
      fi

      # Do not teardown immediately on disconnect; schedule a grace window to ignore BT hiccups.
      # We schedule if the owner disconnected, or if this removal leaves us with no controllers.
      owner_now="$(lock_owner)"
      if [ "$owner_now" = "$DEV" ] || ! any_controller_present; then
        if is_steam_running; then
          log "remove: steam running -> scheduling grace teardown check (dev=$DEV owner=$owner_now)"
          schedule_disconnect_grace "$DEV"
          note "🎮 Controller Disconnected" "$DEV (waiting ${DISCONNECT_GRACE}s)"
        else
          log "remove: steam not running -> immediate teardown (dev=$DEV owner=$owner_now)"
          teardown_couch_mode "controller_disconnect" "$DEV"
        fi
      else
        log "info: remove ignored (non-owner; owner=$owner_now)"
      fi
      ;;
    grace_timeout)
      if [ ! -e "$LOCK" ]; then
        log "grace: timeout ignored (no couch-mode lock)"
        cancel_pending_timer
        continue
      fi

      # If controllers returned during the grace window, do nothing.
      if any_controller_present; then
        log "grace: timeout ignored (controllers present)"
        cancel_pending_timer
        continue
      fi

      owner_now="$(lock_owner)"
      if [ -n "${owner_now:-}" ] && id_present "$owner_now"; then
        log "grace: timeout ignored (owner present: $owner_now)"
        cancel_pending_timer
        continue
      fi

      teardown_couch_mode "grace_timeout" "$DEV"
      ;;
    steam_exit)
      if [ ! -e "$LOCK" ]; then
        log "steam: exit ignored (no couch-mode lock)"
        continue
      fi
      teardown_couch_mode "steam_exit" "$DEV"
      ;;
  esac
done < <(stdbuf -oL -eL tail -F -n 0 "$LOG")



