#!/usr/bin/env bash
#
# Shared helpers for the add_default_stereo_track.sh tests. Sourced by each numbered test.
# The runner only executes files named NN-*, so this file is never run as a test.
#
# A test starts with:
#   SCRIPT="$1"
#   source "$(dirname "$0")/_common.sh"
#   tmp_setup
#
# Exit 0 = pass. Any non-zero exit = fail (fail() exits 1).

fail() {
    echo "assertion failed: $*" >&2
    exit 1
}

# Create a scratch directory for the test's fixtures and outputs; removed on exit.
tmp_setup() {
    TMP_TEST_DIR=$(mktemp -d)
    trap 'rm -rf "$TMP_TEST_DIR"' EXIT
    cd "$TMP_TEST_DIR"
}

# make_source OUT CHANNELS CODEC [extra ffmpeg audio args...]
# Two-second MKV: video track 0 and a sine-wave audio track 1.
make_source() {
    local out=$1 channels=$2 codec=$3
    shift 3
    ffmpeg -v error -y \
        -f lavfi -i color=c=black:s=64x64:d=2 \
        -f lavfi -i sine=f=440:d=2 \
        -map 0:v -map 1:a -t 2 -ac "$channels" -c:a "$codec" "$@" "$out" \
        || fail "could not create fixture $out"
}

# retag IN OUT [mkvmerge options for the next input...]
# Copies IN to OUT with the given track options (language, name, default flag, ...).
# Options are applied to the input file, so track IDs refer to IN's tracks.
retag() {
    local in=$1 out=$2
    shift 2
    mkvmerge -q -o "$out" "$@" "$in" >/dev/null || fail "mkvmerge could not retag $in"
}

# Run the script under test. Output is kept in LAST_OUTPUT. Returns the script's exit status.
run_script() {
    LAST_OUTPUT=$("$SCRIPT" "$@" 2>&1)
}

track_count() {
    mkvmerge -J "$1" | jq '.tracks | length'
}

codec_count() {
    mkvmerge -J "$1" | jq --arg c "$2" '[.tracks[] | select(.type == "audio" and .codec == $c)] | length'
}

# Number of default-flagged 2-channel AAC audio tracks in FILE.
default_stereo_aac_count() {
    mkvmerge -J "$1" | jq '[.tracks[] | select(.type == "audio" and ((.codec // "") | test("^AAC")) and .properties.audio_channels == 2 and (.properties.default_track // false))] | length'
}

# Number of default-flagged audio tracks in FILE.
default_audio_count() {
    mkvmerge -J "$1" | jq '[.tracks[] | select(.type == "audio" and (.properties.default_track // false))] | length'
}

assert_eq() {
    local what=$1 actual=$2 expected=$3
    [ "$actual" = "$expected" ] || fail "$what: expected '$expected', got '$actual'"
}

assert_file() {
    [ -f "$1" ] || fail "expected file '$1' to exist"
}

assert_no_file() {
    [ ! -e "$1" ] || fail "expected '$1' not to exist"
}

assert_output_contains() {
    case "$LAST_OUTPUT" in
        *"$1"*) ;;
        *) fail "script output does not contain '$1'. Output was: $LAST_OUTPUT" ;;
    esac
}
