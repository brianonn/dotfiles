#!/bin/bash

# bootstrap your dotfiles

SAVEDIR="$HOME/.dotfiles_orig"
SYMLINK_EXCLUDES="local | *.template | bootstrap.sh | TODO | *.md"

machine="UNKNOWN:$(uname -s)"
case "$machine" in
    *:Linux*)   machine=Linux ;;
    *:Darwin*)  machine=Mac ;;
    *CYGWIN*)   machine=Cygwin ;;
    *MINGW*)    machine=MinGw ;;
    *)          ;;
esac

# we are bootstrapping , let's not rely on which(1), it's not always there
find_on_path() {
    for path in ${PATH//:/ } ; do
        if test -x $path/$1; then
            echo $path/$1
            return 0
        fi
    done
    return ""
}

get_input() {
    prompt="$1"
    echo -n "$prompt : " > /dev/tty
    read ans
    echo "$ans"
}

install_git() {
    case $machine in
      Linux)
        sudo apt-get update -y
        sudo apt-get install git
        ;;
      Mac)
        brew install git
        ;;
    esac
}

# get the users password credentials reset for later sudo
N="
"
sudo -k
sudo -v -p "We need your password for later sudo$N[sudo %U] password for %u@%H: "

RM="$(find_on_path rm)"
GIT="$(find_on_path git)"

if [ ! -x "$GIT" ]; then
  echo "git is not found."
  case $machine in
    Linux)
      echo "run 'sudo apt-get install git' first"
      ;;
    Mac)
      echo 'run: /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"'
      echo 'then run: brew install git'
      ;;
    esac
  exit 1
fi

echo "This will bootstrap a new system environment, install necessary files and tools"
echo "and create symlinks to your dotfiles in the home directory of this user"
echo
echo "Any existing dotfiles will be saved in $SAVEDIR"
echo
echo -n "Enter Y to continue, or N to exit this script: "
read ans
case "$ans" in [yY]*) ;; *) exit 1 ;; esac

LOCALDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
# templates
for infile in $LOCALDIR/*.template; do
    [ ! -e "$infile" ] && continue
    outfile=$(basename "$infile" ".template")
    $RM -f "$outfile"
    # TODO: read the username and email from the user
    NAME=$(get_input "Enter your fullname (for git commits)" )
    EMAIL=$(get_input "Enter your email (for git commits)" )
    sed < "$infile" > "$outfile" \
        -e 's/\${NAME}/'$NAME'/' \
        -e 's/\${EMAIL}/'$EMAIL'/'
done

#make symlinks
[ ! -e "$SAVEDIR" ] && mkdir -p "$SAVEDIR"
for path in $LOCALDIR/*; do
    filename=`basename "$path"`
    case "$filename" in
    *~|*.tmp|local|TODO|*.md|bootstrap.sh)
        echo "Skipping excluded file or directory: $filename"
        continue
        ;;
    *)
        dotfile="$HOME/.$filename"
        if [ ! -L "$dotfile" ] ; then
            mv "$dotfile" "$SAVEDIR"
            ln -snf "$path" "$dotfile"
        else
            echo "skipping already linked file: $dotfile"
        fi
        ;;
    esac
done

## git completion
GITCOMPLETION="$HOME/.git-completion.bash"
GITCOMPLETION_URL="https://raw.githubusercontent.com/git/git/master/contrib/completion/git-completion.bash"
if [[ ! -r "$GITCOMPLETION" ]] ; then
    wget -q -O "$GITCOMPLETION" "$GITCOMPLETION_URL"
fi

## setup eslint

## setup vim modules
#
VIMBUNDLEDIR="$HOME/.vim/bundle"
[ ! -d "$VIMBUNDLEDIR" ] && mkdir "$VIMBUNDLEDIR"
git submodule init
git submodule update

## setup nvim
if [[ ! -e $HOME/.config/nvim ]]; then
    ln -snf $LOCALDIR/nvim $HOME/.config/nvim
fi

## set up yasnippets for emacs
#
GITHUB="https://github.com/brianonn/yasnippet-snippets.git"
YASSNIPPETDIR="$HOME/.emacs.d/snippets"
$RM -fr $YASSNIPPETDIR
git clone $GITHUB $YASSNIPPETDIR

## on linux
if test $machine = Linux; then
    if test -x /usr/bin/nemo ]] ; then
        ## set up local nemo actions
        mkdir -p ~/.local/share/nemo/actions 2>/dev/null 1>&2
        /bin/cp -pr --remove-destination local/share/nemo/actions/* ~/.local/share/nemo/actions/ 2>/dev/null 1>&2
    fi
    ##
    ## TODO
    ## setup tiling window manager
    ## awesome? xmonad? whatever I stick with
    ##

    # set up screenshot savedir
    SCREENSHOTDIR="$HOME/Pictures/Screenshots"
    /usr/bin/mkdir -p "$SCREENSHOTDIR" 2>/dev/null 1>&2
    [ -x /usr/bin/gsettings ] && gsettings set org.gnome.gnome-screenshot auto-save-directory "$SCREENSHOTDIR" 2>/dev/null 1>&2

    ##
    ## set up FIDO U2F key support
    ## see also: https://developers.yubico.com/libfido2/
    ## TODO: is this still necessary in 2023?
    ##
    UDEV_VERSION="$(sudo udevadm --version)"
    if test $UDEV_VERSION -lt 188; then
        GITHUB_RULES="0aaf34f5309ff8b3bf493bd4628ebdd178a41480/70-old-u2f.rules"
    else
        GITHUB_RULES="master/70-u2f.rules"
    fi
    RULEFILE=70-u2f.rules
    wget -q -O/tmp/$RULEFILE "https://raw.githubusercontent.com/Yubico/libu2f-host/$GITHUB_RULES"
    if test $? -eq 0; then
        if test -s /tmp/$RULEFILE && test -d /etc/udev/rules.d/; then
            sudo cp /tmp/$RULEFILE /etc/udev/rules.d/$RULEFILE
            sudo chmod 644 /etc/udev/rules.d/$RULEFILE
            sudo udevadm control --reload-rules
        fi
    fi
fi
