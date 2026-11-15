#!/usr/bin/env bash
#
# add_default_stereo_track.sh
#
# Change log:
# 2026-11-13
#   - when overwriting the source file, it now retains the original source file
#     mtime and atime values.
#
# 2026-11-14
#   - Detects 5.1 (6ch) or 7.1 (8ch) source tracks and, in addition to the
#     AAC 2-channel stereo track, creates an AC-3 5.1 track at 640kbps, 48kHz.
#   - 5.1 source: encoded directly to AC-3 5.1.
#   - 7.1 source: downmixed to 5.1 (side channels folded into back pair at
#     0.707 each), then encoded to AC-3 5.1.
#   - AC-3 track is not run through the compressor/loudnorm chain, so the
#     surround mix keeps its original dynamics.
#   - Both new tracks are merged into the output; original audio tracks shift
#     down by 2 (or by 1 when no AC-3 track is created). Video stays first.
#   - AC-3 track: tagged eng, named "English 5.1 AC-3", not default. AAC stereo
#     remains the default track.
#   - Track count verification expects +1 or +2 new tracks; when AC-3 is
#     created, the output is also checked for an AC-3 track with 6 channels.
#
# 2026-11-15
#   - Compressor: attack 20ms -> 10ms, release 250ms -> 300ms, knee 2.83dB -> 3dB,
#     makeup gain 6dB -> 2dB (loudnorm restores the level anyway).
#   - Surround downmix: lower summed gain for headroom (FL/FR = 0.35 front + 0.70 FC
#     + 0.25 back + 0.25 side) and 0.20 LFE mixed into both channels.
#   - Existing AAC stereo detection: if the file already has a suitable AAC 2-channel
#     track (eng/en/und, not commentary/visually-impaired/description), it is reused
#     and made the default instead of adding another one. Its AAC encode is skipped.
#   - If no new track is needed at all, exits 0 with "Nothing to do" and writes no
#     output. The input is not touched in overwrite mode.
#   - Track count verification expects +0, +1 or +2 depending on what was added.

set -euo pipefail

OVERWRITE=false

usage() {
    echo "Usage: $0 [-o] <input.mkv>"
    echo "  -o    Safely overwrite the original file after verification"
    exit 1
}

if [ $# -lt 1 ]; then
    echo "Usage: $0 <input.mkv>"
    exit 1
fi

# Parse optional -o flag
while getopts ":o" opt; do
    case "$opt" in
        o) OVERWRITE=true ;;
        *) usage ;;
    esac
done
shift $((OPTIND - 1))

if [ $# -lt 1 ]; then
    usage
fi

INPUT="$1"
if [ ! -f "$INPUT" ]; then
    echo "Error: File '$INPUT' not found." >&2
    exit 1
fi

# Check dependencies
for cmd in mkvmerge mkvextract ffmpeg jq; do
    if ! command -v "$cmd" &>/dev/null; then
        echo "Error: '$cmd' is required but not installed." >&2
        exit 1
    fi
done

# Capture the original access and modify times
if [ "$OVERWRITE" = true ]; then
    ORIG_ATIME=$(stat -c '%x' "$INPUT")
    ORIG_MTIME=$(stat -c '%y' "$INPUT")
fi

# Inspect container metadata once
MKV_JSON=$(mkvmerge -J "$INPUT")

# 1. Pick the highest-quality non-commentary English audio track
TRACK_ID=$(echo "$MKV_JSON" | jq -r '
  [
    .tracks[]
    | select(.type == "audio")
    | select(.properties.language == "eng" or .properties.language == "en" or .properties.language == "und")
    | select((.properties.flag_commentary // false) == false)
    | select((.properties.flag_visual_impaired // false) == false)

    | select(((.properties.track_name // "") | test("commentary|director|descriptive|description"; "i")) | not)
    | . + {
        score: (
          (if (.codec | test("TrueHD|FLAC|PCM"; "i")) or ((.properties.codec_id // "") | test("TRUEHD|FLAC|PCM"; "i")) then 100
           elif (.codec | test("DTS-HD"; "i")) then 90
           elif (.codec | test("DTS"; "i")) then 75
           elif (.codec | test("E-AC-3|EAC3"; "i")) then 65
           elif (.codec | test("AC-3|AC3"; "i")) then 50
           else 25 end)
          + ((.properties.audio_channels // 2) * 2)
        )
      }
  ]
  | sort_by(-.score, .id)
  | .[0].id // empty
')

if [ -z "$TRACK_ID" ]; then
    echo "Error: No suitable English audio track found in '$INPUT'." >&2
    exit 1
fi

# Get all existing audio track IDs to remove their default flags later
ALL_AUDIO_IDS=$(echo "$MKV_JSON" | jq -r '.tracks[] | select(.type == "audio") | .id')

# Source channel count for the selected track (6 = 5.1, 8 = 7.1)
CHANNELS=$(echo "$MKV_JSON" | jq -r --argjson id "$TRACK_ID" '.tracks[] | select(.id == $id) | .properties.audio_channels // 2')

# Look for an existing suitable stereo AAC track so it is not duplicated. Suitable means:
# AAC codec, 2 channels, language eng/en/und (the same set as the source selection above),
# and not commentary, visually-impaired, or description (same filters as the selection).
# When several qualify, one already flagged default wins, then the lowest track ID.
EXISTING_AAC_ID=$(echo "$MKV_JSON" | jq -r '
  [
    .tracks[]
    | select(.type == "audio")
    | select(((.codec // "") | test("^AAC"; "i")) or ((.properties.codec_id // "") | test("^A_AAC"; "i")))
    | select((.properties.audio_channels // 0) == 2)
    | select(.properties.language == "eng" or .properties.language == "en" or .properties.language == "und")
    | select((.properties.flag_commentary // false) == false)
    | select((.properties.flag_visual_impaired // false) == false)
    | select(((.properties.track_name // "") | test("commentary|director|descriptive|description"; "i")) | not)
  ]
  | sort_by(((.properties.default_track // false) | not), .id)
  | .[0].id // empty
')

CREATE_AAC=true
REUSE_AAC_ID=""
if [ -n "$EXISTING_AAC_ID" ]; then
    CREATE_AAC=false
    REUSE_AAC_ID="$EXISTING_AAC_ID"
    REUSE_AAC_LANG=$(echo "$MKV_JSON" | jq -r --argjson id "$REUSE_AAC_ID" '.tracks[] | select(.id == $id) | .properties.language // "und"')
    REUSE_AAC_DEFAULT=$(echo "$MKV_JSON" | jq -r --argjson id "$REUSE_AAC_ID" '.tracks[] | select(.id == $id) | (.properties.default_track // false)')
    echo "Found existing suitable AAC 2-channel track { ID: $REUSE_AAC_ID, Language: $REUSE_AAC_LANG }."
    echo "Reusing it and skipping creation of a new stereo AAC track (AAC, 2 channels, not commentary/visually-impaired/description)."
fi

# Also create an AC-3 5.1 track when the source is 5.1 or 7.1
CREATE_AC3=false
if [ "$CHANNELS" -eq 6 ] || [ "$CHANNELS" -eq 8 ]; then
    CREATE_AC3=true
fi

TRACKS_ADDED=0
if [ "$CREATE_AAC" = true ]; then
    TRACKS_ADDED=$((TRACKS_ADDED + 1))
fi
if [ "$CREATE_AC3" = true ]; then
    TRACKS_ADDED=$((TRACKS_ADDED + 1))
fi

# Nothing new to add: exit before any temp files or output are created, so the input
# is not touched in overwrite mode.
if [ "$TRACKS_ADDED" -eq 0 ]; then
    echo "Nothing to do: '$INPUT' already has a suitable AAC 2-channel track (ID $REUSE_AAC_ID) and no AC-3 5.1 track is needed. No output written."
    if [ "$REUSE_AAC_DEFAULT" != true ]; then
        echo "Note: track $REUSE_AAC_ID is not flagged default. The file was left unchanged."
    fi
    exit 0
fi

# Build dynamic track order. Input file indexes follow the order the inputs are passed to
# mkvmerge, so they depend on which new tracks are created:
# 1. Video track(s) from original file (0:<id>)
# 2. New stereo AAC track (1:0), only when created
# 3. New AC-3 5.1 track (next input index), only when created
# 4. All original audio tracks (0:<id>), shifted down by the number of new tracks.
#    A reused AAC track stays in this original audio order.
# 5. Subtitles and any other tracks (0:<id>)
VIDEO_ORDER=$(echo "$MKV_JSON" | jq -r '[.tracks[] | select(.type == "video") | "0:\(.id)"] | join(",")')
AUDIO_ORDER=$(echo "$MKV_JSON" | jq -r '[.tracks[] | select(.type == "audio") | "0:\(.id)"] | join(",")')
OTHER_ORDER=$(echo "$MKV_JSON" | jq -r '[.tracks[] | select(.type != "video" and .type != "audio") | "0:\(.id)"] | join(",")')

TRACK_ORDER_LIST=()
[ -n "$VIDEO_ORDER" ] && TRACK_ORDER_LIST+=("$VIDEO_ORDER")
NEXT_INPUT=1
if [ "$CREATE_AAC" = true ]; then
    TRACK_ORDER_LIST+=("${NEXT_INPUT}:0")
    NEXT_INPUT=$((NEXT_INPUT + 1))
fi
if [ "$CREATE_AC3" = true ]; then
    TRACK_ORDER_LIST+=("${NEXT_INPUT}:0")
fi
[ -n "$AUDIO_ORDER" ] && TRACK_ORDER_LIST+=("$AUDIO_ORDER")
[ -n "$OTHER_ORDER" ] && TRACK_ORDER_LIST+=("$OTHER_ORDER")
TRACK_ORDER=$(IFS=,; echo "${TRACK_ORDER_LIST[*]}")


# Create temporary output in the SAME directory as $INPUT for an atomic overwrite
TMP_DIR=$(mktemp -d)
INPUT_DIR=$(dirname "$INPUT")
INPUT_BASE=$(basename "$INPUT")
BASENAME="${INPUT%.*}"

# Ensure both temp directory and incomplete temp output are cleaned up on failure
if [ "$OVERWRITE" = true ]; then
    TARGET_OUTPUT=$(mktemp "${INPUT_DIR}/.${INPUT_BASE}.XXXXXX.mkv")
    trap 'rm -rf "$TMP_DIR" "$TARGET_OUTPUT"' EXIT
else
    TARGET_OUTPUT="${BASENAME}_stereo.mkv"
    trap 'rm -rf "$TMP_DIR"' EXIT
fi

RAW_AUDIO="$TMP_DIR/extracted_audio"
AAC_AUDIO="$TMP_DIR/stereo.m4a"

# Extract codec string and channel count for the selected track from MKV_JSON
CODEC=$(echo "$MKV_JSON" | jq -r --argjson id "$TRACK_ID" '.tracks[] | select(.id == $id) | .codec // "Unknown"')

echo "Extracting best English audio track { ID: $TRACK_ID, Codec: $CODEC, Channels: $CHANNELS }..."
mkvextract "$INPUT" tracks "${TRACK_ID}:${RAW_AUDIO}"

# Compression & loudness normalization chain:
# - acompressor: tames loud peaks above -20dB with a 4:1 ratio and a 2dB makeup gain
#   (loudnorm restores the level anyway)
# - loudnorm: brings overall loudness to a consistent -16 LUFS (standard for stereo/mobile playback)
DRC_FILTER="acompressor=threshold=-20dB:ratio=4:attack=10:release=300:knee=3:makeup=2dB,loudnorm=I=-16:TP=-1.5:LRA=11"

if [ "$CREATE_AAC" = true ]; then
    echo "Converting to 160kbps 48kHz stereo AAC with dynamic range compression..."
    if [ "$CHANNELS" -gt 2 ]; then
        # Downmix surround to stereo: center (FC) at 0.70 (2x the 0.35 front level, ~+6dB of dialogue lift),
        # and a 0.20 LFE contribution to both channels. Lower summed gain leaves headroom before loudnorm.
        PAN_FILTER="pan=stereo|FL=0.35*FL+0.70*FC+0.25*BL+0.25*SL+0.20*LFE|FR=0.35*FR+0.70*FC+0.25*BR+0.25*SR+0.20*LFE"
        ffmpeg -y -v error -i "$RAW_AUDIO" -af "${PAN_FILTER},${DRC_FILTER}" -ar 48000 -c:a aac -b:a 160k "$AAC_AUDIO"
    else
        # Already stereo or mono: encode directly without surround pan mapping
        ffmpeg -y -v error -i "$RAW_AUDIO" -ac 2 -af "${DRC_FILTER}" -ar 48000 -c:a aac -b:a 160k "$AAC_AUDIO"
    fi
fi

# AC-3 5.1 track (640kbps, 48kHz). No loudness/DRC processing is applied so the
# surround mix keeps its original dynamics. 7.1 sources are downmixed to 5.1 by
# folding the side channels into the back pair at -3dB each.
AC3_AUDIO="$TMP_DIR/surround.ac3"
if [ "$CREATE_AC3" = true ]; then
    if [ "$CHANNELS" -eq 8 ]; then
        echo "Encoding 640kbps 48kHz AC-3 5.1 (downmixed from 7.1)..."
        AC3_PAN_FILTER="pan=5.1|FL=FL|FR=FR|FC=FC|LFE=LFE|BL=0.707*BL+0.707*SL|BR=0.707*BR+0.707*SR"
        ffmpeg -y -v error -i "$RAW_AUDIO" -af "$AC3_PAN_FILTER" -ac 6 -ar 48000 -c:a ac3 -b:a 640k "$AC3_AUDIO"
    else
        echo "Encoding 640kbps 48kHz AC-3 5.1..."
        ffmpeg -y -v error -i "$RAW_AUDIO" -ac 6 -ar 48000 -c:a ac3 -b:a 640k "$AC3_AUDIO"
    fi
fi

# Build flags to turn off 'default-track' on all existing audio tracks.
# Default rule: exactly one stereo AAC track is default, and no other audio track is.
#   - New AAC created: it becomes the default (below); all original audio is set off.
#   - Existing AAC reused: that track is set default and all other original audio is set off.
DEFAULT_OFF_FLAGS=()
for id in $ALL_AUDIO_IDS; do
    if [ "$CREATE_AAC" = false ] && [ "$id" = "$REUSE_AAC_ID" ]; then
        continue
    fi
    DEFAULT_OFF_FLAGS+=(--default-track-flag "${id}:0")
done
if [ "$CREATE_AAC" = false ]; then
    DEFAULT_OFF_FLAGS+=(--default-track-flag "${REUSE_AAC_ID}:1")
fi

# Options for the new AAC input (default) when it is created
AAC_ARGS=()
if [ "$CREATE_AAC" = true ]; then
    AAC_ARGS=(
        --language 0:eng
        --track-name "0:English 2-ch stereo"
        --default-track-flag 0:1
        "$AAC_AUDIO"
    )
fi

# Options for the optional AC-3 input (kept non-default; AAC stereo stays default)
AC3_ARGS=()
if [ "$CREATE_AC3" = true ]; then
    AC3_ARGS=(
        --language 0:eng
        --track-name "0:English 5.1 AC-3"
        --default-track-flag 0:0
        "$AC3_AUDIO"
    )
fi

echo "Merging new audio track(s) back into MKV and reordering tracks..."
mkvmerge -o "$TARGET_OUTPUT" \
    --track-order "$TRACK_ORDER" \
    "${DEFAULT_OFF_FLAGS[@]}" \
    "$INPUT" \
    ${AAC_ARGS[@]+"${AAC_ARGS[@]}"} \
    ${AC3_ARGS[@]+"${AC3_ARGS[@]}"}

# Verify the new MKV is valid and contains the expected number of
# tracks (original + TRACKS_ADDED, which is 1 or 2 here), that it has a default
# audio track, and the newer filesize is larger than the original filesize
ORIG_TRACK_COUNT=$(echo "$MKV_JSON" | jq '.tracks | length')
NEW_MKV_JSON=$(mkvmerge -J "$TARGET_OUTPUT")
NEW_TRACK_COUNT=$(echo "$NEW_MKV_JSON" | jq '.tracks | length')
NEW_DEFAULT_AUDIO=$(echo "$NEW_MKV_JSON" | jq '[.tracks[] | select(.type == "audio" and (.properties.default_track // false))] | length')
ORIG_SIZE=$(wc -c < "$INPUT" | tr -d ' ')
NEW_SIZE=$(wc -c < "$TARGET_OUTPUT" | tr -d ' ')

if [ ! -s "$TARGET_OUTPUT" ]; then
    echo "Error: Output file has no content." >&2
    exit 1
fi

if [ "$NEW_TRACK_COUNT" -ne $((ORIG_TRACK_COUNT + TRACKS_ADDED)) ]; then
    echo "Error: Track count verification failed (expected $((ORIG_TRACK_COUNT + TRACKS_ADDED)), got $NEW_TRACK_COUNT)." >&2
    exit 1
fi

if [ "$NEW_DEFAULT_AUDIO" -lt 1 ]; then
    echo "Error: No default audio track in '$TARGET_OUTPUT'." >&2
    exit 1
fi

if [ "$CREATE_AC3" = true ]; then
    AC3_OK=$(echo "$NEW_MKV_JSON" | jq -r '[.tracks[] | select(.type == "audio" and .codec == "AC-3" and .properties.audio_channels == 6)] | length')
    if [ "$AC3_OK" -lt 1 ]; then
        echo "Error: AC-3 5.1 track verification failed in '$TARGET_OUTPUT'." >&2
        exit 1
    fi
fi

if [ "$NEW_SIZE" -le "$ORIG_SIZE" ]; then
    echo "Error: File size verification failed (new size ${NEW_SIZE}B is not greater than original ${ORIG_SIZE}B)." >&2
    exit 1
fi

if [ "$OVERWRITE" = true ]; then
    chmod --reference="$INPUT" "$TARGET_OUTPUT" 2>/dev/null || true
    mv -f "$TARGET_OUTPUT" "$INPUT"
    touch -a -d "$ORIG_ATIME" "$INPUT"
    touch -m -d "$ORIG_MTIME" "$INPUT"
    echo "Done! Verified and safely overwritten: $INPUT"
else
    echo "Done! Verified and saved to: $TARGET_OUTPUT"
fi
