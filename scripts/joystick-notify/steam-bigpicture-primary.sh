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

# ---- Helpers ----
is_steam_running() {
  pgrep -x steam >/dev/null 2>&1 || pgrep -f '/steam' >/dev/null 2>&1
}

# Always prefer steam:// so an existing client can be reused
open_bigpicture() {
  # -ifrunning avoids spawning a second instance
  steam -ifrunning "steam://open/bigpicture" >/dev/null 2>&1 || \
  steam "steam://open/bigpicture" >/dev/null 2>&1
}

# ---- Main ----
main() {
  if is_steam_running; then
    # Steam already running → just switch it into Big Picture
    open_bigpicture &
  else
    # Steam not running → start directly into Big Picture
    steam -gamepadui &
  fi
}

main "$@"
