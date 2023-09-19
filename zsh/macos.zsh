alias dircolors="gdircolors"
alias brewup="brew update && brew upgrade && brew cask upgrade --greedy"
alias clip="pbcopy"

export GOPATH=$HOME/projects/go # don't forget to change your path correctly!
export GOROOT=/usr/local/opt/go/libexec
export GOBIN=$HOME/projects/go/bin
export PATH=$PATH:$GOPATH/bin export PATH=$PATH:$GOROOT/bin
