#!/usr/bin/env bash
# steam-bigpicture-primary.sh
set -euo pipefail

# ---- Logging ----
LOG=/tmp/steam-bp.log
LOCK=/tmp/steam-bp.lock
ts() { date -Is; }
_ensure_log() {
  if [ ! -e "$LOG" ]; then
    : >"$LOG"
    chmod 666 "$LOG" 2>/dev/null || true
  fi
}
log() {
  _ensure_log
  {
    flock -n 9 || true
    printf '%s %s\n' "$(ts)" "$*" >>"$LOG"
  } 9>"$LOCK"
}

bin_path() {
  local b="${1:-}"
  command -v "$b" 2>/dev/null || echo "__missing__"
}

# ---- Environment (Wayland / KDE Plasma) ----
export XDG_SESSION_TYPE=wayland
export WAYLAND_DISPLAY="${WAYLAND_DISPLAY:-wayland-0}"
export DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$(id -u)/bus"
export SDL_VIDEODRIVER=wayland
export QT_QPA_PLATFORM=wayland
export STEAM_USE_WAYLAND=1

# ---- Audio (PipeWire/Pulse via pactl) ----
# Steam sometimes switches audio devices when (re)starting or entering Big Picture.
# Re-assert the desired default sink around launch to keep output on the TV.
TV_ALSA_CARD="${TV_ALSA_CARD:-2}"
TV_ALSA_DEVICE="${TV_ALSA_DEVICE:-9}"

resolve_sink_by_alsa() {
  local want_card="${1:-}"
  local want_dev="${2:-}"
  local fallback="${3:-}"
  command -v pactl >/dev/null 2>&1 || { echo -n "$fallback"; return 0; }

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
  if [ -n "${TV_SINK:-}" ]; then
    echo -n "$TV_SINK"
  else
    resolve_sink_by_alsa "$TV_ALSA_CARD" "$TV_ALSA_DEVICE" ""
  fi
}

set_default_sink_best_effort() {
  command -v pactl >/dev/null 2>&1 || return 0
  local sink
  sink="$(tv_sink_name)"
  [ -n "$sink" ] || return 0
  if pactl set-default-sink "$sink" >>"$LOG" 2>&1; then
    log "audio: set-default-sink ok ($sink)"
  else
    log "audio: set-default-sink FAILED ($sink)"
  fi
}

# ---- Cursor hiding (KDE Plasma / KWin) ----
# Plasma 6.1+ includes a "Hide Cursor" desktop effect that hides the pointer after inactivity.
# Under Wayland there is no general-purpose "unclutter" equivalent, so the most reliable approach
# is enabling that KWin effect.
#
# Set HIDE_CURSOR=0 to disable this behavior.
HIDE_CURSOR="${HIDE_CURSOR:-1}"

enable_kwin_hidecursor_effect_best_effort() {
  [ "$HIDE_CURSOR" != "0" ] || return 0

  command -v kwriteconfig6 >/dev/null 2>&1 || return 0
  command -v qdbus6 >/dev/null 2>&1 || return 0

  # Enable the effect in kwinrc if the plugin key exists (Plasma 6.1+).
  # KWin will ignore unknown keys, so this is safe across versions.
  kwriteconfig6 --file kwinrc --group Plugins --key hidecursorEnabled true >/dev/null 2>&1 || true

  # Ask KWin to reload config.
  qdbus6 org.kde.KWin /KWin org.kde.KWin.reconfigure >/dev/null 2>&1 || true
}

# ---- Helpers ----
steam_pid_list() { pgrep -x steam 2>/dev/null | tr '\n' ',' || true; }

steam_process_present() {
  # Only trust real processes. Window heuristics can be stale/false-positive.
  pgrep -x steam >/dev/null 2>&1 && return 0
  pgrep -x steamwebhelper >/dev/null 2>&1 && return 0
  pgrep -x steamservice >/dev/null 2>&1 && return 0
  return 1
}

steam_present() { steam_process_present; }

steam_ipc_ready() {
  # Steam typically creates a local IPC socket/pipe once the client is ready.
  # Paths vary; check common ones.
  [ -S "$HOME/.steam/steam/steam.pipe" ] && return 0
  [ -S "$HOME/.steam/steam.pipe" ] && return 0
  [ -S "${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/steam.pipe" ] && return 0
  return 1
}

log_steam_processes() {
  # Best-effort snapshot for debugging.
  ( ps -C steam,steamwebhelper,steamservice -o pid=,comm=,args= 2>/dev/null || true ) | sed 's/^/ps: /' >>"$LOG" 2>&1 || true
}

# Start Steam (prefer Gamepad UI when supported).
start_steam_best_effort() {
  if ! command -v steam >/dev/null 2>&1; then
    log "error: steam not found in PATH"
    return 0
  fi

  log "steam: starting (pid before=$(steam_pid_list))"

  if steam -h 2>&1 | grep -q -- '-gamepadui'; then
    log "steam: launching 'steam -gamepadui'"
    steam -gamepadui >>"$LOG" 2>&1 &
  else
    log "steam: launching 'steam' (no -gamepadui support detected)"
    steam >>"$LOG" 2>&1 &
  fi
}

# Try to bring the Steam window to the foreground.
# On Plasma Wayland, Steam typically runs under XWayland; focus tools like wmctrl/xdotool can work.
# This is best-effort (no failure if tools aren't installed or focus is denied by policy).
focus_steam_best_effort() {
  local i

  if command -v wmctrl >/dev/null 2>&1; then
    # Try common WM_CLASS values for Steam.
    for i in {1..30}; do
      wmctrl -xa steam >>"$LOG" 2>&1 && { log "focus: wmctrl -xa steam ok"; return 0; }
      wmctrl -xa Steam >>"$LOG" 2>&1 && { log "focus: wmctrl -xa Steam ok"; return 0; }
      wmctrl -a "Steam" >>"$LOG" 2>&1 && { log "focus: wmctrl -a Steam ok"; return 0; }
      sleep 0.1
    done
  fi

  if command -v xdotool >/dev/null 2>&1; then
    # XWayland-only fallback.
    for i in {1..30}; do
      xdotool search --onlyvisible --class steam windowactivate >>"$LOG" 2>&1 && { log "focus: xdotool class=steam ok"; return 0; }
      xdotool search --onlyvisible --class Steam windowactivate >>"$LOG" 2>&1 && { log "focus: xdotool class=Steam ok"; return 0; }
      sleep 0.1
    done
  fi

  log "focus: no focus method succeeded (wmctrl/xdotool missing or denied)"
  return 0
}

STEAM_UI_URI="${STEAM_UI_URI:-steam://open/bigpicture}"

request_ui() {
  # Do not use -ifrunning; it is not a reliable signal across environments.
  # Repeatedly requesting the URI after Steam starts is the most robust approach.
  if steam "$STEAM_UI_URI" >>"$LOG" 2>&1; then
    log "steam: requested ui via $STEAM_UI_URI"
    return 0
  fi
  log "steam: request ui FAILED via $STEAM_UI_URI"
  return 1
}

# ---- Main ----
main() {
  log "----- start -----"
  log "env: XDG_SESSION_TYPE=$XDG_SESSION_TYPE WAYLAND_DISPLAY=$WAYLAND_DISPLAY DBUS_SESSION_BUS_ADDRESS=$DBUS_SESSION_BUS_ADDRESS"
  log "env: TV_ALSA_CARD=$TV_ALSA_CARD TV_ALSA_DEVICE=$TV_ALSA_DEVICE TV_SINK=${TV_SINK:-auto}"
  log "bin: steam=$(bin_path steam) pactl=$(bin_path pactl) wmctrl=$(bin_path wmctrl) xdotool=$(bin_path xdotool)"
  log "steam: pid before=$(steam_pid_list)"
  log "steam: present before=$(steam_present && echo yes || echo no)"
  log "steam: ipc ready before=$(steam_ipc_ready && echo yes || echo no)"
  log_steam_processes

  enable_kwin_hidecursor_effect_best_effort

  # Apply immediately, then again shortly after launch to override device restore races.
  set_default_sink_best_effort

  # If Steam isn't running, start it.
  if ! steam_present; then
    log "steam: not present -> starting"
    start_steam_best_effort
  else
    log "steam: present -> requesting UI switch"
  fi

  # Retry requesting UI for a while; Steam can take time to become ready to handle URIs.
  # IMPORTANT: do NOT stop retrying just because steam_present becomes true — the first URI
  # request might happen before Steam is ready and get ignored.
  (
    ok_count=0
    for i in {1..160}; do
      if [ $((i % 10)) -eq 1 ]; then
        log "steam: retry loop attempt=$i present=$(steam_present && echo yes || echo no) ipc=$(steam_ipc_ready && echo yes || echo no)"
      fi

      # Wait until Steam is at least present; prefer waiting for IPC readiness too.
      if ! steam_present; then
        sleep 0.25
        continue
      fi

      # Once present, start hammering the URI; if IPC is ready it's more likely to stick.
      if steam_ipc_ready || [ "$i" -gt 20 ]; then
        if request_ui; then
          ok_count=$((ok_count + 1))
          log "steam: ui request ok_count=$ok_count (attempt=$i)"
          ( sleep 0.4; focus_steam_best_effort ) >>"$LOG" 2>&1 &
          # Require two successful requests to reduce races during initial startup.
          if [ "$ok_count" -ge 2 ]; then
            break
          fi
        fi
      fi
      sleep 0.25
    done
    log_steam_processes
  ) >>"$LOG" 2>&1 &

  # Re-assert a moment later (non-blocking).
  ( sleep 1; set_default_sink_best_effort ) >>"$LOG" 2>&1 &

  # And try to bring Steam to the front after it has had time to respond to the URI.
  ( sleep 0.4; focus_steam_best_effort ) >>"$LOG" 2>&1 &

  log "----- end (async tasks scheduled) -----"
}

main "$@"
