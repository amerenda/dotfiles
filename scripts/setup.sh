#!/bin/bash

### TO ADD
# Alacritty -deb
# kubectl - curl
# kubectx - brew
# install terraform - https://learn.hashicorp.com/tutorials/terraform/install-cli
# nordvpn

# Set variables
USER=$(whoami)
DOTFILES_PATH="$HOME/projects/dotfiles"
INIT_PATH="$HOME/misc/scripts/install"
APT_PACKAGES="xclip zsh tmux exa direnv git openvpn vim snapd apt-transport-https ca-certificates gnupg curl"
FLATPAKS="com.visualstudio.code-oss org.cryptomator.Cryptomator org.signal.Signal org.signal.Signal"


############################### Define Functions ###############################

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

install_gcloud() {
  echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
  curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key --keyring /usr/share/keyrings/cloud.google.gpg add -
  sudo apt-get update && sudo apt-get install google-cloud-cli
}

install_flatpaks(){
  flatpak install ${FLATPAKS}
}

install_nordvpn() {
  sh <(curl -sSf https://downloads.nordcdn.com/apps/linux/install.sh)
}

############################### Install components ###############################

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
echo "***** Changing dotfiles repo to use git *****"
dot_files_to_git

# Install tmux plugins
echo "***** Installing tmux plugins *****"
bash ${DOTFILES_PATH}/tmux/plugins/tpm/scripts/install_plugins.sh

# Install glcoud
if ! command -v gcloud &> /dev/null
then
  echo "***** Installing gcloud *****"
  install_gcloud
fi

# Install nordpass
if ! command -v nordpass &> /dev/null
then
  echo "***** Installing nordpass *****"
  snap install nordpass
fi

# Install github command line
if ! command -v gh &> /dev/null
then
  echo "***** Installing gh *****"
  brew install gh
fi

# install flatpaks
echo "***** Installing flatpaks  *****"
install_flatpaks

# Install github command line
if ! command -v helm &> /dev/null
then
  echo "***** Installing helm *****"
  brew install helm
fi

if ! command -v nordvpn &> /dev/null
then
  echo "***** Installing nordvpn *****"
  install_nordvpn
fi
