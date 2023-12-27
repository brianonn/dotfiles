#!/bin/sh

# lessfilter
#
# Author: Brian A. Onn
# License: MIT/X11

# use with
#
#   export LESS="-R"
#   export LESSOPEN="|~/.lessfilter"
#

# requirements: install the following before you use it
#     hexdump
#     pandoc
#     pygments
#     gzip
#     bzip2
#     tar
#     vue-lexer (for .vue files)
#
# TODO: There is only two hardcoded style choices right now. Ideally,
#       the style should be selected based on mime-type or file extension
#
# TODO: add LESSFILTER_HTML_VIEWER env variable to use "lynx" or "firefox" or "chrome" , etc

default_style="zenburn"
bash_style="zenburn"

hexdump=$(which hexdump)
##OFF## htmlviewer=$(which webview)
##OFF## [ -n "$LESSFILTER_HTML_VIEWER" ] && htmlviewer="$LESSFILTER_HTML_VIEWER"

case "$1" in
	# man pages
	*.[1-9] | *.[1-9][a-z])
		groff -T utf8 -man -t "$1"
		exit 0
		;;

	# compressed man pages
	*.[1-9].gz | *.[1-9][a-z].gz)
		gzip -dc "$1" | groff -T utf8 -man -t
		exit 0
		;;

##OFF##	# markdown or ReStructured Text
##OFF##	*.[mM][dD]|*.markdown|*.rst)
##OFF##        if [[ -r $HOME/.pandoc.css ]]; then
##OFF##            pandoc_css="--embed-resources --standalone --css=$HOME/.pandoc.css"
##OFF##        else
##OFF##            pandoc_css=""
##OFF##        fi
##OFF##        if [[ -n "$htmlviewer" ]] ; then
##OFF##            pandoc $pandoc_css --metadata title=$(basename "$1") -s -t html "$1" | $htmlviewer
##OFF##        else
##OFF##            pandoc $pandoc_css --metadata title=$(basename "$1") -s -t html "$1"
##OFF##        fi
##OFF##        exit 0
##OFF##        ;;

	# markdown or ReStructured Text
	*.[mM][dD]|*.markdown|*.rst)
        pygmentize -f 16m -O style=${default_style} "$1"
	exit 0
    ;;

    # syntax highlighting using Pygments. Pygments handles quite a lot !
    Dockerfile|*.[ch]|*.[ch]pp|*.[ch]xx|*.cc|*.hh|*.go|*.py|*.pl|*.R|*.asm|*.java| \
        *.awk|*.sql|*.el|*.clj|*.nim| *.pas|*.p| *.php | *.f | *.lua | \
        *.fortran | *.fth | *.4th | *.patch | *.diff | *.css | *.rs | *.vue | \
        *.js|*.scss|*.jade|*.htm|*.html|*.json|*.ini|*.yml|*.yaml|*.v|*.sv | *.vim)
    pygmentize -f 16m -O style=${default_style} "$1"
    exit 0
    ;;

    # Vagrantfile, Capfile, Rakefile, Gemfile, Guardfile, *.rb, *.ru is ruby
    [vV]agrantfile | [Cc]apfile | [Rr]akefile | [Gg]emfile | [Gg]uardfile | *.rb | *.ru)
    pygmentize -f 16m -l ruby  -O style="${default_style}" "$1"
    exit 0
    ;;

    # makefiles
    [mM]akefile*|*.mak|*.make)
    pygmentize -f 16m -l Makefile  -O style="${default_style}" "$1"
    exit 0
    ;;

    # sh and bash using Pygments
    *.sh|.profile|*.bash*)
    pygmentize -f 16m -l sh -O style="${bash_style}" "$1"
    exit 0
    ;;

    # xml and policy-kit using Pygments
    *.xml|*.policy)
    pygmentize -f 16m -l xml -O style="${default_style}" "$1"
    exit 0
    ;;

    # library archive
    *.ar|*.a) ar tv "$1" && exit 0 ;;

    # compressed log
    *.log.gz) gzip -dc "$1" && exit 0 ;;
    *.log.bz|*.log.bz2|*.txt.bz|*.txt.bz2) bzip2 -dc "$1" && exit 0 ;;

    # tar gz
    *.tar.gz|*.tgz) tar -tvzf "$1" && exit 0 ;;

    # no lexer
    *.m4) cat "$1"  # placeholder. Pygments has no lexer for m4 yet
    exit 0
    ;;

    #  check the mime type last
    #  TODO: maybe classify all files first?
    *)
    mimetype=$(file -b -i -L "$1" )
    case ${mimetype} in
      *text/xml*|*/*+xml*)
        pygmentize -f 16m -l xml -O style="${default_style}" "$1"
        exit 0
        ;;
      *text/lisp*|*text/x-lisp*)
        pygmentize -f 16m -l lisp -O style="${bash_style}" "$1"
        exit 0
        ;;
      *application/zip*binary)
        unzip -lv "$1"
        exit 0
        ;;
      *application/x-tar*binary|*application/tar*binary)
        tar tvf "$1"
        exit 0
        ;;

      *inode/x-empty*)
        echo "'$1': is empty (size is 0 bytes)."
        exit 0
        ;;

      # catch all other binaries here
      *charset*binary )
        file "$1" 2>/dev/null
        echo
        if test "1${hexdump}" = "1"; then
          echo "I need the hexdump(1) program to view binary files"
          echo "You should install it"
          echo
          cat -v "$1"
          exit 1
        fi
        ${hexdump} -C "$1"
        exit 0
        ;;
    esac
esac

head -1 "$1" | egrep '(#!/bin/sh|#!/bin/bash|#!/usr/bin/env.*(ba)?sh)' > /dev/null 2>&1
if test $? -eq 0; then
    pygmentize -f 16m -l sh -O style="${bash_style}" "$1"
else
    exit 1
fi

exit 0
