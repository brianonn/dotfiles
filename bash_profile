# File: ~/.bash_profile

# source ~/.profile, if available
#if [[ -r ~/.profile ]]; then
#      . ~/.profile
#fi

SSH_ENV="$HOME/.ssh/environment"

function start_agent {
    echo "Initialising new SSH agent..."
    /bin/rm -rf "${SSH_ENV}"
    /usr/bin/ssh-agent | sed 's/^echo/#echo/' > "${SSH_ENV}"
    echo succeeded
    chmod 600 "${SSH_ENV}"
    . "${SSH_ENV}" > /dev/null
    /usr/bin/ssh-add;
}

# Source SSH settings, if applicable

if [ -f "${SSH_ENV}" ]; then
    . "${SSH_ENV}" > /dev/null
    # does this work under cygwin ?
    kill -0 "${SSH_AGENT_PID}" 2>-
    ps -ef | grep ${SSH_AGENT_PID} | grep ssh-agent$ > /dev/null || {
        start_agent;
    }
else
    start_agent;
fi

# are we interactive, source .bashrc
case $- in *i*) source $HOME/.bashrc;; esac 

