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
  sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  sudo echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
    $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
  sudo apt-get update
  sudo apt -y install docker-ce docker-ce-cli containerd.io docker-compose-plugin
  sudo usermod -aG docker $USER
}

install_input_remapper(){
  echo "************ Installing input-remapper **********"
  sudo apt install git python3-setuptools gettext
  git clone https://github.com/sezanzeb/input-remapper.git ~/tmp/input-remapper
  cd ~/tmp/input-remapper && ./scripts/build.sh
  sudo apt install ./dist/input-remapper-*.deb

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

# Input-remapper check & install
if ! command -v input-remapper-service &> /dev/null
then
    echo "input-remapper not found, installing"
    install_input_remapper
fi

