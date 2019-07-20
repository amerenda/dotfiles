# Initialize completion
autoload -Uz compinit && compinit

# Initialize editing command line
autoload -U edit-command-line && zle -N edit-command-line

# Set automatic cd (typing directory name with no 'cd')
#setopt autocd

# Enable interactive comments (# on the command line)
#setopt interactivecomments

# Show menu
zstyle ':completion:*' menu select

# Nicer history
HISTSIZE=1048576
HISTFILE="$HOME/.zsh_history"
SAVEHIST=$HISTSIZE
setopt appendhistory
setopt incappendhistory
setopt extendedhistory

# Time to wait for additional characters in a sequence
KEYTIMEOUT=1 # corresponds to 10ms

# Use vim as the editor
export VISUAL=vim
export EDITOR="$VISUAL"

# vi key bindings
bindkey -v
bindkey -M viins ‘jj’ vi-cmd-mode

# Movement
bindkey -a 'gg' beginning-of-buffer-or-history
bindkey -a 'G' end-of-buffer-or-history

# Undo
bindkey -a 'u' undo
bindkey -a '^R' redo

# Use incremental search
bindkey "^R" history-incremental-search-backward

# kubectl autocompletion
source <(kubectl completion zsh)
