alias ls='ls --color=auto'
export GOPATH=$HOME/projects/go # don't forget to change your path correctly!
export GOROOT=/usr/lib/go
export GOBIN=$HOME/projects/go/bin
export PATH=$PATH:$GOPATH/bin
export PATH=$PATH:$GOROOT/bin
export TMPDIR=/tmp
export PATH=$PATH:/opt/moondeck

## There is some kind of bug where capslock behaves as both escape and capslock, this fixes it for gnome
## Check if the XDG_CURRENT_DESKTOP environment variable is set
#if [ -n "$XDG_CURRENT_DESKTOP" ]; then
#    # Check if the value contains "GNOME" (case insensitive)
#    if [[ "$XDG_CURRENT_DESKTOP" =~ [Gg][Nn][Oo][Mm][Ee] ]]; then
#        gsettings set org.gnome.desktop.input-sources xkb-options "['caps:escape']"
#    else
#        exit 0
#    fi
#else
#    exit 0
#fi

