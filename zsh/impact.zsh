autoload bashcompinit
bashcompinit

# The next line updates PATH for the Google Cloud SDK.
if [ -f '/Users/alexmerenda/bin/platform/google-cloud-sdk/path.zsh.inc' ]; then source '/Users/alexmerenda/bin/platform/google-cloud-sdk/path.zsh.inc'; fi

# The next line enables shell command completion for gcloud.
if [ -f '/Users/alexmerenda/bin/platform/google-cloud-sdk/completion.zsh.inc' ]; then source '/Users/alexmerenda/bin/platform/google-cloud-sdk/completion.zsh.inc'; fi

#ssh -O check bastion 2> /dev/null
#
#retVal=$?
#
#if [ $retVal -ne 0 ]; then
#   echo "Created socks tunnel to bastion..."
#   # forward 1080 via socks
#   ssh -fNTMn -D 1080 bastion
#else
#   :
#fi
