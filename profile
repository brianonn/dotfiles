# -*- mode: sh; c-basic-offset: 4; tab-width: 4; indent-tabs-mode: nil -*-
#
# ~/.profile: executed by the command interpreter for login shells.
# This file is not read by bash(1), if ~/.bash_profile or ~/.bash_login
# exists.
#
# see /usr/share/doc/bash/examples/startup-files for examples.
# the files are located in the bash-doc package.

# the default umask is set in /etc/profile; for setting the umask
# for ssh logins, install and configure the libpam-umask package.
#umask 022

#echo running the profile

# what's my IP addr
#IPADDR=$(ip -j a|jq -r '.[]|select(.ifname|test("^wl"))|.addr_info[].local')

# Start an ssh agent for the login session
ssh_env="$HOME/.ssh/environment"
start_agent() {
    echo "Initialising new SSH agent..."
    /bin/rm -rf "${ssh_env}"
    /usr/bin/ssh-agent | sed 's/^echo/#echo/' >"${ssh_env}"
    echo succeeded
    /bin/chmod 600 "${ssh_env}"
    . "${ssh_env}" >/dev/null
    /usr/bin/ssh-add
}

# Source SSH settings, if applicable
if [ -f "${ssh_env}" ]; then
    . "${ssh_env}" >/dev/null # sets SSH_AGENT_PID
    /bin/ps -p ${SSH_AGENT_PID} | grep ssh-agent$ >/dev/null || {
        start_agent
    }
else
    start_agent
fi

prepend_path() {
    [ -d "$1" ] && PATH="$1:$PATH" && return 0
    return 1
}

append_path() {
    [ -d "$1" ] && PATH="$PATH:$1" && return 0
    return 1
}

# set PATH so it includes user's private bin if it exists
prepend_path "$HOME/bin"

# altera
ALTERA="$HOME/altera_lite/15.1"
if [ -d "$ALTERA" ]; then
    ALTERAOCLSDKROOT="$ALTERA/hld"
    QSYS_ROOTDIR="$ALTERA/quartus/sopc_builder/bin"
    export ALTERAOCLSDKROOT QSYS_ROOTDIR
    append_path "$QSYS_ROOTDIR"
fi

# Rust / Cargo
append_path "$HOME/.cargo/bin"

# include arm tools for cross compiling arm source for embedded devices
append_path "$HOME/arm/tools:$HOME/arm/tools/gcc-arm-none-eabi-4_7-2013q1/bin"
append_path "/opt/WebStorm-135.547/bin"
KIGITHUB=https://github.com/KiCad
export KIGITHUB

PHP_IDE_CONFIG='servername=localhost'
export PHP_IDE_CONFIG
NODE_PATH=/usr/local/lib/node_modules
export NODE_PATH
NVM_DIR="/home/brian/.nvm"
export NVM_DIR
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh" # This loads nvm

DART_SDK="/usr/lib/dart"
if prepend_path "${DART_SDK}/bin"; then export DART_SDK; fi

LESS="-f -S -X -R -F" && export LESS
LESSOPEN="||$HOME/.lessfilter.sh %s" && export LESSOPEN

export FZF_DEFAULT_OPTS="--multi --height=80% --layout=reverse --info=inline --preview 'if [ -d {} ]; then (tree -C {}) else (bat --style=numbers -- olor=always --line-range :500 {}) fi' --preview-label='[ Preview ]' --border --margin=1 --padding=1 --preview-window=60%,border-double,top --bind 'ctrl-d:abort'"

#DOCKER_HOST="0.0.0.0:4243"  # this depends on DOCKER_OPTS set in /etc/default/docker
DOCKER_HOST="unix:///run/user/$UID/podman/podman.sock"
#export DOCKER_HOST

export PATH
prepend_path $HOME/.nimble/bin

# TODO: only do these next two lines on OS X
prepend_path /usr/local/opt/gnu-tar/libexec/gnubin
export MANPATH="/usr/local/opt/gnu-tar/libexec/gnuman:$MANPATH"

[[ -r "$HOME/.gvm/scripts/gvm" ]] && source "$HOME/.gvm/scripts/gvm"
[[ -r "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"
