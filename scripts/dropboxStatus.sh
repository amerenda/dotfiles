#!/bin/bash
#Dropbox Status outputs
#Dropbox isn't enabled : "Dropbox"
#Dropbox is startin: "Starting..."
#Dropbox is Syncing: "Syncing ..."
#Dropbox is running: "Up to date..."
STATUS="$(echo `dropbox.py status` | awk '{print $1;}')"
DROPBOX_ICON=""
if [[ $STATUS == *"Dropbox"* ]]; then
    :
elif [[ $STATUS == *"Starting"* ]]; then
  DROPBOX_ICON=""
elif [[ $STATUS == *"Syncing"* ]]; then
  DROPBOX_ICON=
else
  DROPBOX_ICON=""
fi
echo "$DROPBOX_ICON"
