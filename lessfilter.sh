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

# TODO: make it completely based on mimetypes, since we determined it's type anyways. 
mimetype=$(file -i -F'|' "$1" )

case ${mimetype} in
    *application/zip*binary)
      unzip -tv "$1"
      ;; 
    *application/x-tar*binary|*application/tar*binary)
      tar tvf "$1"
      ;; 

    # catch all other binaries here
    *charset*binary )
      file "$1" 2>/dev/null
      echo 
      if test "1${hexdump}" != "1"; then
        echo "I need the hexdump(1) program to view binary files"
        echo "You should install it"
        echo
        cat -v "$1"
        exit 1
      fi
      ${hexdump} -C "$1" 
      ;;
    *)
      case "$1" in
          # markdown with pandoc
          *.rst|*.md|*.markdown) 
            pandoc -s -f markdown -t man "$1" | groff -T utf8 -man -t 
            ;;
          
          # syntax highlighting using Pygments
          *.[ch]|*.[ch]pp|*.[ch]xx|*.cc|*.hh|*.py|*.pl|*.rb|*.asm|*.java|*.awk|*.sql|*.el|*.clj|*.nim| \
          *.pas|*.p| *.php | Makefile*|*.mak|*.make| \
          *.f | *.fortran | *.fth | *.4th | \
          *.patch | *.diff | \
          *.css|*.js|*.scss|*.jade|*.htm|*.html|*.json|*.ini)
            pygmentize -f 256 -O style=${style} "$1"
            ;;

          # sh and bash using Pygments
          *.sh|.profile|*.bash*)
            pygmentize -f 256 -l sh -O style="${bash_style}" "$1"
            ;;

          # no lexer
          *.m4) cat "$1" ;;  # placeholder. Pygments has no lexer for m4 yet

          # catch-all. can do some tricky guessing with file(1) here too
          *)
            head -1 "$1" | egrep '(#!/bin/sh|#!/bin/bash|#!/usr/bin/env.*(ba)?sh)' > /dev/null 2>&1 
            if test $? -eq 0; then 
              pygmentize -f 256 -l sh -O style="${bash_style}" "$1"
            else
              exit 1
            fi
            ;;
      esac
    esac
  exit 0
