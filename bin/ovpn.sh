#!/bin/bash
pgrep -x openvpn &> /dev/null
if [[ $? -eq 0 ]]; then
    device=$(nmcli device | grep wifi | awk '{ print $1 }')
    if [[ $(nmcli con | grep -i vpn | grep 'stormhold' | awk '{ print $4 }') == "$device" ]]; then
        vpn="stormhold"
    elif [[ $(nmcli con | grep -i vpn | grep 'PlaceIQ' | awk '{ print $4 }') == "$device" ]]; then
        vpn="piq"
    else
        vpn="other"
    fi
fi



function send_status {
    icon="🖧"
    case  $1 in
        piq)
            echo "%{F#EBCB8B}$icon"
            ;;
        stormhold)
            echo "%{F#8FA1B3}$icon"
            ;;
        other)
            echo "%{F#D08770}$icon"
            ;;
    esac
}

case $1 in
    status)
        send_status "$vpn"
    ;;
    notif)
        notify "$vpn"
    ;;
esac
