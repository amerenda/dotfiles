#!/usr/bin/env bash


export DOTFILES_DIR=${HOME}/projects/dotfiles
export INCLUDE_FILE="./meta/backup/include.txt"
export EXCLUDE_FILE="./meta/backup/exclude.txt"

export OUTPUT_LOG=""

export GOOGLE_APPLICATION_CREDENTIALS=/etc/backup-keys/backup-amerenda.json
export RESTIC_REPOSITORY="gs://amerenda-backups/$(hostname)"
export RESTIC_PASSWORD=$(cat /etc/backup-keys/restic_password.txt)

if restic snapshots &>/dev/null; then
    : 
else
    echo "Restic repository is not initialized. Initializing now..."
    restic init
fi

restic backup --files-from ${INCLUDE_FILE} --exclude-file ${EXCLUDE_FILE} > ${DOTFILES_DIR}/logs/restic.log 2> ${DOTFILES_DIR}/logs/restic-error.log

