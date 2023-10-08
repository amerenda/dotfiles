SPACESHIP_PROMPT_ORDER=(
  time
  dir           # Current directory section
  git           # Git section (git_branch + git_status)
  docker        # Docker section
  terraform     # Terraform workspace section
  venv          # virtualenv section
  exit_code     # Exit code section
  exec_time     # How long it took commands to run
  char          # Prompt character
)

#
SPACESHIP_PROMPT_ASYNC=true

# time settings
SPACESHIP_TIME_SHOW=false

# dir settings
SPACESHIP_DIR_TRUNC=2
SPACESHIP_DIR_TRUNC_REPO=true

# git settings
SPACESHIP_GIT_SHOW=true
SPACESHIP_GIT_BRANCH_SHOW=true
SPACESHIP_GIT_STATUS_SHOW=true

# go settings
SPACESHIP_GOLANG_SHOW=true

# docker settings
SPACESHIP_DOCKER_SHOW=true
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
SPACESHIP_VI_MODE_SHOW=true

# Terraform settings
SPACESHIP_TERRAFORM_SYMBOL='🛠️ '
SPACESHIP_TERRAFORM_ASYNC=true
SPACESHIP_TERRAFORM_SHOW=true
SPACESHIP_TERRAFORM_COLOR=105
