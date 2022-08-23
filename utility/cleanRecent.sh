#!/bin/bash

# Variables
recent="$HOME/.local/share/recently-used.xbel"
verbot="dngr"
cache=".cache.txt"

# create cache
touch $cache

# get list of files matching
grep -i $verbot $recent | awk '{ print $2 }' >> $cache

while read -r line
do
  if [[ $line != "" ]]; then
    xmlstarlet ed --inplace --delete "//bookmark[@$line]" $recent
  fi
done < $cache

# remove file cache
rm -f $cache
