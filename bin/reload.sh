#!/bin/bash
pkill polybar
~/.bin/start_polybar.sh & 2>/dev/null

pkill dunst
dunst & 2>/dev/null

pkill xbindkeys
xbindkeys & 2>/dev/null
