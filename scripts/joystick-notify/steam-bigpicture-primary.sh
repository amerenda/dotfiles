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
HIDE_CURSOR_TIMEOUT="${HIDE_CURSOR_TIMEOUT:-1}"  # seconds-ish; effect uses a small discrete set

enable_kwin_hidecursor_effect_best_effort() {
  [ "$HIDE_CURSOR" != "0" ] || return 0

  command -v kwriteconfig6 >/dev/null 2>&1 || return 0
  command -v qdbus6 >/dev/null 2>&1 || return 0

  # Enable the effect (Plasma 6.1+).
  kwriteconfig6 --file kwinrc --group Plugins --key hidecursorEnabled true >/dev/null 2>&1 || true

  # Configure it (best-effort): many installs default to "never hide on inactivity".
  # Unfortunately KWin's exact group naming can vary; write the common variants.
  for grp in "Effect-hidecursor" "Effect-HideCursor" "HideCursor" "HideCursorEffect"; do
    kwriteconfig6 --file kwinrc --group "$grp" --key HideOnTyping true >/dev/null 2>&1 || true
    kwriteconfig6 --file kwinrc --group "$grp" --key InactivityDuration "$HIDE_CURSOR_TIMEOUT" >/dev/null 2>&1 || true
  done

  # Try to load/reconfigure the effect immediately via DBus.
  qdbus6 org.kde.KWin /Effects org.kde.kwin.Effects.loadEffect hidecursor >/dev/null 2>&1 || true
  qdbus6 org.kde.KWin /Effects org.kde.kwin.Effects.reconfigureEffect hidecursor >/dev/null 2>&1 || true
  qdbus6 org.kde.KWin /KWin org.kde.KWin.reconfigure >/dev/null 2>&1 || true

  log "cursor: ensured hidecursor effect enabled (timeout=${HIDE_CURSOR_TIMEOUT}s, hide_on_typing=true)"
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

# We intentionally avoid wmctrl/focus here. This script's job is only:
# - ensure Steam is running
# - request Big Picture mode (legacy URI is the most compatible)
open_bigpicture_best_effort() {
  # Keep the known-good behavior, but add a few extra attempts that often work when
  # Steam is already running but ignores the URI.
  #
  # NOTE: Steam's exit codes are not always meaningful, so we treat this as best-effort
  # and rely on retries in the caller.
  local ok=1

  steam -ifrunning "steam://open/bigpicture" >>"$LOG" 2>&1 && { log "steam: open_bigpicture via -ifrunning ok"; ok=0; } || log "steam: -ifrunning bigpicture failed"
  steam -ifrunning "steam://open/gamepadui" >>"$LOG" 2>&1 && { log "steam: open_gamepadui via -ifrunning ok"; ok=0; } || log "steam: -ifrunning gamepadui failed"

  # These flags can force a mode switch for some Steam builds.
  steam -bigpicture >>"$LOG" 2>&1 && { log "steam: invoked 'steam -bigpicture' ok"; ok=0; } || log "steam: 'steam -bigpicture' failed"
  steam -tenfoot >>"$LOG" 2>&1 && { log "steam: invoked 'steam -tenfoot' ok"; ok=0; } || log "steam: 'steam -tenfoot' failed"

  steam "steam://open/bigpicture" >>"$LOG" 2>&1 && { log "steam: open_bigpicture direct ok"; ok=0; } || log "steam: open_bigpicture direct failed"
  steam "steam://open/gamepadui" >>"$LOG" 2>&1 && { log "steam: open_gamepadui direct ok"; ok=0; } || log "steam: open_gamepadui direct failed"

  return "$ok"
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
  fi

  # Always request Big Picture. When Steam starts cold, it can ignore early requests;
  # keep retrying for a bit until it accepts them.
  (
    for i in {1..160}; do
      if [ $((i % 10)) -eq 1 ]; then
        log "steam: retry loop attempt=$i present=$(steam_present && echo yes || echo no) ipc=$(steam_ipc_ready && echo yes || echo no)"
      fi

      # Wait until Steam is at least present; prefer waiting for IPC readiness too.
      if ! steam_present; then
        sleep 0.25
        continue
      fi

      # Once present, send the request; if IPC is ready it's more likely to stick.
      if steam_ipc_ready || [ "$i" -gt 20 ]; then
        if open_bigpicture_best_effort; then
          log "steam: bigpicture request succeeded (attempt=$i)"
          # Don't break immediately: Steam can ignore early requests even if the wrapper exits 0.
          # Keep nudging a little longer to ensure it actually switches.
          for j in {1..8}; do
            sleep 0.25
            open_bigpicture_best_effort || true
          done
          break
        fi
      fi
      sleep 0.25
    done
    log_steam_processes
  ) >>"$LOG" 2>&1 &

  # Re-assert a moment later (non-blocking).
  ( sleep 1; set_default_sink_best_effort ) >>"$LOG" 2>&1 &

  log "----- end (async tasks scheduled) -----"
}

main "$@"
