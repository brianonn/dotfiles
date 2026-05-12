#!/usr/bin/env bash

#
# set all bash shell options here
#
set -o noclobber

# don't put duplicate lines in the history. See bash(1) for more options
export HISTCONTROL=$HISTCONTROL${HISTCONTROL+:}ignoredups

# don't overwrite GNU Midnight Commander's setting of `ignorespace'.
# ... or force ignoredups and ignorespace
export HISTCONTROL=ignoreboth:erasedups
export HISTIGNORE="??"

# append to the history file, don't overwrite it
shopt -s histappend

# always verify history expansion by putting the new command line in the terminal input buffer before execution
shopt -s histverify

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

