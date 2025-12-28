#!/usr/bin/env bash

# Ensure script is run as root for system backup
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root (use sudo)" 
   exit 1
fi

# Determine locations based on script path
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
# SCRIPT_DIR is .../dotfiles/scripts, so DOTFILES_PATH is .../dotfiles
DOTFILES_PATH="$(dirname "$SCRIPT_DIR")"

export INCLUDE_FILE="${DOTFILES_PATH}/scripts/backup/meta/include.txt"
export EXCLUDE_FILE="${DOTFILES_PATH}/scripts/backup/meta/exclude.txt"

export GOOGLE_APPLICATION_CREDENTIALS=/etc/backup-keys/backup-amerenda.json

if [ -f /etc/backup-keys/restic_password.txt ]; then
    export RESTIC_PASSWORD=$(cat /etc/backup-keys/restic_password.txt)
else
    echo "Error: /etc/backup-keys/restic_password.txt not found."
    exit 1
fi

export RESTIC_REPO="gs:amerenda-backups:/archlinux"

echo "Using include file: ${INCLUDE_FILE}"
echo "Using exclude file: ${EXCLUDE_FILE}"
echo "Repository: ${RESTIC_REPO}"

if restic snapshots -r "${RESTIC_REPO}" &>/dev/null; then
    echo "Starting backup..."
    restic backup -r "${RESTIC_REPO}" --files-from "${INCLUDE_FILE}" --exclude-file "${EXCLUDE_FILE}" --verbose
else
    echo "Restic repository is not initialized or accessible. Initializing now..."
    restic -r "${RESTIC_REPO}" init
    if [ $? -eq 0 ]; then
        echo "Initialization successful. Starting backup..."
        restic backup -r "${RESTIC_REPO}" --files-from "${INCLUDE_FILE}" --exclude-file "${EXCLUDE_FILE}" --verbose
    else
        echo "Failed to initialize repository."
        exit 1
    fi
fi

unset GOOGLE_APPLICATION_CREDENTIALS
unset RESTIC_PASSWORD
unset RESTIC_REPO
