#!/bin/bash

if ! [ -d ~/.config ]; then
  mkdir ~/.config
fi
rm -fr ~/.ssh
rm -fr ~/.bin
