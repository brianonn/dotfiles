# this function provides me with some local help information for my customized environment
# TODO: extract this to a .localhelp.txt file
function _local_help() {
    echo
    echo "############# LOCAL HELP ############"
    echo
    if type tldr 2>/dev/null >/dev/null; then
        echo "  Use tldr <command> "
        echo "  See also 'tldr tldr'"
        echo
    fi
    echo "  You can also see the output from 'help man'"
    echo "  and try just 'man <command>'"
    echo
    if type info 2>/dev/null >/dev/null; then
        echo "  The 'info' command is useful for getting help with GNU commands"
        echo "  Try 'info' by itself, or 'info <command>'."
        echo
    fi
    echo "  For looking up commands that might do what you want,"
    echo "  use 'apropos <thing>' where <thing> is something about"
    echo "  what you want the command to do for you"
    echo
    echo "  Ex: "
    echo "    'apropos audio'  -- will return a list of commands that work with audio."
    echo
    echo "########################################"
    echo
}

# update the bash help command to be more useful
function help() {
    # run the built-in bash help first
    \command \help

    # then show the local help text
    _local_help
}

