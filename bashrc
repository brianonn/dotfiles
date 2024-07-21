# -*- mode: sh; -*-
# vi: set ft=sh :

# ~/.bashrc: executed by bash(1) for non-login shells.

# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples

# echo running the bashrc

# If not running interactively, just exit.
[[ $- != *i* ]] && return

# [[ $TERM = alacritty ]] && exec wezterm start -e /bin/bash

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

    # A two-line colored Bash prompt (PS1) with the VCS branch
    # currently only works with git
    # TODO support other VCS besides git
    #
    git=$(command -v git)
    function update_user_badge {
        if [[ $TERM_PROGRAM = iTerm.app ]]; then
            iterm2_set_user_var gitStatus "$(get_vcs_project_name)"
        fi
    }
    function which_vcs {
        if ${git} rev-parse --is-inside-work-tree 2>/dev/null 1>&2; then
            echo git
        fi
    }
    function get_vcs_project_name {
        case $( which_vcs ) in
        git)
            vcs_top_level=$(${git} rev-parse --show-toplevel)
            echo "${vcs_top_level##*/}"
            ;;
        *) return 1 ;;
        esac
    }
    function get_vcs_branch_name {
        local ref
        case $( which_vcs ) in
        git)
            ref=$( ${git} symbolic-ref HEAD 2> /dev/null )
            [[ ! -z $ref ]] && ref="${ref#refs/heads/}"
            ;;
        *) return 1 ;;
        esac
        echo "$ref"
    }
    function get_vcs_branch_status {
        case $( which_vcs ) in
        git)
            # ${git} status >/dev/null 2>&1 || echo ' (dirty)'
            echo \ $( ${git} status --porcelain | awk '/^[MAD]/{S=1}/^ [M]/{M=1}/^[?][?]?/{U=1}END{if(S+M+U){printf"("};if(S){printf" staged"};if(M){printf" modified"};if(U){printf" untracked"}if(S+M+U){printf" )"}}' )
            ;;
        *) return 1 ;;
        esac
    }
    function get_vcs_ahead_behind {
        case $( which_vcs ) in
        git)
            echo $( ${git} for-each-ref --format="%(push:track)" $(${git} symbolic-ref HEAD) | tr -d '[]' )
            ;;
        *) return 1 ;;
        esac
    }

    PS_LINE=$(printf -- '- %.0s' {1..200})
    PS_FILL=${PS_LINE:0:$COLUMNS}

    function get_vcs_info {
        PS_VCS_CMD='' PS_VCS_BRANCH='' PROMPT_DIRTRIM=6 PS_VCS_L='' PS_VCS_R=''
        PS_VCS_STATUS='' PS_VCS_AHEAD_BEHIND=''
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

pathlist=""
for path in \
  "$HOME/bin" \
  "/usr/local/bin" \
  "/opt/homebrew/bin" \
  "/use/local/homebrew/bin" \
  "/opt/homebrew/opt/openjdk/bin" \
  "$HOME/google-cloud-sdk/bin"
do
    [[ -d "$path" ]] && pathlist=${pathlist}:${path}
done
export PATH="${pathlist}:$PATH"

# Alias definitions.
# put all your additions into a separate file like
# ~/.bash_aliases, instead of adding them here directly.

[[ -r ~/.bash_aliases ]] && source ~/.bash_aliases

# enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
if [ -r /etc/bash_completion ] && ! shopt -oq posix; then
    . /etc/bash_completion
fi

[[ $(command -v starship 2>/dev/null) ]] && eval "$(starship init bash)"
[[ $(command -v zoxide 2>/dev/null) ]] && eval "$(zoxide init --cmd cd bash)"

export DOCKER_HOST=
export GOPATH=
# EPCTL_PROFILE=${HOME}/go/src/github.com/etherparty/epctl/scripts/bash_profile
#[ -r "$EPCTL_PROFILE" ] && source $EPCTL_PROFILE

if [ -r ~/.git-completion.bash ]; then
  . ~/.git-completion.bash
fi

if [ -r ~/.kubie-completion.bash ]; then
  . ~/.kubie-completion.bash
fi

# Golang Version Manager
# gvm list
# gvm use <version>
[[ -s "$HOME/.gvm/scripts/gvm" ]] && source "$HOME/.gvm/scripts/gvm"
[[ -d "/Volumes/Go" ]] && export GOPATH="/Volumes/Go" || export GOPATH="$HOME/go"
#export GOBIN="$GOPATH/bin/$(uname -s)"
export GOBIN="$GOPATH/bin"
export PATH="$GOBIN:$PATH"

# Node version manager
export NVM_DIR="$HOME/.nvm"
[[ -r "$NVM_DIR/nvm.sh" ]] && source "$NVM_DIR/nvm.sh"  # This loads nvm
[[ -r "$NVM_DIR/bash_completion" ]] && source "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# added by travis gem
[[ -r $HOME/.travis/travis.sh ]] && source $HOME/.travis/travis.sh

#source ~/Projects/MBI/microbiome-insights/devops/scripts/00-shell-env.sh

# The next line updates PATH for the Google Cloud SDK.
[[ -r "${HOME}/google-cloud-sdk/path.bash.inc" ]] && source "${HOME}/google-cloud-sdk/path.bash.inc"

# The next line enables shell command completion for gcloud.
[[ -r "${HOME}/google-cloud-sdk/completion.bash.inc" ]] && source "${HOME}/google-cloud-sdk/completion.bash.inc"

[[ -d $HOME/.gem/ruby/2.6.0/bin ]] && export PATH=$HOME/.gem/ruby/2.6.0/bin:$PATH

LOCATE_PATH=
for i in ${HOME}/.mlocate/*.db; do
    LOCATE_PATH="$LOCATE_PATH:$i"
done
export LOCATE_PATH
findroms() {  mlocate -i --regex "roms.*$1"; }

# 8 colors for jq(1)
# null:false:true:numbers:strings:arrays:objects:keys
export JQ_COLORS="1;36:0;36:0;36:0;33:0;32:0;37:0;37:0;37"

# Haskell GHC compiler - ghcup-env
[[ -r "$HOME/.ghcup/env" ]] && source "$HOME/.ghcup/env"

# bun
[[ -d $HOME/.bun ]] && { export BUN_INSTALL="$HOME/.bun"; export PATH=$BUN_INSTALL/bin:$PATH; }

export GPG_TTY=$(tty)
type bat 2>/dev/null >/dev/null && export BAT_THEME='Catppuccin Mocha'

[[ -d "$HOME/.local/bin" ]] && export PATH=$HOME/.local/bin:$PATH

[[ -r ~/.fzf.bash ]] && source ~/.fzf.bash
#[[ -r /usr/share/fzf/fzf-extras.bash ]] && source /usr/share/fzf/fzf-extras.bash
#[[ -r /usr/share/fzf-tab-completion/bash/fzf-bash-completion.sh ]] && source /usr/share/fzf-tab-completion/bash/fzf-bash-completion.sh
#bind -x '"\t": fzf_bash_completion'

export AWS_PROFILE="cns-enforcer-dev"
[[ -z "$APO_ROOT" ]] && export APO_ROOT="$HOME/apomux"
root_path=/Users/bonn/Repos/testing
export PYTHONPATH="$root_path"

GCLOUD="/Users/bonn/google-cloud-sdk"
# The next line updates PATH for the Google Cloud SDK.
if [ -r "$GCLOUD/path.bash.inc" ]; then . "$GCLOUD/path.bash.inc"; fi
# The next line enables shell command completion for gcloud.
if [ -r "$GCLOUD/completion.bash.inc" ]; then . "$GCLOUD/completion.bash.inc" ; fi
export PS1="$ "

#eval "$(starship init bash)"

[[ -r "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"
[[ -d /opt/homebrew/opt/openjdk ]] && export JAVA_HOME="/opt/homebrew/opt/openjdk"

[[ -r "/opt/homebrew/etc/profile.d/bash_completion.sh" ]] && source "/opt/homebrew/etc/profile.d/bash_completion.sh"
[[ -r /usr/local/etc/bash_completion ]] && source /usr/local/etc/bash_completion

# MacOS
[[ -r "${HOME}/.iterm2_shell_integration.bash" ]] && source "${HOME}/.iterm2_shell_integration.bash"

source <(kubectl completion bash)
alias k=kubectl
complete -o default -F __start_kubectl k

## keep this line near the end
[[ -r $HOME/.secrets/env ]] && source $HOME/.secrets/env
[[ -r $HOME/.bash_secrets ]] && source $HOME/.bash_secrets
