##
## common X startup.
##
## This script is sourced, never executed.  Do not exit from this script
## or the main xsession will exit and never start.
##

log="$HOME/.xsession.startup.log"

echo "$(date) : starting $1" >> ${log}

## two screens, with laptop screen to the left and HDMI screen to the right
xrandr --output eDP1 --primary --left-of HDMI1 --output HDMI1 --auto

# disable X server screen blanking and set DPMS stanby timers to 3600s (1 hr)
xset s 0 0 s noblank s noexpose dpms 3600 3600 3600

case $1 in
  xmonad)
    xmonad --recompile 2>&1 >> ${log}
    ## start some apps for xmonad
    $HOME/.config/xmonad/startup.sh 2>&1 >> ${log}
    ;;
  *openbox-session*)
     ## do nothing special here, openbox has it's own startup in ~/.config/openbox/autostart.sh
     ;;
  *) ;;
esac
