# Allow local customizations in the ~/.zshrc_local_before file
if [ -f ~/.zshrc_local_before ]; then
    SECONDS=0
    source ~/.zshrc_local_before
    duration=$SECONDS
    echo "~/.zshrc_local_before.zsh: $(($duration % 60))s"
fi
# init plugins
/usr/local/bin/antibody bundle < ~/.zsh/plugins.txt > ~/.zsh/plugins.zsh

# Aliases (must be sourced before plugins)
SECONDS=0
source ~/.zsh/aliases.zsh
duration=$SECONDS
echo "~/.zsh/aliases.zsh: $(($duration % 60))s"

# Impact settings
SECONDS=0
source ~/.zsh/impact.zsh
duration=$SECONDS
echo "~/.zsh/impact.zsh: $(($duration % 60))s"

# go settings
SECONDS=0
source ~/.zsh/go.zsh
duration=$SECONDS
echo "~/.zsh/go.zsh: $(($duration % 60))s"

# Settings
SECONDS=0
source ~/.zsh/settings.zsh
duration=$SECONDS
echo "~/.zsh/settings.zsh: $(($duration % 60))s"

# External settings
SECONDS=0
source ~/.zsh/external.zsh
duration=$SECONDS
echo "~/.zsh/external.zsh: $(($duration % 60))s"

# Source plugins
SECONDS=0
source ~/.zsh/plugins.zsh
duration=$SECONDS
echo "~/.zsh/plugins.zsh: $(($duration % 60))s"

# Allow local customizations in the ~/.zshrc_local_after file
if [ -f ~/.zshrc_local_after ]; then
    SECONDS=0
    source ~/.zshrc_local_after
    duration=$SECONDS
    echo "~/.zshrc_local_after.zsh: $(($duration % 60))s"
fi
