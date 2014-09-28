# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples

# If not running interactively, don't do anything
[[ $- != *i* ]] && return 

##
## Everything else is useful stuff when sitting at an 
## interactive terminal shell.  Don't push stuff here that you need in 
## a remote rsh(1) or ssh shell 
##

set -o noclobber

# don't put duplicate lines in the history. See bash(1) for more options
# don't overwrite GNU Midnight Commander's setting of `ignorespace'.
export HISTCONTROL=$HISTCONTROL${HISTCONTROL+:}ignoredups
# ... or force ignoredups and ignorespace
export HISTCONTROL=ignoreboth:erasedups
export HISTIGNORE="??"

# append to the history file, don't overwrite it
shopt -s histappend

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# make less more friendly for non-text input files, see lesspipe(1)
#[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# set variable identifying the chroot you work in (used in the prompt below)
if [ -z "$debian_chroot" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

#PROMPT_COMMAND='PS1="\[\033[0;33m\][\!]\`if [[ \$? = "0" ]]; then echo "\\[\\033[32m\\]"; else echo "\\[\\033[31m\\]"; fi\`[\u.\h: \`if [[ `pwd|wc -c|tr -d " "` > 18 ]]; then echo "\\W"; else echo "\\w"; fi\`]\$\[\033[0m\] "; echo -ne "\033]0;`hostname -s`:`pwd`\007"'

# set to no to turn off the fancy color prompt
color_prompt=yes

if [ "$color_prompt" = yes ]; then

    if tput setaf 1 &> /dev/null; then
        tput sgr0
        if [[ $(tput colors) -ge 256 ]] 2>/dev/null; then
            MAGENTA=$(tput setaf 9)
            ORANGE=$(tput setaf 172)
            GREEN=$(tput setaf 190)
            PURPLE=$(tput setaf 141)
            WHITE=$(tput setaf 256)
        else
            MAGENTA=$(tput setaf 5)
            ORANGE=$(tput setaf 4)
            GREEN=$(tput setaf 2)
            PURPLE=$(tput setaf 1)
            WHITE=$(tput setaf 7)
        fi
        BOLD=$(tput bold)
        RESET=$(tput sgr0)
    else
        RESET="\[\033[0m\]"
        BOLD="\[\033[1m\]"
        RED="\[\033[31m\]"
        GREEN="\[\033[32m\]"
        ORANGE="\[\033[33m\]"
        BLUE="\[\033[34m\]"
        MAG="\[\033[35m\]"
        CYAN="\[\033[36m\]"
        WHT="\[\033[39m\]"
    fi
     
    if [ $UID = 0 ]; then
      UID_COLOR="$RED"
      P="#"
    else
      UID_COLOR="$CYAN"
      P="$"
    fi

    # some unused samples here
    #PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\][\[\033[01;34m\]\w\[\033[00m\]]\$ '
    #PS1="${debian_chroot:+($debian_chroot)}[\[\033[32m\]\w\[\033[00m]\n\[\033[1;36m\]\u\[\033[1;33m\]-> \[\033[00m\]"

    # A two-line colored Bash prompt (PS1) with Git branch 


     
    export PROMPT_DIRTRIM=6

    PS_LINE=$(printf -- '- %.0s' {1..200})
    function parse_git_branch {
        PS_GIT_BRANCH='' PROMPT_DIRTRIM=6
        PS_FILL=${PS_LINE:0:$COLUMNS}
        ref=$(git symbolic-ref HEAD 2> /dev/null) || return
        PROMPT_DIRTRIM=5
        PS_GIT_BRANCH="git:${ref#refs/heads/} "
    }
    PROMPT_COMMAND=parse_git_branch
    PS_INFO="$GREEN\u@\h$RESET:$BLUE\w" 
    PS_INFO=""
    PS_GIT="$BOLD$ORANGE\$PS_GIT_BRANCH$RESET"
    PS_TIME="\[\033[\$((COLUMNS-10))G\] $RED[\t]"
#    export PS1="\${PS_FILL}\[\033[0G\]${PS_INFO} ${PS_GIT}${PS_TIME}\n${RESET}\$ "
#

  #L="«" R="»"
  L="[" R="]"
  #R= L= 

  #export PS1="\n${UID_COLOR}\342\226\210\342\226\210 \u${WHT} (\h) ${ORANGE}${L}${PS_GIT}${ORANGE} \w ${R}\n${CYAN}\342\226\210\342\226\210 [\!] ${P}${RESET}${WHT} "
  export PS1="\n${UID_COLOR}\342\226\210\342\226\210 ${GREEN}[\@] ${ORANGE}${L}${PS_GIT}${ORANGE}\w${R}\n${CYAN}\342\226\210\342\226\210 [\!] ${P}${RESET}${WHT} "
   
  unset P L R UID_COLOR B_UID_COLOR RESET BOLD RED GREEN ORANGE BLUE MAG CYAN WHT
  unset PS_GIT_BRANCH PS_FILL ref PS_INFO PS_GIT PS_TIME
else
    # no color prompt, just plain
    PS1='${debian_chroot:+($debian_chroot)}\u@\h[\w]\$ '
fi
unset color_prompt force_color_prompt

# If this is an xterm set the title to user@host:dir
case "$TERM" in
xterm*|rxvt*)
    PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
    ;;
*)
    ;;
esac

# Alias definitions.
# You may want to put all your additions into a separate file like
# ~/.bash_aliases, instead of adding them here directly.
# See /usr/share/doc/bash-doc/examples in the bash-doc package.

if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

# enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
if [ -f /etc/bash_completion ] && ! shopt -oq posix; then
    . /etc/bash_completion
fi

LOCATE_PATH=
for i in /home/brian/.mlocate/*.db; do 
    LOCATE_PATH="$LOCATE_PATH:$i"
done
export LOCATE_PATH
function findroms() {  mlocate -i --regex "roms.*$1"; }

# include arm tools for cross compiling arm source for embedded devices
export PATH="$PATH":$HOME/arm/tools:$HOME/arm/tools/gcc-arm-none-eabi-4_7-2013q1/bin
export PATH="$PATH":/opt/WebStorm-135.547/bin
export KIGITHUB=https://github.com/KiCad

export PHP_IDE_CONFIG='servername=localhost'
