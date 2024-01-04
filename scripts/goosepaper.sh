#!/usr/bin/env bash

# Enter directory
cd /tmp

# Create goosepaper
docker run -it --rm \
    -v $HOME/.scripts/meta/goose_config.json:/goosepaper/config/goose_config.json \
    -v $(pwd):/goosepaper/mount \
    j6k4m8/goosepaper \
    goosepaper -c /goosepaper/config/goose_config.json -o /goosepaper/mount/Goosepaper.pdf

# Remove old goosepaper
docker run -v $HOME/.config/rmapi/:/home/app/.config/rmapi/ -v $HOME/misc/goosepaper/:/home/app/ -it rmapi rm /Goosepaper.pdf

# Copy new goosepaper
docker run -v $HOME/.config/rmapi/:/home/app/.config/rmapi/ -v $(pwd):/home/app/ -it rmapi put /home/app/Goosepaper.pdf /

