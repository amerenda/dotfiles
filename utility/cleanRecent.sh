#!/bin/bash

file="/home/alex/.local/share/recently-used.xbel"
verbot="dngr"
cache="./.cache.txt"

# clear cache
echo > $cache

# get list of files matching
grep -i $verbot $file >> $cache

while read -r line
do
  if [[ $line != "" ]]; then
    match=$(echo $line | awk '{ print $2 }')
    xmlstarlet ed --inplace --delete "//bookmark[@$match]" $file
  fi
done < $cache

# remove file cache
rm -f $cache
