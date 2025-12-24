#!/usr/bin/env bash
# steam-bigpicture-primary.sh
set -euo pipefail

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
  pactl set-default-sink "$sink" >/dev/null 2>&1 || true
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
is_steam_running() {
  pgrep -x steam >/dev/null 2>&1 || pgrep -f '/steam' >/dev/null 2>&1
}

# Try to bring the Steam window to the foreground.
# On Plasma Wayland, Steam typically runs under XWayland; focus tools like wmctrl/xdotool can work.
# This is best-effort (no failure if tools aren't installed or focus is denied by policy).
focus_steam_best_effort() {
  local i

  if command -v wmctrl >/dev/null 2>&1; then
    # Try common WM_CLASS values for Steam.
    for i in {1..30}; do
      wmctrl -xa steam >/dev/null 2>&1 && return 0
      wmctrl -xa Steam >/dev/null 2>&1 && return 0
      wmctrl -a "Steam" >/dev/null 2>&1 && return 0
      sleep 0.1
    done
  fi

  if command -v xdotool >/dev/null 2>&1; then
    # XWayland-only fallback.
    for i in {1..30}; do
      xdotool search --onlyvisible --class steam windowactivate >/dev/null 2>&1 && return 0
      xdotool search --onlyvisible --class Steam windowactivate >/dev/null 2>&1 && return 0
      sleep 0.1
    done
  fi

  return 0
}

# Always prefer steam:// so an existing client can be reused
open_bigpicture() {
  # -ifrunning avoids spawning a second instance
  steam -ifrunning "steam://open/bigpicture" >/dev/null 2>&1 || \
  steam "steam://open/bigpicture" >/dev/null 2>&1
}

# ---- Main ----
main() {
  enable_kwin_hidecursor_effect_best_effort

  # Apply immediately, then again shortly after launch to override device restore races.
  set_default_sink_best_effort

  if is_steam_running; then
    # Steam already running → just switch it into Big Picture
    open_bigpicture
  else
    # Steam not running → start directly into Big Picture
    steam -gamepadui >/dev/null 2>&1 &
  fi

  # Re-assert a moment later (non-blocking).
  ( sleep 1; set_default_sink_best_effort ) >/dev/null 2>&1 &

  # And try to bring Steam to the front after it has had time to respond to the URI.
  ( sleep 0.4; focus_steam_best_effort ) >/dev/null 2>&1 &
}

main "$@"
