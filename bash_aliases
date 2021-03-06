# -*- mode: sh; c-basic-offset: 4; tab-width: 4; indent-tabs-mode: nil -*-
# vi: set ft=sh shiftwidth=4 tabstop=4 expandtab :

# File: ~/.bash_aliases

# read the sensitive aliases, that might contain passwords.
# This file should never be pushed up to a public server in the dotfiles.
[[ -r ~/.dotfile_secrets/bash_aliases ]] && source ~/.dotfile_secrets/bash_aliases

real_less=$(which less 2>/dev/null)
real_tail=$(which tail 2>/dev/null)
real_grep=$(which grep 2>/dev/null)
real_ls=$(which gls 2>/dev/null) || real_ls=$(which ls 2>/dev/null)

#
# TODO: make an alias for counting extensions in a directory (or list of directories)
countext () {
    local dirs="$@"
    find $dirs -type f | sed -re 's/^.*\.(.{1,5})$/\1/p; d' | tr 'A-Z' 'a-z' | sort | uniq -c | sort -n
}



# functions as aliases

## returns exit status 0 if running on systemd
isSystemd() {
    # requires sudo
    # grep -q systemd <<<$(ls -l $(sed 's/.* //g' <<<$(sudo ls -l /proc/1/exe)))
    ps --no-headers -o comm 1 2>/dev/null | $real_grep -q systemd || return 1
}

bu() {
 cp "$@" "$@".backup-`date +%Y%m%d`&& echo "`date +%Y-%m-%d` backed up $PWD/$@" >> ~/.backups.log;
}

# remove all kernels except the running one
rmkernel () {
   local cur_kernel=$(uname -r|sed 's/-*[a-z]//g'|sed 's/-386//g')
   local kernel_pkg="linux-(image|headers|ubuntu-modules|restricted-modules)"
   local meta_pkg="${kernel_pkg}-(generic|i386|server|common|rt|xen|ec2)"
   sudo dpkg -P --force-all $(dpkg -l | ${real_grep} -E --color=no $kernel_pkg | ${real_grep} -E --color=no -v "${cur_kernel}|${meta_pkg}" | awk '{print $2}')
   sudo update-grub
}

## crazy web server in shell
webserver() {
    port=${1:-3333}
    pipe=/tmp/pipe.$port.$RANDOM.$$
    rm -f $pipe
    mkfifo $pipe
    while :
        do {
            read line < $pipe
            echo -e "HTTP/1.1 200 OK\r\nServer: $SHELL $BASH_VERSION\r\nContent-Type: text/plain\r\nConnection: close\r\n"
            echo $(date)
        } | ncat -l $port > $pipe
    done
    rm -f $pipe
}

# imagemagic resize screencaps from LG G3
#
# mkdir tmp
# mogrify -path ./tmp  -level 35%,100%,0.70 -resize x1024\> -quality 87 -format jpg *.png
#

## mkpw is now a function in my ~/bin
alias pw=mkpw

# random 16 lowercase letters
alias mkpw='cat /dev/urandom | LC_CTYPE=C tr -dc a-z | fold -w 16 | head -n 1'

fc()
{
  old="$1"
  new="$2"
  cmp -l $old $new | \
       gawk '{printf "%08X %02X %02X\n", $1, strtonum(0$2), strtonum(0$3)}'
}

pid2cmd()
{
  c=$(ps -p "$1" -o command=) && echo $c
}

# grep for a process
psgrep()
{
  str="$1"
  ps axo pid,ppid,ruser,euser,stat,pcpu,pmem,stime,command | awk 'BEGIN {s=1} NR==1 {hdr=$0} $9 ~ /'"${str}"'/ { if(s) {print hdr} print $0;s=0} END {exit s}'
  if test "$?" = 1; then
    echo "no matching commands"
  fi
}

# show the complete docker process tree
psdocker()
{
    pid=$(ps axo pid,cmd | sed -e 's,\([0-9][0-9]*\) /usr/bin/docker.*,\1,p' -e d)
    if test "1$pid" -ne 1; then
        pstree -au $pid
    fi
}

dmesg_with_human_timestamps () {
    local dmesg_bin=$(type -a dmesg | /usr/bin/tail -n 1 | awk '{ print $NF }')
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

# convert a markdown file to HTML using pandoc and a decent CSS for style
mdtohtml() {
  pandoc -f markdown -t html -s -c ~/Documents/buttondown.css --self-contained  "$1" -o "${1%md}.html"
}
# convert markdown to HTML and view it
viewmd() {
  mdtohtml "$1"
  xdg-open "${1%md}.html"
}

function serve {
  port="${1:-3000}"
  ruby -run -e httpd . -p $port
}


alias backup='rsync -av --progress --exclude='\''*/Downloads/In-Progress/'\'' --exclude='\''*/Downloads/Torrents/'\'' --exclude='\''*/Downloads/Completed/'\'' --exclude='\''*/.cache/'\'' --exclude='\''*/.thumb*/'\'' $HOME /zpool0/downloads/'
alias book=$HOME/bin/findebook.sh
alias b=book
alias rs='rsync -az --dry-run --delete-after --out-format="[%t]:%o:%f:Last Modified %M" source destination | ${real_less}'

## CSCOPE AND CTAGS
alias cstags='/bin/rm -f cscope.* tags etags TAGS ETAGS ; find . \( -name "*.[cChHsS]" -o -name "*.[chCH]pp" -o -name "*.asm" -o -name "*.ASM" -o -name "*.py" -o -name "*.java" \) -print | /usr/bin/grep -E -v '[/][.]?#.*#?$' > cscope.files ; cscope -ubq -i cscope.files ; ctags -e --extra=+q -f ETAGS -L cscope.files ; ctags -f TAGS -L cscope.files; ccglue -o cctree.out -i cctree.idx'

alias llpkg='dpkg-query -W -f="\${Installed-Size}\t\${binary:Package}\n" | sort -n'
alias shred='shred -v -n 3 -u -f'
alias smath='/opt/smath-mono/smath.sh'
alias tff='torify32 /usr/local/firefox/firefox'
alias t='rxvt-unicode &'
alias vcc='valac'
alias tf=terraform

alias quartus='/opt/altera/13.0sp1/quartus/bin/quartus'
alias ff='firefox'

# Editors
alias e='$HOME/bin/edit'
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
alias gcp='git add -u && git commit -m "checkpoint $(date -u +%FT%TZ)" '
alias gcpp='git add -u && git commit -m "checkpoint $(date -u +%FT%TZ)" && git push'
alias gcpw='watch -n 3600 "git add -A && git commit -m \"checkpoint $(date -u +%FT%TZ)\" && git push"'
alias gitu='git checkout master && git pull --rebase && git checkout - && git rebase master'
alias git-remove-untracked='git fetch --prune && git branch -r | awk "{print \$1}" | /usr/bin/grep -E --color=no -v -f /dev/fd/0 <(git branch -vv | grep --color=no origin) | awk "{print \$1}" | xargs -n1 echo git branch -d'

# google shell
alias gsh="$HOME/src/perl/goosh.pl"

# clojure
alias clojure15='java -cp ~/lib/clojure/clojure-1.5.1.jar clojure.main'
alias clojure16='java -cp ~/lib/clojure/clojure-1.6.0.jar clojure.main'
alias cj15='clojure15'
alias cj16='clojure16'
alias clojure='clojure16'
alias cj='clojure'
alias cji='clojure16'

## android dev
alias android="$HOME/android-sdk-linux/tools/android"
alias adb="$HOME/android-sdk-linux/platform-tools/adb"
alias fastboot="$HOME/android-sdk-linux/platform-tools/fastboot"

# lattice diamond for ECP3 and MACHXO
alias diamond='sudo rmmod ftdi_sio usbserial; fakemac 00:1a:4d:92:e6:dc /opt/usr/local/diamond/2.2_x64/bin/lin64/diamond'

# safe mv(1) and rm(1) will move to xdesktop Trash can
[ -x $HOME/Source/del.sh ] && alias rm="$HOME/Source/del.sh"
alias mv='mv -i'
alias del=/bin/rm

alias ppc='cd /cygdrive/d/ppc; Release/ppc.exe ppc.cfg'
alias matlab='~/Courses/Digital_Signal_Processing/MATLAB/R2013b/bin/matlab'

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

ls_pager="perl -lpe 's/(\S+)\//[\1]/g' | ${real_less} -S -R -X -F"
ls_pager="${real_less} -S -R -X -F"
ls_bin="${real_ls} -C -F --group-directories-first $color_opt"

alias more=less
[ -x $(which colortail 2>/dev/null) ] && alias tail=colortail

alias ls=ls
unalias ls
ls  () { $ls_bin "$@" | $ls_pager ; }
l   () { $ls_bin -C "$@" | $ls_pager ; }
ll  () { $ls_bin -l "$@" | $ls_pager ; }		# long list
lt  () { $ls_bin -lt "$@" | ${real_tail} -20 ; }	# time order long list
lr  () { $ls_bin -lrt "$@" | ${real_tail} -20 ; } 	# reverse time ordered long list
lx  () { $ls_bin -X -C --si "$@" | $ls_pager ; }	# list ordered by extension
lw  () { $ls_bin -w $(tput cols) "$@"; }		# list wide
### ll  () { $ls_bin -l "$@" | $ls_pager ; }
### lll () { $ls_bin -lt "$@" | /usr/bin/tail -20 | $ls_pager; }
### llr () { $ls_bin -lrt "$@" | /usr/bin/tail -20 | $ls_pager; }
### alias lr=llr
### llx () { $ls_bin -X -C --si "$@" | $ls_pager ; }
### lw  () { $ls_bin -w $(tput cols) "$@" | $ls_pager ; }

alias findgrep='find . -type f \( -name \*.git -o -name .snaphot -o -name .bak -prune \) -print0 | xargs -0 grep -in'

# helpful docker aliases
alias dclr='_i=$(docker ps -qa);[ ! -z "$_i" ] && docker rm $_i; _i=$(docker images -q --filter dangling=true); [ ! -z "$_i" ] && docker rmi $_i'
alias vclr='docker volume rm `docker volume ls -q -f dangling=true`'
alias   d1="docker ps | awk 'NR==2 { print \$1 }'"
alias  dip="docker inspect --format='{{.NetworkSettings.IPAddress}}' \`d1\`"

#tmux pane titles
#alias np=printf "'\033]2;%s\033'" "'title goes here'"

alias cdi='isoinfo -d -i /dev/cdrom | grep -i -E "block size|volume size"'
alias cpu="watch \"grep -E '^model name|^cpu MHz' /proc/cpuinfo\""

# safe(r) strings - GNU strings normally uses libbfd to read sections, and this can be exploited with evil pointers in
# the random executable you're running strings on. The -a option forces strings to not use libbfd.
alias strings='strings -a'

#
# Some convenient dig aliases
alias adig='dig -t a +noall +answer'
alias mdig='dig -t mx +noall +answer'
alias cdig='dig -t cname +noall +answer'
alias digg='dig +all'

alias mpb='/bin/nc paste.linuxmint.com 9999 <<< "${*:-`cat`}"'

alias iso8601='date -u +%FT%TZ'
alias localtime='date "+%F %T %Z"'
alias utctime='date -u "+%F %T %Z"'
alias utc=utctime
alias unixtime='date "+%s"'

alias qpdfview='qpdfview --unique'
alias qp='qpdfview --unique'

# pretty print json files with python
alias jsp='python -mjson.tool'
alias size='du -skh'
alias ipy='ipython notebook --pylab inline'
alias bcryptpass='htpasswd -nBC 10 "" | tr -d ":\n"'
alias qu='qemu-system-x86_64 -machine accel=kvm:tcg -m 4096 -hda /dev/sdc -net tap -net nic --monitor stdio'
alias mount='mount | column -t'
alias diff='colordiff -w -t --tabsize=4'

# hub
# brew install hub
[ -x $(which hub 2>/dev/null) ] && alias git=hub

# glances monitors system process and io and docker and temps
alias glance=glances

# list all the fonts available
alias fonts="fc-list | awk '{\$1=\"\"}1' | cut -d: -f1 | sort| uniq"
alias start_ubuntu='vmrun start ~/Virtual\ Machines.localized/Ubuntu\ 64-bit.vmwarevm/Ubuntu\ 64-bit.vmx nogui'
alias start_windows='vmrun start ~/Virtual\ Machines.localized/Windows\ 10\ x64.vmwarevm/Windows\ 10\ x64.vmx'

# termbin.com without netcat
alias tb="(exec 3<>/dev/tcp/termbin.com/9999; cat >&3; cat <&3; exec 3<&-)"
