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

# TODO: make the style selection based on mime-type or file extension
style="monokai"
bash_style="paraiso-dark"

hexdump=$(which hexdump)

case "$1" in
    # markdown with pandoc
    *.1|*.rst|*.md|*.markdown)
    pandoc -s -f markdown -t man "$1" | groff -T utf8 -man -t
    exit 0
    ;;

    # syntax highlighting using Pygments
    *.[ch]|*.[ch]pp|*.[ch]xx|*.cc|*.hh|*.py|*.pl|*.rb|*.asm|*.java| \
        *.awk|*.sql|*.el|*.clj|*.nim| *.pas|*.p| *.php | *.f | \
        *.fortran | *.fth | *.4th | *.patch | *.diff | *.css| \
        *.js|*.scss|*.jade|*.htm|*.html|*.json|*.ini)
    pygmentize -f 256 -O style=${style} "$1"
    exit 0
    ;;

    # Vagrantfile
    [vV]agrantfile)
    pygmentize -f 256 -l ruby  -O style="${style}" "$1"
    exit 0
    ;;

    # makefiles
    [mM]akefile*|*.mak|*.make)
    pygmentize -f 256 -l Makefile  -O style="${style}" "$1"
    exit 0
    ;;

    # sh and bash using Pygments
    *.sh|.profile|*.bash*)
    pygmentize -f 256 -l sh -O style="${bash_style}" "$1"
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
    *)
    mimetype=$(file -i -L -F'|' "$1" )
    case ${mimetype} in
      *text/lisp*|*text/x-lisp*)
        pygmentize -f 256 -l lisp -O style="${bash_style}" "$1"
        exit 0
        ;;
      *application/zip*binary)
        unzip -tv "$1"
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
    pygmentize -f 256 -l sh -O style="${bash_style}" "$1"
else
    exit 1
fi

exit 0
