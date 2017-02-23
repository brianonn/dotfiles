#!/bin/sh


##
## ALL THIS COULD PROBABLY BE DONE
## BETTER WITH PUPPET
##

SAVEDIR="$HOME/.dotfiles_orig"

RM=/bin/rm
GIT=/usr/bin/git

[[ ! -x "$GIT" ]] && echo "run 'sudo apt-get install git' first"

echo "This will bootstrap a new system environment, install necessary files and tools"
echo "and create symlinks to your dotfiles in the home directory of this user"
echo
echo "Any existing dotfiles will be saved in $SAVEDIR"
echo
echo -n "Enter Y to continue, or N to exit this script: "
read ans
case "$ans" in [yY]*) ;; *) exit 1 ;; esac

dir="readlink -f `dirname $0`"
dir=`eval $dir`

# templates
for path in $dir/*.template; do
    cp -pf "$path" `basename "$path" ".template"`
done

#make symlinks
for path in $dir/*; do
    filename=`basename "$path"`
    if [ "$filename" = "bootstrap.sh" ]; then
        continue;
    else
        dotfile="$HOME/.$filename"
        if [ -e "$dotfile" ]; then
            [ -e "$SAVEDIR" ] || mkdir -p "$SAVEDIR"
            mv "$dotfile" "$SAVEDIR"
        fi
        ln -s "$path" "$dotfile"
    fi
done

## setup eslint


## set up yasnippets for emacs
GITHUB="git@github.com:brianonn/yasnippet-snippets.git"
YASSNIPPETDIR="~/.emacs.d/snippets"
$RM -fr $YASSNIPPETDIR
git clone $GITHUB $YASSNIPPETDIR
