alias ls='ls -G'
alias dircolors="gdircolors"
alias brewup="brew update && brew upgrade"
alias clip="pbcopy"

export GOPATH=$HOME/projects/go # don't forget to change your path correctly!
export GOROOT=/usr/local/opt/go/libexec
export GOBIN=$HOME/projects/go/bin
export PATH="$PATH:/usr/local/opt/python/libexec/bin:$HOME/Library/Python/3.7/bin:/usr/local/bin:/usr/local/opt/openvpn/sbin:$HOME/.cargo/bin:$GOPATH/bin"
export PATH=$PATH:$GOROOT/bin
export JAVA_HOME=/Library/Java/JavaVirtualMachines/jdk1.8.0_181.jdk/Contents/Home
