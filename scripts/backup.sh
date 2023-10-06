#!/usr/bin/env bash


export DOTFILES_DIR=${HOME}/projects/dotfiles
export INCLUDE_FILE="./meta/backup/include.txt"
export EXCLUDE_FILE="./meta/backup/exclude.txt"

export OUTPUT_LOG="${DOTFILES_DIR}/logs"

export GOOGLE_APPLICATION_CREDENTIALS=/etc/backup-keys/backup-amerenda.json
export RESTIC_PASSWORD=$(cat /etc/backup-keys/restic_password.txt)
echo $REESTIC_PASSWORD

if restic snapshots &>/dev/null; then
    : 
else
    echo "Restic repository is not initialized. Initializing now..."
    restic -r gs:amerenda-backups:/alexm-moove init
fi

#restic backup --files-from ${INCLUDE_FILE} --exclude-file ${EXCLUDE_FILE} > ${OUTPUT_LOG}/restic.log 2> ${OUTPUT_LOG}/restic-error.log

