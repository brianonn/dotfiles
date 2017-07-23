# -*- mode: sh; c-basic-offset: 4; tab-width: 4; indent-tabs-mode: nil -*-
# ~/.profile: executed by the command interpreter for login shells.
# This file is not read by bash(1), if ~/.bash_profile or ~/.bash_login
# exists.
# see /usr/share/doc/bash/examples/startup-files for examples.
# the files are located in the bash-doc package.

# the default umask is set in /etc/profile; for setting the umask
# for ssh logins, install and configure the libpam-umask package.
#umask 022

#echo I am the profile

# Start an ssh agent for the login session
ssh_env="$HOME/.ssh/environment"
start_agent () {
    echo "Initialising new SSH agent..."
    /bin/rm -rf "${ssh_env}"
    /usr/bin/ssh-agent | sed 's/^echo/#echo/' > "${ssh_env}"
    echo succeeded
    /bin/chmod 600 "${ssh_env}"
    . "${ssh_env}" > /dev/null
    /usr/bin/ssh-add;
}

# Source SSH settings, if applicable
if [ -f "${ssh_env}" ]; then
    . "${ssh_env}" > /dev/null  # sets SSH_AGENT_PID
    /bin/ps -p ${SSH_AGENT_PID} | grep ssh-agent$ > /dev/null || {
        start_agent;
    }
else
    start_agent;
fi

prepend_path()
{
    [ -d "$1" ] && PATH="$1:$PATH" && return 0
    return 1
}

append_path()
{
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


LOCATE_PATH=
for i in /home/brian/.mlocate/*.db; do
    LOCATE_PATH="$LOCATE_PATH:$i"
done
export LOCATE_PATH
findroms() {  mlocate -i --regex "roms.*$1"; }

# include arm tools for cross compiling arm source for embedded devices
PATH="$PATH":$HOME/arm/tools:$HOME/arm/tools/gcc-arm-none-eabi-4_7-2013q1/bin
PATH="$PATH":/opt/WebStorm-135.547/bin
KIGITHUB=https://github.com/KiCad; export KIGITHUB

PHP_IDE_CONFIG='servername=localhost' && export PHP_IDE_CONFIG
NODE_PATH=/usr/local/lib/node_modules && export NODE_PATH
NVM_DIR="/home/brian/.nvm" && export NVM_DIR
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"  # This loads nvm

DART_SDK="/usr/lib/dart" && export DART_SDK
[ -d $DART_SDK ] && PATH="${DART_SDK}/bin:$PATH"

LESS="-f -S -X -R -F" && export LESS
LESSOPEN="||~/.lessfilter %s" && export LESSOPEN

DOCKER_HOST="0.0.0.0:4243"  # this depends on DOCKER_OPTS set in /etc/default/docker
export DOCKER_HOST

export PATH