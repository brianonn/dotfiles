##
## common X startup.
##
## This script is sourced, never executed.  Do not exit from this script
## or the main xsession will exit and never start.
##
## This xsession script is sourced by the XDM display manager
## see also the .xprofile file
##

set -x
exec > "$HOME/.xsession.debug.log" 2>&1

echo "$(date) : $0: starting $1"

# switch based on session chosen from the Display Manager (SDDM, GDM, LightDM, etc)
#
case $1 in
  xmonad-session)
    ## TODO: recompile only if $HOME/.config/xmonad/xmonad.hs is newer than $(which xmonad) binary
    xmonad --recompile
    ## start some apps for xmonad
    echo "$(date) : $0: startup.sh: xmonad window manager..."
    [ -x $HOME/.config/xmonad/startup.sh ] && $HOME/.config/xmonad/startup.sh
    echo "$(date) : $0: startup.sh: completed"
    ;;
  openbox-session)
     ## do nothing special here, openbox runs it's own startup in ~/.config/openbox/autostart.sh
     ;;
  *) ;;
esac
