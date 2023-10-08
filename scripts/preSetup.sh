#!/bin/bash

if ! [ -d ~/.config ]; then
  mkdir ~/.config
fi

if ! [ -d ~/.config/conky ]; then
  mkdir ~/.config/conky
fi

if ! [ -d ~/.config/autostart ]; then
  mkdir ~/.config/autostart
fi

ssh_test_path="$HOME/.ssh/github"
if ! [ -L ${ssh_test_path} ]; then
  echo "Symlink not found"
  rm -fr ~/.ssh
fi

rm -fr ~/.bin
