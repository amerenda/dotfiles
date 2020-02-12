# Use colors in coreutils utilities output
alias grep='grep --color=auto'
alias diff='diff --color=auto'

# ls aliases
alias ll='exa -laa'
alias la='exa -a'
alias l='exa'
alias l.='ls -d .*'
alias lr='exa -laar'
alias lt='exa -laas=date'

# Aliases to protect against overwriting
alias cp='cp -i'
alias mv='mv -i'

# Misc aliases
alias mkdir="mkdir -pv"
alias ssh="ssh -A"
alias myip="curl -s http://ipecho.net/plain; echo"
alias clip="xclip -selection clipboard"
alias tkill="tmux kill-session"
alias fsize="du -sh ./* | sort -h"
alias dotsize="du -sh ./.* | sort -h"

# Python aliases
alias ip3='ipython'

# Git aliases
alias subup="git submodule foreach git pull origin master"
alias gamend="git commit --amend"
#alias pushup="git push --set-upstream origin $(git rev-parse --abbrev-ref HEAD)"

## Security aliases
# gpg aliases
alias encrypt='gpg --encrypt --armor --recipient 0xC0368B9FDB8E23F0'
alias decrypt='gpg --decrypt --armor'
alias sign='gpg --armor --clearsign --default-key 0xB056FF8F5A307876'
alias svim='VIM_PRIVATE=1 vim'

# Work aliases
alias glist="gcloud compute instances list"
alias glistdp="gcloud compute instances list --filter='labels.goog-dataproc-cluster-name:*'"
alias gfilter="gcloud compute instances list --filter="


function man() {
    LESS_TERMCAP_md=$'\e[01;31m' \
    LESS_TERMCAP_me=$'\e[0m' \
    LESS_TERMCAP_se=$'\e[0m' \
    LESS_TERMCAP_so=$'\e[01;44;33m' \
    LESS_TERMCAP_ue=$'\e[0m' \
    LESS_TERMCAP_us=$'\e[01;32m' \
    command man "$@"
}


function sslinfo()

{
    if [[ "${1}" == "" ]]; then
        echo "Please specify the hostname to check"
    else
        echo | openssl s_client -showcerts -servername ${1} -connect ${1}:443 2>/dev/null | openssl x509 -inform pem -noout -text
    fi
}


function promq()
{
    echo ${1}
    if [[ "${1}" == "" ]]; then
        echo "please specify a prometheus query"
    else
        http "http://prometheus.int.2pth.com:9090/api/v1/query?query=${1}"
    fi
}


function bastionUp()
{
    ssh -O check bastion 2> /dev/null

    retVal=$?

    if [ $retVal -ne 0 ]; then
       echo "Created socks tunnel to bastion..."
       # forward 1080 via socks
       ssh -fNTMn -D 1080 bastion 2> /dev/null
    else
       :
    fi
}


function bastionCheck()
{
    ssh -O check bastion 2> /dev/null
    retVal=$?

    if [ $retVal -eq 0 ]; then
        (lsof -nPi | grep LISTEN | grep 1080) > /dev/null
        retVal=$?
        if [ $retVal -eq 0 ]; then
            echo "bastion is running"
        fi
    elif [ $retVal -ne 0 ]; then
        echo "bastion is not running"
    fi
}


function dfu() {
    (
        cd ~/.dotfiles && git pullff && ./install -q
    )
}


function mcd() {
    mkdir "${1}" && cd "${1}"
}


function up()
{
    local cdir="$(pwd)"
    if [[ "${1}" == "" ]]; then
        cdir="$(dirname "${cdir}")"
    elif ! [[ "${1}" =~ ^[0-9]+$ ]]; then
        echo "Error: argument must be a number"
    elif ! [[ "${1}" -gt "0" ]]; then
        echo "Error: argument must be positive"
    else
        for i in {1..${1}}; do
            local ncdir="$(dirname "${cdir}")"
            if [[ "${cdir}" == "${ncdir}" ]]; then
                break
            else
                cdir="${ncdir}"
            fi
        done
    fi
    cd "${cdir}"
}


# Check if a file contains non-ascii characters
function nonascii() {
    LC_ALL=C grep -n '[^[:print:][:space:]]' ${1}
}


# Serve current directory
function serve() {
    ruby -run -e httpd . -p "${1:-8080}"
}

# Mirror a website
alias mirrorsite='wget -m -k -K -E -e robots=off'

# send a file somewhere
transfer() { if [ $# -eq 0 ]; then echo "No arguments specified. Usage:\necho transfer /tmp/test.md\ncat /tmp/test.md | transfer test.md"; return 1; fi
tmpfile=$( mktemp -t transferXXX ); if tty -s; then basefile=$(basename "$1" | sed -e 's/[^a-zA-Z0-9._-]/-/g'); curl --progress-bar --upload-file "$1" "https://transfer.sh/$basefile" >> $tmpfile; else curl --progress-bar --upload-file "-" "https://transfer.sh/$1" >> $tmpfile ; fi; cat $tmpfile; rm -f $tmpfile; }
