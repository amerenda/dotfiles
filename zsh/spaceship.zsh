SPACESHIP_PROMPT_ORDER=(
  time
  dir           # Current directory section
  git           # Git section (git_branch + git_status)
  xcode         # Xcode section
  golang        # Go section
  docker        # Docker section
  venv          # virtualenv section
  kubecontext   # Kubectl context section
  terraform     # Terraform workspace section
  jobs          # Background jobs indicator
  exit_code     # Exit code section
  exec_time
  char          # Prompt character
)

SPACESHIP_RPROMPT_ORDER=()

# time settings
SPACESHIP_TIME_SHOW=false

# dir settings
SPACESHIP_DIR_TRUNC=2

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
SPACESHIP_DOCKER_SHOW=true

# virtualenv settings
SPACESHIP_VENV_SHOW=true

# kubecontext settings
SPACESHIP_KUBECONTEXT_SHOW=false
SPACESHIP_KUBECONTEXT_SYMBOL=$'\u2388 '
SPACESHIP_KUBECONTEXT_SUFFIX=' '
SPACESHIP_KUBECONTEXT_COLOR_GROUPS=(
  # red if namespace is "kube-system"
  red    '\(kube-system)$'
  # else, green if "dev-01" is anywhere in the context or namespace
  green  dev
  # else, red if context name ends with ".k8s.local" _and_ namespace is "system"
  red    '\.k8s\.local \(system)$'
  # else, yellow if the entire content is "test-" followed by digits, and no namespace is displayed
  yellow '^test-[0-9]+$'
)


# terraform settings
SPACESHIP_TERRAFORM_SHOW=true

# jobs settings
SPACESHIP_JOBS_SHOW=true

# exit code settings
SPACESHIP_EXIT_CODE_SHOW=false

# Execution time settings
SPACESHIP_EXEC_TIME_SHOW=true
SPACESHIP_EXEC_TIME_ELAPSED=3
SPACESHIP_EXEC_TIME_PREFIX=''

SPACESHIP_PROMPT_ADD_NEWLINE=false
SPACESHIP_PROMPT_SEPARATE_LINE=false
SPACESHIP_PROMPT_FIRST_PREFIX_SHOW=false
SPACESHIP_PROMPT_SUFFIXES_SHOW=true
SPACESHIP_VI_MODE_SHOW=false
