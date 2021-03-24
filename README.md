[![Build Status](https://travis-ci.com/amerenda/dotfiles.svg?branch=master)](https://travis-ci.com/amerenda/dotfiles)
# README #

To install, do a recursive clone and run ./install

These dotfiles will work equally well on linux and macOS, it will detect the OS and load the correct config for each application.

`git clone git@github.com:amerenda/dotfiles.git --recursive`

## Docs
* None

## Dependencies
* zsh
* tmux
* zsh-autosuggestions
* coreutils
* hyper terminal

`brew install zsh-autosuggestions exa coreutils zsh tmux reattach-to-user-namespace`

`brew update`

`brew cask install hyper`


## Tweaks
Disable accented characters
`defaults write -g ApplePressAndHoldEnabled -bool false`
