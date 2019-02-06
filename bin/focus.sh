#!/bin/sh

function blackHoleSites()
{
    # back up /etc/hosts for later
    sudo /bin/cp -f /etc/hosts  /etc/hosts-orginal
    # clean temp hosts
    echo > /tmp/hosts.tmp
    # put /etc/hosts into tmp hosts
    cat /etc/hosts >> /tmp/hosts.tmp
    echo "### START BLOCKLIST" >> /tmp/hosts.tmp
    # loop through sitesToBlock and store it in tmp hosts file
    for i in "${sitesToBlock[@]}"
    do
        echo "127.0.0.1         $i" >> /tmp/hosts.tmp
        echo "127.0.0.1         www.$i" >> /tmp/hosts.tmp
        echo "fe80::1%lo0       $i" >> /tmp/hosts.tmp
        echo "fe80::1%lo0       www.$i" >> /tmp/hosts.tmp
    done
    echo "### END BLOCKLIST" >> /tmp/hosts.tmp
    sudo /bin/cp -f /tmp/hosts.tmp /etc/hosts
}


if [[ ${1} == "start" ]]; then
    osascript -e "display notification \"Time to focus! for ${2} minutes\" with title \"Focus\""
    declare -a sitesToBlock=("reddit.com" "facebook.com" "news.ycombinator.com")
    blackHoleSites
elif [[ ${1} == "stop" ]]; then
    say "Time is up" &
    osascript -e "display notification \"Time is up! You focused for ${2} minutes\" with title \"Focus\"" &
    sudo /bin/cp -f /etc/hosts-orginal /etc/hosts
fi
