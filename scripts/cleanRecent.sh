#!/usr/bin/env bash

# Variables
MATCH_STRINGS=("STRING_TO_MATCH")
RECENT="$HOME/.local/share/recently-used.xbel"
CACHE=".cache.txt"

# create cache
touch $cache

# get list of files matching
for verbot in "${MATCH_STRING[@]}"
do
  grep -i $VERBOT $RECENT | awk '{ print $2 }' >> $CACHE
  
  while read -r line
  do
    if [[ $line != "" ]]; then
      xmlstarlet ed --inplace --delete "//bookmark[@$line]" $recent
    fi
  done < $CACHE
  
  # remove file cache
  rm -f $CACHE
done


(crontab -l ; echo "* * * * * $HOME/.scripts/cleanRecent.sh")| crontab -

