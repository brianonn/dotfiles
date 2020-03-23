# -*- mode: sh; -*-
# vi: set ft=sh :

# ~/.bashrc: executed by bash(1) for non-login shells.

# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples

# echo in bashrc
# If not running interactively, just exit.
[[ $- != *i* ]] && return

# echo interactive, so continuing bashrc

##
## Below here is useful stuff only when sitting at an
## interactive terminal shell.  Don't put stuff here that you need in
## a remote shell started non-interactively, or shell scripts.
## These should go in the .bash_profile file
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

# always verify history expansion by putting the new command line in the terminal input buffer before execution
shopt -s histverify

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
            MAGENTA=$(tput setaf 5)
            ORANGE=$(tput setaf 172)
            GREEN=$(tput setaf 118)
            YELLOW=$(tput setaf 190)
            RED=$(tput setaf 196)
            WHITE=$(tput setaf 7)
            CYAN=$(tput setaf 14)
            BLUE=$(tput setaf 12)
            LBLUE=$(tput setaf 110)
        else
            MAGENTA=$(tput setaf 5)
            ORANGE=$(tput setaf 3)
            GREEN=$(tput setaf 2)
            RED=$(tput setaf 1)
            WHITE=$(tput setaf 7)
            BLUE=$(tput setaf 12)
            LBLUE=$(tput setaf 6)
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
        MAGENTA="\[\033[35m\]"
        CYAN="\[\033[36m\]"
        WHITE="\[\033[39m\]"
    fi

    if [ $UID = 0 ]; then
      UID_COLOR="$RED"
      P="${UID_COLOR}(root) #"
    else
      UID_COLOR="$BOLD$CYAN"
      P="${UID_COLOR}\$${RESET}"
    fi

    # some unused samples here
    #PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\][\[\033[01;34m\]\w\[\033[00m\]]\$ '
    #PS1="${debian_chroot:+($debian_chroot)}[\[\033[32m\]\w\[\033[00m]\n\[\033[1;36m\]\u\[\033[1;33m\]-> \[\033[00m\]"

    # A two-line colored Bash prompt (PS1) with the VCS branch
    # currently only works with git
    # TODO support other VCS besides git
    #
    function update_user_badge {
        if [[ $TERM_PROGRAM = iTerm.app ]]; then
            iterm2_set_user_var gitStatus "$(get_vcs_project_name)"
        fi
    }
    function which_vcs {
        if git rev-parse --is-inside-work-tree 2>/dev/null 1>&2; then
            echo git
        fi
    }
    function get_vcs_project_name {
        case $( which_vcs ) in
        git)
            echo $(basename $(git rev-parse --show-toplevel))
            ;;
        *) return 1 ;;
        esac
    }
    function get_vcs_branch_name {
        local ref
        case $( which_vcs ) in
        git)
            ref=$( git symbolic-ref HEAD 2> /dev/null )
            [[ ! -z $ref ]] && ref="${ref#refs/heads/}"
            ;;
        *) return 1 ;;
        esac
        echo $ref
    }
    function get_vcs_branch_status {
        case $( which_vcs ) in
        git)
            #$(git status --quiet || echo ' (dirty)')
            echo \ $( git status --porcelain | awk '/^[MAD]/{S=1}/^ [M]/{M=1}/^[?][?]?/{U=1}END{if(S+M+U){printf"("};if(S){printf" staged"};if(M){printf" modified"};if(U){printf" untracked"}if(S+M+U){printf" )"}}' )
            ;;
        *) return 1 ;;
        esac
    }
    function get_vcs_ahead_behind {
        case $( which_vcs ) in
        git)
            $( git for-each-ref --format="%(push:track)" $(git symbolic-ref HEAD) | tr -d '[]' )
            ;;
        *) return 1 ;;
        esac
    }
    function get_vcs_info {
        PS_VCS_CMD='' PS_VCS_BRANCH='' PROMPT_DIRTRIM=6 PS_VCS_L='' PS_VCS_R=''
        PS_VCS_STATUS='' PS_VCS_AHEAD_BEHIND=''
        PS_LINE=$(printf -- '- %.0s' {1..200})
        PS_FILL=${PS_LINE:0:$COLUMNS}
        ref="$(get_vcs_branch_name)" || return
        # continue only if inside a VCS directory
        PROMPT_DIRTRIM=5
        PS_VCS_BRANCH="${ref}"
        PS_VCS_CMD="$( which_vcs ):"
        PS_VCS_L="[ " PS_VCS_R=" ]"
        PS_VCS_STATUS="$( get_vcs_branch_status )"
        PS_VCS_AHEAD_BEHIND="$( get_vcs_ahead_behind )"
        [[ ! -z $PS_VCS_AHEAD_BEHIND ]] && PS_VCS_AHEAD_BEHIND=" ( ${PS_VCS_AHEAD_BEHIND} )"
        update_user_badge
    }
    PROMPT_COMMAND=get_vcs_info
    PS_VCS_COLOR1=${BLUE}
    PS_VCS_COLOR2=${LBLUE}
    PS_VCS_COLOR3=${YELLOW}
    PS_INFO="$GREEN\u@\h$RESET:$BLUE\w"
    PS_INFO=""
    PS_VCS_INFO="${BOLD}${PS_VCS_COLOR1}\${PS_VCS_CMD}\${PS_VCS_L}${PS_VCS_COLOR2}\${PS_VCS_BRANCH}${PS_VCS_COLOR3}\${PS_VCS_STATUS}\${PS_VCS_AHEAD_BEHIND}${PS_VCS_COLOR1}\${PS_VCS_R}${RESET}\n"
    PS_TIME="\[\033[\$((COLUMNS-10))G\] $RED[\t]"
    PS_TIME='\t'
    PS_DATE='\d'
#    export PS1="\${PS_FILL}\[\033[0G\]${PS_INFO} ${PS_VCS_INFO}${PS_TIME}\n${RESET}\$ "
#

## Left and Right sides of the path string
  #L="ÃÂ«" R="ÃÂ»"
  #L="«" R="»"
  #L="<<" R=">>"
  #R= L=
  #L="[" R="]"
  L="[ " R=" ]"


  #export PS1="\n${UID_COLOR}\342\226\210\342\226\210 \u${WHITE} (\h) ${ORANGE}${L}${PS_VCS_INFO}${ORANGE} \w ${R}\n${CYAN}\342\226\210\342\226\210 [\!] ${P}${RESET}${WHITE} "
#  export PS1="\n${UID_COLOR}\342\226\210\342\226\210 ${GREEN}[\@] ${ORANGE}${L}${PS_VCS_INFO}${ORANGE}\w${R}\n${CYAN}\342\226\210\342\226\210 [\!] ${P}${RESET}${WHITE} "
  export PS1="\n${GREEN}${L}${PS_DATE} ${PS_TIME}${R} ${ORANGE}${PS_VCS_INFO}${ORANGE}${L}\w${R}\n${CYAN}[\!] ${P}${RESET}${WHITE} "

  unset P L R UID_COLOR B_UID_COLOR RESET BOLD RED GREEN ORANGE BLUE MAGENTA CYAN WHITE
  unset PS_VCS_BRANCH PS_FILL ref PS_INFO PS_VCS_INFO PS_TIME
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

[[ -s "$HOME/.gvm/scripts/gvm" ]] && source "$HOME/.gvm/scripts/gvm"

export DOCKER_HOST=
export GOPATH=
# EPCTL_PROFILE=/home/brian/go/src/github.com/etherparty/epctl/scripts/bash_profile
#[ -r "$EPCTL_PROFILE" ] && source $EPCTL_PROFILE

if [ -f ~/.git-completion.bash ]; then
  . ~/.git-completion.bash
fi

# Golang Version Manager
# gvm list
# gvm use <version>
[[ -s "$HOME/.gvm/scripts/gvm" ]] && source "$HOME/.gvm/scripts/gvm"
export GOPATH="$HOME/go"
export GOBIN="$GOPATH/bin/$(uname -s)"
mkdir -p $GOBIN
export PATH="$GOBIN:$PATH"

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# added by travis gem
[ -f $HOME/.travis/travis.sh ] && source $HOME/.travis/travis.sh

# The next line updates PATH for the Google Cloud SDK.
if [ -f "$HOME/Library/GoogleCloudSDK/path.bash.inc" ]; then . "$HOME/Library/GoogleCloudSDK/path.bash.inc"; fi

# The next line enables shell command completion for gcloud.
if [ -f "$HOME/Library/GoogleCloudSDK/completion.bash.inc" ]; then . "$HOME/Library/GoogleCloudSDK/completion.bash.inc"; fi

export PATH=$HOME/.gem/ruby/2.6.0/bin:$PATH
