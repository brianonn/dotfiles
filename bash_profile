# -*- mode: sh; c-basic-offset: 4; tab-width: 4; indent-tabs-mode: nil -*-
# vi: set ft=sh shiftwidth=4 tabstop=4 expandtab :

# File: ~/.bash_profile

# When: this file is sourced for all login shells.  If it exists,
#      then .profile is not run, so we must source .profile here to
#      get the shell environment variables

# ATTENTION:
#      put all environment variables in $HOME/.profile so
#      a /bin/sh (even a remote /bin/sh) will get it too

# source $HOME/.profile, if available, to get all the environment
# variables that can be used across all shells

# echo running the bash_profile

profile="$HOME/.profile"
if [[ -r "$profile" ]]; then
      source "$profile"
fi

# at login, remove dangerous rm and del from old history
#
_histfile="$HOME/.bash_history"
if [ -r "$_histfile" ]; then
    _temphist="/tmp/temphist.$$"
    ( umask 077 && grep --color=never -E -v '^(rm(dir)?|del|/bin/rm(dir)?|/usr/bin/rm(dir)?)[ \t]+' "$_histfile" > "$_temphist" )
    mv "$_temphist" "$_histfile"
fi

# are we interactive, source .bashrc
case $- in *i*) source $HOME/.bashrc;; esac

## End
