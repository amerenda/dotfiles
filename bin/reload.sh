#!/bin/bash
pkill polybar
~/.bin/start_polybar.sh &

pkill dunst
dunst &

pkill xbindkeys
xbindkeys &
