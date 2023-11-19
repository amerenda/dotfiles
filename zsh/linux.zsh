alias ls='ls --color=auto'
export GOPATH=$HOME/projects/go # don't forget to change your path correctly!
export GOROOT=/usr/lib/go
export GOBIN=$HOME/projects/go/bin
export PATH=$PATH:$GOPATH/bin
export PATH=$PATH:$GOROOT/bin
export TMPDIR=/tmp

# There is some kind of bug where capslock behaves as both escape and capslock, this fixes it for gnome
# Check if the XDG_CURRENT_DESKTOP environment variable is set
