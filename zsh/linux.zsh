alias ls='ls --color=auto'
export GOPATH=$HOME/projects/go # don't forget to change your path correctly!
export GOROOT=/usr/lib/go
export GOBIN=$HOME/projects/go/bin
export PATH=$PATH:$GOPATH/bin
export PATH=$PATH:$GOROOT/bin

# transparent arm execution with qemu
export QEMU_LD_PREFIX=/usr/arm-linux-gnueabihf

