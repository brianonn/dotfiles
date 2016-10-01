#!/bin/sh

SAVEDIR="$HOME/.dotfiles_orig"

echo "This will install symlinks to your dotfiles"
echo "Any existing dotfiles will be saved in $SAVEDIR"
echo ""
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
            echo mv "$dotfile" "$SAVEDIR"
            echo ln -s "$path" "$dotfile"
        fi
    fi
done
