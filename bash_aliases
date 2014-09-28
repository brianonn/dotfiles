# c-basic-offset: 4; tab-width: 4; indent-tabs-mode: nil
# vi: set shiftwidth=4 tabstop=4 expandtab:
# vi: set filetype=sh
# :indentSize=4:tabSize=4:noTabs=true:

# functions as aliases
# mkpw <length>
mkpw()
{
    len="$1"
    if test 1$len = 1; then 
        len=16
    fi

    cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w $len | head -n 1
}

pid2cmd()
{
  c=$(ps -p "$1" -o command=) && echo $c
}

psgrep()
{
  str="$1"
  pids=$(ps axo pid,command | grep "${str}" | grep -v grep | awk 'BEGIN {c=""} {printf "%c%s",c,$1;c=","} END {print "\n"}')
  if [[ ! -z ${pids} ]]; then 
    ps -p ${pids} -o pid,ppid,ruser,euser,stat,pcpu,pmem,command
  else
    echo "no matching commands"
  fi
}

dmesg_with_human_timestamps () {
    local dmesg_bin=$(type -a dmesg | tail -n 1 | awk '{ print $NF }')
    $dmesg_bin "$@" | perl -w -e 'use strict;
        my ($uptime) = do { local @ARGV="/proc/uptime";<>}; ($uptime) = ($uptime =~ /^(\d+)\./);
        foreach my $line (<>) {
            printf( ($line=~/^\[\s*(\d+)\.\d+\](.+)/) ? ( "[%s]%s\n", scalar localtime(time - $uptime + $1), $2 ) : $line )
        }'
}
alias dmesg=dmesg_with_human_timestamps

lsR () {
    if test "1$1" -eq "1"; then 
      dir=.
    else
      dir="$1"
    fi
    ls -lRU --time-style="+%Y-%m-%d,%H:%M:%S" "$1" | awk '  \
        /:$/&&f{s=$0;f=0}                       \
        /:$/&&!f{sub(/:$/,"");s=$0;f=1;next}    \
        /^total/ {next}                         \
        NF&&f{ print $6, s"/"$7}                \
        ' | sort  
}

recent() {
  lsR $1 | sort -r | head -20
}

alias backup='rsync -av --progress --exclude='\''*/Downloads/In-Progress/'\'' --exclude='\''*/Downloads/Torrents/'\'' --exclude='\''*/Downloads/Completed/'\'' --exclude='\''*/.cache/'\'' --exclude='\''*/.thumb*/'\'' $HOME /zpool0/downloads/'
alias book=$HOME/bin/findebook.sh
alias b=book

## CSCOPE AND TAGS
alias cstags='/bin/rm -f cscope.files cscope.out tags etags TAGS ETAGS ; find . \( -name "*.[cChHsS]" -o -name "*.[chCH]pp" -o -name "*.asm" -o -name "*.ASM" \) -print > cscope.files ; cscope -ubc -i cscope.files ; ctags -e -f ETAGS -L cscope.files ; ctags -f TAGS -L cscope.files; ccglue -o cctree.out -i cctree.idx'

alias llpkg='dpkg-query -W -f="\${Installed-Size}\t\${binary:Package}\n" | sort -n'
alias shred='shred -v -n 3 -z -u -f'
alias smath='/opt/smath-mono/smath.sh'
alias tff='torify32 /usr/local/firefox/firefox'
alias t='rxvt-unicode &'
alias vcc='valac'

alias quartus='/opt/altera/13.0sp1/quartus/bin/quartus'
alias ff='firefox'

# Editors
alias e='emacs'
alias v='vi'
alias gv='gvim'
alias ge='gedit'
alias z='zile'
alias s=subl
alias phpstorm=/opt/phpstorm/bin/phpstorm.sh
alias p=phpstorm

# Git aliases for bash
alias gs='git status'
alias gpl='git pull'
alias gps='git push'
alias gd='git diff | mate'
alias gc='git commit -v'
alias gca='git commit -v -a'
alias gb='git branch'
alias gba='git branch -a'
alias gl='git log --oneline --abbrev-commit --graph --decorate'
alias gla='git log --oneline --abbrev-commit --graph --all --decorate'

# google shell
alias gsh="$HOME/src/perl/goosh.pl"

# clojure
alias clojure15='java -cp ~/lib/clojure/clojure-1.5.1.jar clojure.main' 
alias clojure16='java -cp ~/lib/clojure/cloju
re-1.6.0.jar clojure.main' 
alias cj15='clojure15'
alias cj16='clojure16'
alias clojure='clojure16'
alias cj='clojure'

## android dev
alias android="$HOME/android-sdk-linux/tools/android"
alias adb="$HOME/android-sdk-linux/platform-tools/adb"
alias fastboot="$HOME/android-sdk-linux/platform-tools/fastboot"

# lattice diamond for ECP3 and MACHXO
alias diamond='sudo rmmod ftdi_sio usbserial; fakemac 00:1a:4d:92:e6:dc /opt/usr/local/diamond/2.2_x64/bin/lin64/diamond'

# safe mv(1) and rm(1) will move to xdesktop Trash can
alias rm="$HOME/Source/del.sh"
alias mv='mv -i'
alias del=/bin/rm 

alias ppc='cd /cygdrive/d/ppc; Release/ppc.exe ppc.cfg'
alias matlab='~/Courses/Digital_Signal_Processing/MATLAB/R2013b/bin/matlab'

alias less='less -S -R -X -F'
alias h=history
alias dirs='dirs -v'
alias cd=pushd
alias gld-solo-grid="./cgminer -c ~/.bfgminer/goldcoin.conf --gridseed-options='freq=800'"

color_opt=''
if [[ $(tput colors) > 0 ]] ; then 
    color_opt='--color=always' 
    if [ -x /usr/bin/dircolors ]; then 
        [ -r ~/.dircolors ] && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    fi
fi

alias grep="grep $color_opt"
alias fgrep="fgrep $color_opt"
alias egrep="egrep $color_opt"

ls_pager="perl -lpe 's/(\S+)\//[\1]/g' | /bin/less -S -R -X -F"
ls_pager="/bin/less -S -R -X -F"
ls="/bin/ls -F --group-directories-first $color_opt"
alias ls="$ls | $ls_pager" 
alias l="$ls -C | $ls_pager"
alias ll="$ls -l | $ls_pager"
alias lll="$ls -l | tail -20"
alias llr="$ls -lrt | tail -20"
alias lr=llr
alias llx="$ls -X -C --si | $ls_pager"

alias findgrep='find . -type f \( -name \*.git -o -name .snaphot -o -name .bak -prune \) -print0 | xargs -0 grep -in'

alias dclr='sudo docker rm $(sudo docker ps -qa); sudo docker rmi $(sudo docker images -q -f dangling=true)'
alias d1="sudo docker ps | awk 'NR==2 { print \$1 }'"
alias dip="sudo docker inspect --format='{{.NetworkSettings.IPAddress}}' \`d1\`"

#tmux pane titles
#alias np=printf "'\033]2;%s\033'" "'title goes here'"
