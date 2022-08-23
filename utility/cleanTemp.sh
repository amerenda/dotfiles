#!/bin/bash

# Variables
recent="/home/alex/.local/share/recently-used.xbel"
verbot="STRING_TO_MATCH" 
cache=".cache.txt"

# create cache
touch 

# get list of files matching
grep -i   | awk '{ print  }' >> 

while read -r line
do
  if [[  != "" ]]; then
    xmlstarlet ed --inplace --delete "//bookmark[@]" 
  fi
done < 

# remove file cache
rm -f 
