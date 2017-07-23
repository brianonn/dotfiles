#!/bin/sh

# bootstrap your dotfiles

SAVEDIR="$HOME/.dotfiles_orig"
EXCLUDES= \
        "*.template" \
        "bootstrap.sh"

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
for infile in $dir/*.template; do
    outfile=$(basename "$infile" ".template")
    $RM -f "$outfile"
    # TODO: read the username and email from the user
    NAME="Joe Smith"
    EMAIL="joe@example.com"
    sed < "$infile" > "$outfile" \
        -e 's/\${NAME}/'$NAME'/' \
        -e 's/\${EMAIL}/'$EMAIL'/'
done

#make symlinks
for path in $dir/*; do
    filename=`basename "$path"`
    case "$filename" in
    *.template|bootstrap.sh)
        continue
        ;;
    *)
        dotfile="$HOME/.$filename"
        if [ -e "$dotfile" ]; then
            [ -e "$SAVEDIR" ] || mkdir -p "$SAVEDIR"
            mv "$dotfile" "$SAVEDIR"
        fi
        ln -s "$path" "$dotfile"
        ;;
    esac
done

## setup eslint

## setup vim pathogen modules
#
VIMBUNDLEDIR="$HOME/.vim/bundle"
[[ ! -d "$VIMBUNDLEDIR" ]] && mkdir "$VIMBUNDLEDIR"
git submodule init
git submodule update

## set up yasnippets for emacs
#
GITHUB="https://github.com/brianonn/yasnippet-snippets.git"
YASSNIPPETDIR="~/.emacs.d/snippets"
$RM -fr $YASSNIPPETDIR
git clone $GITHUB $YASSNIPPETDIR

## setup local nemo actions
mkdir -p ~/.local/share/nemo/actions 
/bin/cp -pr --remove-destination local/share/nemo/actions/* ~/.local/share/nemo/actions/
