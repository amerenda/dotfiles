debug() {
    debugOn="false"
    sourceFile="${1}"
    duration="${2}"
    if [[ "${debugOn}" == "true" ]]; then
        echo "${sourceFile}: ${duration}s"
    fi
}

# Allow local customizations in the ~/.zshrc_local_before file
if [ -f ~/.zshrc_local_before ]; then
    SECONDS=0
    source ~/.zshrc_local_before
    duration=$SECONDS
    debug "false" "~/.zshrc_local_before.zsh" $(($duration % 60))
fi
# init plugins
#/usr/local/bin/antibody bundle < ~/.zsh/plugins.txt > ~/.zsh/plugins.zsh

SECONDS=0
source ~/.antigen/antigen.zsh
duration=$SECONDS
debug "~/.antigen/antigen.zsh" "$(($duration % 60))"

## Activate Plugins via antigent
SECONDS=0
source ~/.zsh/plugins.zsh
duration=$SECONDS
debug  "~/.zsh/plugins.zsh" "$(($duration % 60))"

# Aliases (must be sourced before plugins)
SECONDS=0
source ~/.zsh/aliases.zsh
duration=$SECONDS
debug  "~/.zsh/aliases.zsh" "$(($duration % 60))"

# Impact settings
SECONDS=0
source ~/.zsh/impact.zsh
duration=$SECONDS
debug "~/.zsh/impact.zsh" "$(($duration % 60))"

# go settings
SECONDS=0
source ~/.zsh/go.zsh
duration=$SECONDS
debug "~/.zsh/go.zsh" "$(($duration % 60))"

# Settings
SECONDS=0
source ~/.zsh/settings.zsh
duration=$SECONDS
debug "~/.zsh/settings.zsh" "$(($duration % 60))"

# External settings
SECONDS=0
source ~/.zsh/external.zsh
duration=$SECONDS
debug "~/.zsh/external.zsh" "$(($duration % 60))"

# Source spaceship prompt
SECONDS=0
source ~/.zsh/spaceship.zsh
duration=$SECONDS
debug "~/.zsh/spaceship.zsh" "$(($duration % 60))"


# Allow local customizations in the ~/.zshrc_local_after file
if [ -f ~/.zshrc_local_after ]; then
    SECONDS=0
    source ~/.zshrc_local_after
    duration=$SECONDS
    debug "~/.zshrc_local_after.zsh" "$(($duration % 60))"
fi
