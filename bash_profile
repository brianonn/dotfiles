# -*- mode: sh; c-basic-offset: 4; tab-width: 4; indent-tabs-mode: nil -*-
# vi: set ft=sh shiftwidth=4 tabstop=4 expandtab :
#
# File: ~/.bash_profile
#
# When: a bash login shell is started, it will search in order for
#       .bash_profile, then .bash_login and finally .profile.
#       A bash login shell will NEVER source .bashrc on it's own.
#       This .bash_profile is a good place to put bash specific login startup.
#       Then we must source .profile and .bashrc directly here.
#       .bashrc will be skipped for non-interactive shells, such as 'ssh host git status'
#
# ATTENTION:
#       put all PATH setup and environment variables in $HOME/.profile so
#       a /bin/sh (even a remote /bin/sh) will get it too
#
#       We source $HOME/.profile, if available, to get all the environment
#       variables that can be used across all shells
#
##

# at first login, remove any dangerous rm and del commands from the history file
# I probably don't want to run them again
#
_histfile="$HOME/.bash_history"
if [ -r "$_histfile" ]; then
    _temphist="/tmp/temphist.$$"
    ( umask 077 && grep --color=never -E -v '^(rm(dir)?|del|/bin/rm(dir)?|/usr/bin/rm(dir)?)[ \t]+' "$_histfile" > "$_temphist" )
    mv "$_temphist" "$_histfile"
fi


# always source the .profile here to load all POSIX shell compatible settings
profile="$HOME/.profile"
if [[ -r "$profile" ]]; then
      source "$profile"
fi

# source .bashrc only for interactive shells
case $- in *i*)
    [[ -r $HOME/.bashrc ]] && source $HOME/.bashrc ;;
esac

## End
