SPACESHIP_PROMPT_ORDER=(
#  time
  dir           # Current directory section
  git           # Git section (git_branch + git_status)
  xcode         # Xcode section
  golang        # Go section
  docker        # Docker section
  venv          # virtualenv section
#  kubecontext   # Kubectl context section
  terraform     # Terraform workspace section
  jobs          # Background jobs indicator
  exit_code     # Exit code section
#  exec_time
  char          # Prompt character
)
#SPACESHIP_RPROMPT_ORDER=()

# Execution Time Settings
SPACESHIP_EXEC_TIME_ELAPSED=2

# Prompt View Settings
SPACESHIP_PROMPT_ADD_NEWLINE=false
SPACESHIP_PROMPT_SEPARATE_LINE=false
SPACESHIP_PROMPT_FIRST_PREFIX_SHOW=false
SPACESHIP_PROMPT_SUFFIXES_SHOW=true
SPACESHIP_VI_MODE_SHOW=false

# Kube settings
SPACESHIP_KUBECONTEXT_SHOW=true
SPACESHIP_KUBECONTEXT_PREFIX=''
SPACESHIP_KUBECONTEXT_SUFFIX=''
SPACESHIP_KUBECONTEXT_NAMESPACE_SHOW=false
SPACESHIP_KUBECONTEXT_SYMBOL=$'\u2388 '

# Git Settings
SPACESHIP_GIT_SHOW=true
SPACESHIP_GIT_BRANCH_SHOW=true
SPACESHIP_GIT_STATUS_SHOW=true

