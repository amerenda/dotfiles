#!/usr/bin/env bash

kill_cafe() {
    kill $(ps aux | grep caffeinate | grep -v grep | awk '{ print $2 }')
}

trap "rm -rf /Users/alexm/tmp/caffeinated && kill_cafe" EXIT

while True
do
    STATUS=$(pmset -g batt | head -n 1 | cut -d \' -f2)

    # Turns keep awake on if AC power is connected
    # Uses atomic directory to prevent multiple executions
    if [ "${STATUS}" == "AC Power" ] && [ ! -d "/Users/alexm/tmp/caffeinated" ]; then
        caffeinate -dist 0 &
        echo "Keep Awake on"
        mkdir /Users/alexm/tmp/caffeinated
    fi

    # Turns off keep awake if the AC power is disconnected and the caffeinated directory is still there
    if [ "${STATUS}" != "AC Power" ] && [ -d "/Users/alexm/tmp/caffeinated" ]; then
        echo "Keep Awake off"
        kill $(ps aux | grep caffeinate | grep -v grep | awk '{ print $2 }')
        rm -fr /Users/alexm/tmp/caffeinated
    fi
    sleep 1;
done

