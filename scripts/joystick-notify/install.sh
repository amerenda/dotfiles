#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

usage() {
  cat <<'EOF'
Usage: install.sh [--no-enable]

Installs:
- scripts to /usr/local/bin
- udev rule to /etc/udev/rules.d
- systemd user unit to ~/.config/systemd/user

Options:
  --no-enable   Do not enable/start the systemd user service
EOF
}

ENABLE=1
for arg in "$@"; do
  case "$arg" in
    --no-enable) ENABLE=0 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown arg: $arg" >&2; usage >&2; exit 2 ;;
  esac
done

need_cmd() { command -v "$1" >/dev/null 2>&1 || { echo "Missing command: $1" >&2; exit 1; }; }
need_cmd install
need_cmd systemctl
need_cmd sudo

if [ "${EUID:-$(id -u)}" -eq 0 ]; then
  echo "[joystick-notify] Do not run this installer with sudo (it needs your user session bus for systemctl --user)." >&2
  echo "Run as your user instead:" >&2
  echo "  $ROOT/$(basename "$0") $*" >&2
  exit 2
fi

# Prompt for sudo once up front (interactive).
sudo -v

echo "[joystick-notify] Installing scripts to /usr/local/bin ..."
sudo install -Dm0755 "$ROOT/monitor-switcher.sh" /usr/local/bin/monitor-switcher.sh
sudo install -Dm0755 "$ROOT/joystick-event.sh" /usr/local/bin/joystick-event.sh
sudo install -Dm0755 "$ROOT/steam-bigpicture-primary.sh" /usr/local/bin/steam-bigpicture-primary.sh

echo "[joystick-notify] Installing udev rules ..."
sudo install -Dm0644 "$ROOT/udev/99-joystick-notify.rules" /etc/udev/rules.d/99-joystick-notify.rules
sudo udevadm control --reload-rules

echo "[joystick-notify] Installing systemd user unit ..."
install -Dm0644 "$ROOT/systemd/joystick-notify.service" "$HOME/.config/systemd/user/joystick-notify.service"

# Ensure user bus vars exist (some terminals / sudo contexts can be missing them).
uid="$(id -u)"
export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$uid}"
export DBUS_SESSION_BUS_ADDRESS="${DBUS_SESSION_BUS_ADDRESS:-unix:path=${XDG_RUNTIME_DIR}/bus}"

systemctl --user daemon-reload

if [ "$ENABLE" -eq 1 ]; then
  echo "[joystick-notify] Enabling + starting systemd user service ..."
  systemctl --user enable --now joystick-notify.service
  echo "[joystick-notify] Restarting systemd user service to pick up updates ..."
  systemctl --user restart joystick-notify.service
else
  if systemctl --user is-active --quiet joystick-notify.service; then
    echo "[joystick-notify] Service is running; restarting to pick up updates ..."
    systemctl --user restart joystick-notify.service
  fi
  echo "[joystick-notify] Installed. To enable later:"
  echo "  systemctl --user enable --now joystick-notify.service"
fi

echo "[joystick-notify] Done."


