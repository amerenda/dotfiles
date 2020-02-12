# pip should only run if there is a virtualenv currently activated
#export PIP_REQUIRE_VIRTUALENV=true

# Export SSH Variables
#export SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/ssh-agent.socket"

# disable ansible cowsay
export ANSIBLE_NOCOWS=1

# Cache pip-installed packages to avoid re-downloading
export PIP_DOWNLOAD_CACHE=$HOME/.pip/cache
export INVENTORY_IP_TYPE=internal
export DEFAULT_USER=alexmerenda
export GOSS_PATH=~/bin/goss-linux-amd64
export PATH="$PATH:$CARGO_HOME/bin"
eval "$(direnv hook zsh)"
