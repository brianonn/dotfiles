#!/usr/bin/env bash
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

# Build dynamic track order:
# 1. Video track(s) from original file (0:<id>)
# 2. New stereo AAC track from second input file (1:0) -> becomes Audio Track #1
# 3. All original audio tracks (0:<id>) -> shifted down by 1 slot
# 4. Subtitles and any other tracks (0:<id>)
VIDEO_ORDER=$(echo "$MKV_JSON" | jq -r '[.tracks[] | select(.type == "video") | "0:\(.id)"] | join(",")')
AUDIO_ORDER=$(echo "$MKV_JSON" | jq -r '[.tracks[] | select(.type == "audio") | "0:\(.id)"] | join(",")')
OTHER_ORDER=$(echo "$MKV_JSON" | jq -r '[.tracks[] | select(.type != "video" and .type != "audio") | "0:\(.id)"] | join(",")')

TRACK_ORDER_LIST=()
[ -n "$VIDEO_ORDER" ] && TRACK_ORDER_LIST+=("$VIDEO_ORDER")
TRACK_ORDER_LIST+=("1:0")
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
CHANNELS=$(echo "$MKV_JSON" | jq -r --argjson id "$TRACK_ID" '.tracks[] | select(.id == $id) | .properties.audio_channels // 2')

echo "Extracting best English audio track { ID: $TRACK_ID, Codec: $CODEC, Channels: $CHANNELS }..."
mkvextract "$INPUT" tracks "${TRACK_ID}:${RAW_AUDIO}"

echo "Converting to 160kbps 48kHz stereo AAC with dynamic range compression..."

# Compression & loudness normalization chain:
# - acompressor: tames loud peaks above -20dB with a 4:1 ratio and gentle 6dB makeup gain
# - loudnorm: brings overall loudness to a consistent -16 LUFS (standard for stereo/mobile playback)
DRC_FILTER="acompressor=threshold=-20dB:ratio=4:attack=20:release=250:makeup=6dB,loudnorm=I=-16:TP=-1.5:LRA=11"

if [ "$CHANNELS" -gt 2 ]; then
    # Downmix surround to stereo with center channel (FC) boosted to 1.4x (approx +3dB)
    # Adjustable Gain: If dialogue is still too quiet, raise 1.4*FC to 1.6*FC (roughly +4 dB)
    #    if it distorts on loud scenes, lower it to 1.2*FC or add loudnorm to the filter string
    # Also applies the Dynamic Range and Compression Filter from  above.
    PAN_FILTER="pan=stereo|FL=0.5*FL+1.4*FC+0.5*BL+0.5*SL|FR=0.5*FR+1.4*FC+0.5*BR+0.5*SR"
    ffmpeg -y -v error -i "$RAW_AUDIO" -af "${PAN_FILTER},${DRC_FILTER}" -ar 48000 -c:a aac -b:a 160k "$AAC_AUDIO"
else
    # Already stereo or mono: encode directly without surround pan mapping
    ffmpeg -y -v error -i "$RAW_AUDIO" -ac 2 -af "${DRC_FILTER}" -ar 48000 -c:a aac -b:a 160k "$AAC_AUDIO"
fi

# Build flags to turn off 'default-track' on all existing audio tracks
DEFAULT_OFF_FLAGS=()
for id in $ALL_AUDIO_IDS; do
    DEFAULT_OFF_FLAGS+=(--default-track-flag "${id}:0")
done

echo "Merging stereo AAC back into MKV and reordering tracks..."
mkvmerge -o "$TARGET_OUTPUT" \
    --track-order "$TRACK_ORDER" \
    "${DEFAULT_OFF_FLAGS[@]}" \
    "$INPUT" \
    --language 0:eng \
    --track-name "0:English 2-ch stereo" \
    --default-track-flag 0:1 \
    "$AAC_AUDIO"

# Verify the new MKV is valid and contains the expected number of
# tracks, and the newer filesize is larger than the original filesize
ORIG_TRACK_COUNT=$(echo "$MKV_JSON" | jq '.tracks | length')
NEW_TRACK_COUNT=$(mkvmerge -J "$TARGET_OUTPUT" | jq '.tracks | length')
ORIG_SIZE=$(wc -c < "$INPUT" | tr -d ' ')
NEW_SIZE=$(wc -c < "$TARGET_OUTPUT" | tr -d ' ')

if [ ! -s "$TARGET_OUTPUT" ]; then
    echo "Error: Output file has no content." >&2
    exit 1
fi

if [ "$NEW_TRACK_COUNT" -ne $((ORIG_TRACK_COUNT + 1)) ]; then
    echo "Error: Track count verification failed (expected $((ORIG_TRACK_COUNT + 1)), got $NEW_TRACK_COUNT)." >&2
    exit 1
fi

if [ "$NEW_SIZE" -le "$ORIG_SIZE" ]; then
    echo "Error: File size verification failed (new size ${NEW_SIZE}B is not greater than original ${ORIG_SIZE}B)." >&2
    exit 1
fi

if [ "$OVERWRITE" = true ]; then
    chmod --reference="$INPUT" "$TARGET_OUTPUT" 2>/dev/null || true
    mv -f "$TARGET_OUTPUT" "$INPUT"
    echo "Done! Verified and safely overwritten: $INPUT"
else
    echo "Done! Verified and saved to: $TARGET_OUTPUT"
fi
