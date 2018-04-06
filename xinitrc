#!/bin/sh

userresources=$HOME/.Xresources
usermodmap=$HOME/.Xmodmap
sysresources=/etc/X11/xinit/.Xresources
sysmodmap=/etc/X11/xinit/.Xmodmap

# merge in defaults and keymaps

if [ -f $sysresources ]; then

    xrdb -merge $sysresources

fi

if [ -f $sysmodmap ]; then
    xmodmap $sysmodmap
fi

if [ -f "$userresources" ]; then

    xrdb -merge "$userresources"

fi

if [ -f "$usermodmap" ]; then
    xmodmap "$usermodmap"
fi

# start some nice programs

if [ -d /etc/X11/xinit/xinitrc.d ] ; then
 for f in /etc/X11/xinit/xinitrc.d/?*.sh ; do
  [ -x "$f" ] && . "$f"
 done
 unset f
fi

# calendar reminders
if [ -x /usr/bin/gcalcli ]; then
  while true; do
    /usr/bin/gcalcli --configFolder "~/.gcalcli_placeiq" --calendar="amerenda@placeiq.com" remind 10 'notify-send -i /usr/share/icons/Numix/48/categories/preferences-calendar-and-tasks.svg -a gcalcli %s' 2> /dev/null
    /usr/bin/gcalcli --configFolder "~/.gcalcli_personal" --calendar="amerenda89@gmail.com" remind 10 'notify-send -i /usr/share/icons/Numix/48/categories/preferences-calendar-and-tasks.svg -a gcalcli %s' 2> /dev/null
    sleep 300
  done &
fi



# sets custom font path
xset +fp /usr/share/fonts/local/

# starts xbindkeys to map media keys
xbindkeys

# starts i3 window manager and logs it
exec i3 -V >> ~/.i3/log/i3-out-$(date + '%F-%k-%M-%S').log 2>&1
