# Use colors in coreutils utilities output
alias ls='ls --color'
alias grep='grep --color'

# ls aliases
#alias ll='ls -lah'
#alias la='ls -A'
#alias l='ls'
#alias l.='ls -d .*'
#alias lr='ls -lahtr'
#alias lt='ls -halt'
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
alias n='terminal_velocity ~/notes'
alias np='terminal_velocity ~/Dropbox/Work/PlaceIQ/Notes'
alias nd='terminal_velocity ~/Dropbox/Work/PlaceIQ/daySummary'
alias na='terminal_velocity ~/Dropbox/Documentation/Notes'
alias mkdir="mkdir -pv"
alias ssh="ssh -A"
alias myip="curl http://ipecho.net/plain; echo"
alias clip="xclip -selection c"
alias tl="clear && task list"
alias tlw="clear && task list +placeiq"
alias tlp="clear && task list +personal"
alias tkill="tmux kill-session"
alias fsize="du -sh ./* | sort -h"
alias dotsize="du -sh ./.* | sort -h"
alias pacsearch="pacman -Ss"

# calendar aliass
alias gcal='gcalcli --configFolder=~/.gcalcli_placeiq 2>/dev/null'
alias gcalw='gcalcli --configFolder=~/.gcalcli_placeiq 2>/dev/null'
alias gcalp='gcalcli --configFolder=~/.gcalcli_personal 2>/dev/null'

# Python aliases
alias ip2='ipython2'
alias ip3='ipython'

# Git aliases
alias subup="git submodule foreach git pull origin master"

# Work aliases
alias gfs='snakebite -n gandalf-nn.placeiq.net'
alias pfs='snakebite -n phoenix-nn.placeiq.net'

# Docker aliases (Is this the best way to do this??)
alias influxd='docker exec -it influxd influxd'


# Get current number of commits on current branch, or another branch, as compared to master.
function gcommits()
{
    if [[ "${1}" == "" ]]; then
        git rev-list master..$(git rev-parse --abbrev-ref HEAD) | wc -l
    else
        git rev-list master..${1} | wc -l
    fi
}

# Update dotfiles
function dfu() {
    (
        cd ~/.dotfiles && git pullff && ./install -q
    )
}


# Create a directory and cd into it
function mcd() {
    mkdir "${1}" && cd "${1}"
}

# Jump to directory containing file
function jump() {
    cd "$(dirname ${1})"
}

# Go up [n] directories
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

# Execute a command in a specific directory
function in() {
    (
        cd ${1} && shift && ${@}
    )
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

transfer() { if [ $# -eq 0 ]; then echo "No arguments specified. Usage:\necho transfer /tmp/test.md\ncat /tmp/test.md | transfer test.md"; return 1; fi
tmpfile=$( mktemp -t transferXXX ); if tty -s; then basefile=$(basename "$1" | sed -e 's/[^a-zA-Z0-9._-]/-/g'); curl --progress-bar --upload-file "$1" "https://transfer.sh/$basefile" >> $tmpfile; else curl --progress-bar --upload-file "-" "https://transfer.sh/$1" >> $tmpfile ; fi; cat $tmpfile; rm -f $tmpfile; }
