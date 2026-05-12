# determine the os platform and architecture we are on
#
# this specific script must be POSIX shell only so
# that it can run on all platforms
#
# outputs:
#   sets variable ${PLATFORM}
#   sets variable ${ARCH}

# do nothing if we already set it before, as it's readonly
if test "1${PLATFORM}" = "1" ; then
    # can't use bash lowercase string substitution here !
    # sed y/.../.../ is very old and portable, and better than tr(1)
    lowercase(){
        echo "$1" | sed "y/ABCDEFGHIJKLMNOPQRSTUVWXYZ/abcdefghijklmnopqrstuvwxyz/"
    }

    PLATFORM=`uname -s`
    PLATFORM=`lowercase ${PLATFORM}`

    ARCH=`uname -m`
    ARCH=`lowercase ${ARCH}`

    case "${PLATFORM}" in
        linux|darwin|solaris|sunos) ;;
        mac*)                                 PLATFORM="darwin" ;;
        sun*)                                 PLATFORM="sunos" ;;
        cygin*|msys*|win32*|win64*|windows*)  PLATFORM="windows" ;;
        *)                                    PLATFORM="unknown" ;;
    esac

    readonly PLATFORM
    readonly ARCH

    unset -f lowercase

fi
