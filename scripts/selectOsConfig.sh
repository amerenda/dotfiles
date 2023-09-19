#!/usr/bin/env bash
if [ -L ~/.ssh/config.d/macos ]; then
    unlink ~/.ssh/config.d/macos
elif [ -L ~/.ssh/config.d/linux ]; then
    unlink ~/.ssh/config.d/linux
fi

if $(uname | grep -q Darwini); then
    echo "Found macOS."
    echo "Applying macOS Settings"
    TMUX_OPTIONS="set-option -g default-command "reattach-to-user-namespace -l zsh""
    ln -s ~/.ssh/config_macos ~/.ssh/config.d/macos;
    sed -i "s/#STRING_REPLACE_CAKE/${TMUX_OPTIONS}/g" ~/.tmux.conf
elif $(uname | grep -q linux); then
    echo "Found Linux"
    echo "Applying Linux settings"
    TMUX_OPTIONS="#Linux Options"
    sed -i "s/#STRING_REPLACE_CAKE/${TMUX_OPTIONS}/g" ~/.tmux.conf
    ln -s ~/.ssh/config_linux ~/.ssh/config.d/linux;
fi


