#!/bin/bash

### TO ADD
# gcloud cli -deb
# Alacritty -deb
# vscode - deb
# gh cli - brew
# spotify - flatpak
# helm - brew
# kubectl - curl
# kubectx - brew
# install terraform - https://learn.hashicorp.com/tutorials/terraform/install-cli
# nordvpn
# xpadneo - https://atar-axis.github.io/xpadneo/




# Set variables
USER=$(whoami)
DOTFILES_PATH="$HOME/projects/dotfiles"
INIT_PATH="$HOME/misc/scripts/install"
APT_PACKAGES="zsh tmux exa direnv git openvpn"


init() {
  mkdir -p $INIT_PATH 2&>/dev/null
  mkdir -p $HOME/tmp 2&>/dev/null
  sudo apt update
  sudo apt -y install $APT_PACKAGES
  sudo chsh --shell /usr/bin/zsh $USER
  touch $INIT_PATH/init
}

install_brew() {
  echo "***** Installing Brew *****"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
}

install_docker() {
  echo "***** Installing Docker *****"
  sudo apt-get -y remove docker docker-engine docker.io containerd runc
  sudo apt-get update
  sudo apt-get install ca-certificates curl gnupg lsb-release
  sudo mkdir -p /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  sudo echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
    $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
  sudo apt-get update
  sudo apt -y install docker-ce docker-ce-cli containerd.io docker-compose-plugin
  sudo systemctl start docker
  sudo usermod -aG docker $USER
  newgrp docker
}

install_cargo() {
  echo "***** Installing rust + cargo *****"
  curl https://sh.rustup.rs -sSf | sh
}

decrypt_ssh_keys() {
  gpg -d ${DOTFILES_PATH}/ssh/github.gpg > ${DOTFILES_PATH}/ssh/github
  gpg -d ${DOTFILES_PATH}/ssh/alexm_moove.gpg > ${DOTFILES_PATH}/ssh/alexm_moove
  gpg -d ${DOTFILES_PATH}/ssh/alex_personal.gpg > ${DOTFILES_PATH}/ssh/alex_personal
  touch ${DOTFILES_PATH}/ssh/decrypted
}

dot_files_to_git() {
  cd ${DOTFILES_PATH}
  git remote set-url origin git@github.com:amerenda/dotfiles.git
}

# Init check & install
if ! [ -f $INIT_PATH/init ]; then
  init
fi

# Brew check & install
if ! command -v brew &> /dev/null
then
    echo "brew not found, installing"
    install_brew
fi

# Docker check & install
if ! command -v docker &> /dev/null
then
    echo "Docker not found, installing"
    install_docker
fi

# Install Cargo
if ! command -v cargo &> /dev/null
then
    echo "cargo not found, installing"
    install_cargo
fi

# Decrypt ssh key
if ! [ -f ${DOTFILES_PATH}/ssh/decrypted ]
then
  echo "decrypting ssh keys"
  decrypt_ssh_keys
fi

# Change dotfiles to use git
dot_files_to_git
