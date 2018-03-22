#!/bin/sh -e

# Take a screenshot
scrot /tmp/screen_locked.png

# Pixellate it 10x
mogrify -scale 20% -scale 500% /tmp/screen_locked.png

# Pauses music
if pgrep spotify >/dev/null; then
    dbus-send --print-reply --dest=org.mpris.MediaPlayer2.spotify /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.Pause
fi

# Lock screen displaying this image.
i3lock -i /tmp/screen_locked.png
