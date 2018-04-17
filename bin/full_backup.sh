#!/bin/bash
if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi

if [ $# -eq 0 ]
  then
    echo "please specify a backup path"
fi

rsync -aAXv --exclude={"/dev/*","/proc/*","/sys/*","/tmp/*","/run/*","/mnt/*","/media/*","/lost+found","/home/amerenda/.config/","/home/amerenda/.cache/","/home/amerenda/.local/share/Steam/*","/home/amerenda/tmp/","/home/amerenda/Downloads/","/home/amerenda/.i3/log/","/home/amerenda/.mozilla/","/home/amerenda/Dropbox/*","$1"/*} / "$1"
