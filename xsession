##
## common X startup.
##
## This script is sourced, never executed.  Do not exit from this script
## or the main xsession will exit and never start.
##
## This xsession script is sourced by the XDM display manager
##

log="$HOME/.xsession.startup.log"

echo "$(date) : $0: starting $1" >> ${log}

## two screens, with laptop screen to the left and HDMI screen to the right
xrandr --output eDP1 --primary --left-of HDMI1 --output HDMI1 --auto

# disable X server screen blanking and set DPMS stanby timers to 3600s (1 hr)
xset s 0 0 s noblank s noexpose dpms 3600 3600 3600

case $1 in
  xmonad-session)
    xmonad --recompile 2>&1 >> ${log}
    ## start some apps for xmonad
    $HOME/.config/xmonad/startup.sh 2>&1 >> ${log}
    echo "$(date) : $0: ending $1" >> ${log}
    echo "$(date) : $0: starting xmonad window manager..." >> ${log}
    ;;
  openbox-session)
     ## do nothing special here, openbox has it's own startup in ~/.config/openbox/autostart.sh
     ;;
  *) ;;
esac
