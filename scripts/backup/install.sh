#!/usr/bin/env bash
set -euo pipefail

if [[ ${EUID:-$(id -u)} -ne 0 ]]; then
  echo "This script must be run as root (use sudo)" >&2
  exit 1
fi

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

SERVICE_SRC="$ROOT/meta/backup.service"
TIMER_SRC="$ROOT/meta/backup.timer"
SCRIPT_SRC="$ROOT/backup.sh"

SERVICE_DST="/etc/systemd/system/backup.service"
TIMER_DST="/etc/systemd/system/backup.timer"
SCRIPT_DST="/usr/local/sbin/backup.sh"

echo "[backup] Installing systemd units..."
install -Dm0644 "$SERVICE_SRC" "$SERVICE_DST"
install -Dm0644 "$TIMER_SRC" "$TIMER_DST"

echo "[backup] Installing backup script..."
install -Dm0755 "$SCRIPT_SRC" "$SCRIPT_DST"

echo "[backup] Reloading systemd daemon..."
systemctl daemon-reload

echo "[backup] Installed."
echo "[backup] To enable the timer:"
echo "  systemctl enable --now backup.timer"


