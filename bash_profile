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

##
## Put bash specific first login commands and settings here
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
