# pip should only run if there is a virtualenv currently activated
#export PIP_REQUIRE_VIRTUALENV=true

# Export SSH Variables
#export SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/ssh-agent.socket"

# Cache pip-installed packages to avoid re-downloading
export ANSIBLE_NOCOWS=1
export PIP_DOWNLOAD_CACHE=$HOME/.pip/cache
export GOROOT=/usr/local/go
export GOBIN=/usr/bin/go
export GOPATH=~/go
export PATH=/home/amerenda/.bin/pip/bin:/home/amerenda/.bin:/home/amerenda/.local/bin/:/usr/local/bin:${PATH}:${GOPATH}
