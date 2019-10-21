#!/usr/bin/env bash

if [ -L ~/.ssh/config.d/macos ]; then
    unlink ~/.ssh/config.d/macos
elif [ -L ~/.ssh/config.d/linux ]; then
    unlink ~/.ssh/config.d/linux
fi

if `uname | grep -q Darwin`; then
    ln -s ~/.ssh/config_macos ~/.ssh/config.d/macos;
elif `uname | grep -q linux`; then
    ln -s ~/.ssh/config_linux ~/.ssh/config.d/linux;
fi
