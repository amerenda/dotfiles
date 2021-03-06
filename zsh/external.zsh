# pip should only run if there is a virtualenv currently activated
#export PIP_REQUIRE_VIRTUALENV=true

# Export SSH Variables
#export SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/ssh-agent.socket"

# Cache pip-installed packages to avoid re-downloading
export ANSIBLE_NOCOWS=1
export PIP_DOWNLOAD_CACHE=$HOME/.pip/cache
export INVENTORY_IP_TYPE=internal
export DEFAULT_USER=alexmerenda
export PATH="/Users/alexmerenda/.bin:/usr/local/opt/python/libexec/bin:/Users/alexmerenda/Library/Python/3.7/bin:/usr/local/bin:/usr/local/opt/openvpn/sbin:/Users/alexmerenda/.cargo/bin:$PATH"
export GOSS_PATH=~/bin/goss-linux-amd64
export PATH="$PATH:$CARGO_HOME/bin"
eval "$(direnv hook zsh)"
export JAVA_HOME=/Library/Java/JavaVirtualMachines/jdk1.8.0_181.jdk/Contents/Home
export GOOGLE_APPLICATION_CREDENTIALS=~/.gcloud_creds/terraform-serviceaccount.json

