# pip should only run if there is a virtualenv currently activated
export PIP_REQUIRE_VIRTUALENV=true

# Cache pip-installed packages to avoid re-downloading
export ANSIBLE_NOCOWS=1
export PIP_DOWNLOAD_CACHE=$HOME/.pip/cache

# Path settings
export PATH="/usr/local/opt/openjdk/bin:$PATH"
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/.cargo/env:$PATH"

# Google variables
export USE_GKE_GCLOUD_AUTH_PLUGIN=True

# Terraform
export TF_LOG_PATH=$HOME/tmp/terraform-debug.log

# Evals
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
eval "$(direnv hook zsh)"

# Dotfiles helper
export DOTFILES_PATH=$HOME/projects/dotfiles

# Fix issues with electron apps in wayland
ELECTRON_OZONE_PLATFORM_HINT=auto

#sudo /usr/sbin/setcap -r $(readlink -f $(which sunshine))
