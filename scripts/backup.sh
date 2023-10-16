#!/usr/bin/env bash
#!/bin/bash

# Calculate seconds until 2 am
SECONDS=$(echo $(date -d '2:00 next day' +%s) - $(date +%s) | bc)

# Wake up laptop at 2 am
sudo rtcwake -m mem -s $SECONDS

export DOTFILES_PATH="${HOME}/projects/dotfiles"
export INCLUDE_FILE="${DOTFILES_PATH}/scripts/meta/backup/include.txt"
export EXCLUDE_FILE="${DOTFILES_PATH}/scripts/meta/backup/exclude.txt"

export GOOGLE_APPLICATION_CREDENTIALS=/etc/backup-keys/backup-amerenda.json
export RESTIC_PASSWORD=$(cat /etc/backup-keys/restic_password.txt)
export RESTIC_REPO="gs:amerenda-backups:/alexm-moove"

if restic snapshots -r gs:amerenda-backups:/alexm-moove &>/dev/null; then
    restic backup -r ${RESTIC_REPO} --files-from ${INCLUDE_FILE} --exclude-file ${EXCLUDE_FILE} --exclude-file <(find $HOME -type l) 
else
    echo "Restic repository is not initialized. Initializing now..."
    restic -r ${RESTIC_REPO} init
fi

unset GOOGLE_APPLICATION_CREDENTIALS
unset RESTIC_PASSWORD
unset RESTIC_REPO

sudo systemctl suspend
