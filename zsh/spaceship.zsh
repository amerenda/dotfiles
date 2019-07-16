SPACESHIP_PROMPT_ORDER=(
  dir           # Current directory section
  git           # Git section (git_branch + git_status)
#  xcode         # Xcode section
#  golang        # Go section
#  docker        # Docker section
#  venv          # virtualenv section
#  kubecontext   # Kubectl context section
#  terraform     # Terraform workspace section
#  jobs          # Background jobs indicator
#  exit_code     # Exit code section
  char          # Prompt character
)


SPACESHIP_PROMPT_ADD_NEWLINE=false
SPACESHIP_PROMPT_SEPARATE_LINE=false
SPACESHIP_PROMPT_FIRST_PREFIX_SHOW=false
SPACESHIP_PROMPT_SUFFIXES_SHOW=true

SPACESHIP_KUBECONTEXT_SHOW=false

SPACESHIP_VI_MODE_SHOW=false

#SPACESHIP_GIT_SHOW=true
#SPACESHIP_GIT_PREFIX=off
#SPACESHIP_GIT_SUFFIX='git'
#SPACESHIP_GIT_SYMBOL='g'

SPACESHIP_GIT_BRANCH_SHOW=true
SPACESHIP_GIT_BRANCH_PREFIX=$SPACESHIP_GIT_SYMBOL

SPACESHIP_GIT_STATUS_SHOW=true

