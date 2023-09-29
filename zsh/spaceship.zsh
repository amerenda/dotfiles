SPACESHIP_PROMPT_ORDER=(
  time
  dir           # Current directory section
  git           # Git section (git_branch + git_status)
  docker        # Docker section
  venv          # virtualenv section
  terraform     # Terraform workspace section
  exit_code     # Exit code section
  exec_time
  char          # Prompt character
)

SPACESHIP_RPROMPT_ORDER=()

# time settings
SPACESHIP_TIME_SHOW=false

# dir settings
SPACESHIP_DIR_TRUNC=2
SPACESHIP_DIR_TRUNC_REPO=false

# git settings
SPACESHIP_GIT_SHOW=true
SPACESHIP_GIT_BRANCH_SHOW=true
SPACESHIP_GIT_STATUS_SHOW=true

# xcode settings
SPACESHIP_XCODE_SHOW_LOCAL=true
SPACESHIP_XCODE_SHOW_GLOBAL=true

# go settings
SPACESHIP_GOLANG_SHOW=true

# docker settings
SPACESHIP_DOCKER_SHOW=false
SPACESHIP_DOCKER_SYMBOL=''
#SPACESHIP_DOCKER_SYMBOL='🐳'

# virtualenv settings
SPACESHIP_VENV_SHOW=true

# Execution time settings
SPACESHIP_EXEC_TIME_SHOW=true
SPACESHIP_EXEC_TIME_ELAPSED=3
SPACESHIP_EXEC_TIME_PREFIX=''

# Prompt settings
SPACESHIP_CHAR_SUFFIX=""
SPACESHIP_PROMPT_ADD_NEWLINE=false
SPACESHIP_PROMPT_SEPARATE_LINE=false
SPACESHIP_PROMPT_FIRST_PREFIX_SHOW=false
SPACESHIP_PROMPT_SUFFIXES_SHOW=true
SPACESHIP_VI_MODE_SHOW=false

# Terraform settings
SPACESHIP_TERRAFORM_SYMBOL='🛠️'
SPACESHIP_TERRAFORM_SYMBOL=''
SPACESHIP_TERRAFORM_SHOW=true
