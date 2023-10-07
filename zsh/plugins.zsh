antigen theme spaceship-prompt/spaceship-prompt &>> $HOME/.logs/antigen.error
antigen bundle zsh-users/zsh-autosuggestions &>> $HOME/.logs/antigen.error
antigen bundle zsh-users/zsh-syntax-highlighting &> $HOME/.logs/antigen.error
antigen bundle zsh-users/zsh-history-substring-search $HOME/.logs/antigen.error
antigen apply
