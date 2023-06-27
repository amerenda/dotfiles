# pip should only run if there is a virtualenv currently activated
export PIP_REQUIRE_VIRTUALENV=true

# Cache pip-installed packages to avoid re-downloading
export ANSIBLE_NOCOWS=1
export PIP_DOWNLOAD_CACHE=$HOME/.pip/cache

# Path settings
export PATH="/usr/local/opt/openjdk/bin:$PATH"
export PATH="$PATH:/opt/aerospike/bin"
export PATH="$HOME/.local/bin:$PATH"

# Google variables
export GOOGLE_APPLICATION_CREDENTIALS=~/.gcloud_creds/terraform-serviceaccount.json
export USE_GKE_GCLOUD_AUTH_PLUGIN=True

# Terraform
export TF_LOG_PATH=~/tmp/terraform-debug.log

# Evals
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
eval "$(direnv hook zsh)"

