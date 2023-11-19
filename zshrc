## Allow local customizations in the ~/.zshrc_local_before file
if [ -f ~/.zshrc_local_before ]; then
    source ~/.zshrc_local_before
fi

# Installs plugin manager
source ~/.antigen/antigen.zsh

# Installs plugins
source ~/.zsh/plugins.zsh

# Aliases (must be sourced before plugins)
source ~/.zsh/aliases.zsh

# go settings
source ~/.zsh/go.zsh

# Settings
source ~/.zsh/settings.zsh

# External settings
source ~/.zsh/external.zsh

# Install yq commands
source ~/.zsh/yq.zsh

# source spaceship
source ~/.zsh/spaceship.zsh

# Allow local customizations in the ~/.zshrc_local_after file
if [ -f ~/.zshrc_local_after ]; then
    source ~/.zshrc_local_after
fi

if uname | grep -q Darwin; then
    source ~/.zsh/macos.zsh
fi

if uname | grep -q Linux; then
    source ~/.zsh/linux.zsh
fi

#source ~/.zsh/temp.zsh
