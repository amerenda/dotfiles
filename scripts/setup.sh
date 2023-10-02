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
APT_PACKAGES="\
  xclip zsh tmux exa direnv git openvpn vim snapd \
  apt-transport-https ca-certificates gnupg curl"
FLATPAKS="com.visualstudio.code-oss \
  org.cryptomator.Cryptomator \
  org.signal.Signal org.signal.Signal \
  app/org.cryptomator.Cryptomator/x86_64/stable"

# cronjob definitions are located in the $HOME/.scripts/cronJobDefinitions dir. See 'example.txt' for help
# You just need to add the name of the file, not the file path to this list
CRON_JOBS=(
  "cleanLogs.txt"
  "cleanRecent.txt"
)


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
  printf "\n"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
}

install_docker() {
  echo "***** Installing Docker *****"
  printf "\n"
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
  printf "\n"
  curl https://sh.rustup.rs -o /tmp/rustup.rs
  sh /tmp/rustup.rs -y
}

check_result() {
  local exit_status=$?
  if [ $exit_status -eq 0 ]; then
    return 0
  else
    echo "Command returned error: $2"
    exit 1
  fi
}

decrypt_ssh_keys() {
  gpg --pinentry-mode loopback -d ${DOTFILES_PATH}/ssh/github.gpg > ${DOTFILES_PATH}/ssh/github
  check_result $? "decrypting github key"
  gpg --pinentry-mode loopback -d ${DOTFILES_PATH}/ssh/alexm_moove.gpg > ${DOTFILES_PATH}/ssh/alexm_moove
  check_result $? "decrypting moove key"
  gpg --pinentry-mode loopback -d ${DOTFILES_PATH}/ssh/alex_personal.gpg > ${DOTFILES_PATH}/ssh/alex_personal
  check_result $? "decrypting personal key"
  chmod 0400 ${DOTFILES_PATH}/ssh/github
  chmod 0400 ${DOTFILES_PATH}/ssh/alexm_moove
  chmod 0400 ${DOTFILES_PATH}/ssh/alex_personal
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
  flatpak install ${FLATPAKS} 2> /dev/null | echo
}

install_nordvpn() {
  sh <(curl -sSf https://downloads.nordcdn.com/apps/linux/install.sh)
}

add_cron_jobs() {
  cron_job_dir=$HOME/.scripts/cronJobDefinitions
  for cron in "${CRON_JOBS[@]}"; do
    def="${cron_job_dir}/${cron}"
    job="$(cat $def 2>/dev/null)"
    job_no_comment="$(cat $def 2>/dev/null | grep -v \#)"
    script="$(awk '{print $6}' <<< "$job_no_comment")"
    script="$(eval echo "$script")"

    if [ -e "$def" ]
    then
      :
    else
      echo "CronJob ${cron} is missing. Please create the file: $def with the cronjob definition."
      printf "\n"
      printf "\n"
      echo "*********************** EXAMPLE ***********************************"
      echo "# Removes files from the recent folder that match a list of strings"
      echo "* * * * * $HOME/.scripts/cleanRecent.sh"
      echo "*********************** EXAMPLE ***********************************"
      exit 1
    fi

    if [ -e "$script" ]
    then
      :
    else
      echo "Error missing script"
      printf "\n"
      printf "\n"
      echo "The script in CronJob: ${cron} is missing."
      echo "Please ensure the script you want to run is created."
      printf "\n"
      echo "Script not found in: ${script}"
      exit 2
    fi

    if ! (crontab -l 2>/dev/null | grep -Fq "$job"); then
      echo "Adding: $job"
      (crontab -l 2>/dev/null; echo "$job") | crontab -
    else
      :
    fi
  done
}

############################### Install components ###############################

add_cron_jobs
if [ $? -ne 0 ]; then
    echo "The check_cron_jobs command failed."
    exit 1
fi

# Init check & install
if ! [ -f $INIT_PATH/init ]; then
  init
  if [ $? -ne 0 ]; then
      echo "The init function failed."
      exit 1
  fi
fi

# Brew check & install
if ! command -v brew &> /dev/null
then
    echo "brew not found, installing"
    install_brew
  if [ $? -ne 0 ]; then
      echo "The install_brew function failed."
      exit 1
  fi
fi

# Docker check & install
if ! command -v docker &> /dev/null
then
    echo "Docker not found, installing"
    install_docker
  if [ $? -ne 0 ]; then
      echo "The install_docker function failed"
      exit 1
  fi
fi

# Install Cargo
if ! command -v cargo &> /dev/null
then
    echo "cargo not found, installing"
    install_cargo
  if [ $? -ne 0 ]; then
      echo "The cargo install function failed"
      exit 1
  fi
fi

# Decrypt ssh key
if ! [ -f ${DOTFILES_PATH}/ssh/decrypted ]
then
  echo "decrypting ssh keys"
  decrypt_ssh_keys
  if [ $? -ne 0 ]; then
      echo "The decrypt_ssh_keys function failed."
      exit 1
  fi
fi

# Change dotfiles to use git
echo "***** Changing dotfiles repo to use git *****"
printf "\n"
dot_files_to_git
  if [ $? -ne 0 ]; then
      echo "The dot_files_to_git function failed."
      exit 1
  fi

# Install tmux plugins
echo "***** Installing tmux plugins *****"
printf "\n"
bash ${DOTFILES_PATH}/tmux/plugins/tpm/scripts/install_plugins.sh 2&> /dev/null
  if [ $? -ne 0 ]; then
      echo "The install tmux command failed."
      exit 1
  fi

# Install glcoud
if ! command -v gcloud &> /dev/null
then
  echo "***** Installing gcloud *****"
  printf "\n"
  install_gcloud
  if [ $? -ne 0 ]; then
      echo "The install_gcloud function failed."
      exit 1
  fi
fi

# Install nordpass
if ! command -v nordpass &> /dev/null
then
  echo "***** Installing nordpass *****"
  printf "\n"
  snap install nordpass
  if [ $? -ne 0 ]; then
      echo "The install nordpass command failed."
      exit 1
  fi
fi

# Install github command line
if ! command -v gh &> /dev/null
then
  echo "***** Installing gh *****"
  printf "\n"
  brew install gh
  if [ $? -ne 0 ]; then
      echo "The gh install command failed"
      exit 1
  fi
fi

# install flatpaks
echo "***** Checking flatpaks  *****"
install_flatpaks
  if [ $? -ne 0 ]; then
      echo "The install_flatpaks function failed."
      exit 1
  fi

# Install helm
if ! command -v helm &> /dev/null
then
  echo "***** Installing helm *****"
  printf "\n"
  brew install helm
  if [ $? -ne 0 ]; then
      echo "The command brew install failed."
      exit 1
  fi
fi

# install tflint
if ! command -v tflint &> /dev/null
then
  echo "***** Installing helm *****"
  printf "\n"
  brew install tflint
  if [ $? -ne 0 ]; then
      echo "The command brew install tflint."
      exit 1
  fi
fi

# Install nordvpn
if ! command -v nordvpn &> /dev/null
then
  echo "***** Installing nordvpn *****"
  printf "\n"
  install_nordvpn
  if [ $? -ne 0 ]; then
      echo "Install nordvpn command failed"
      exit 1
  fi
fi

if ! command -v d2 &> /dev/null
then
  echo "***** Installing dw *****"
  printf "\n"
  curl -fsSL https://d2lang.com/install.sh | sh -s --
  if [ $? -ne 0 ]; then
      echo "Install d2 command failed"
      exit 1
  fi
fi


