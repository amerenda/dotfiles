# pip should only run if there is a virtualenv currently activated
#export PIP_REQUIRE_VIRTUALENV=true

# Export SSH Variables
#export SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/ssh-agent.socket"

# Cache pip-installed packages to avoid re-downloading
export PIP_DOWNLOAD_CACHE=$HOME/.pip/cache


# disable cowsay with ansible
export ANSIBLE_NOCOWS=1
export GOROOT=/usr/local/go
export GOBIN=/usr/bin/go
export GOPATH=~/go
PATH=~/.bin:~/.local/bin/:/usr/local/bin:${PATH}:${GOPATH}

# write a function that...
# Checks if there's an event happening in 30 minutes
# notifies ONCE about the event
# checks if an event is happening in 10 minutes
# notifies again one time about the event
