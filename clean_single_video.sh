#!/usr/bin/env bash
set -euo pipefail

INPUT="$1"
OUTPUT_DIR="${2:-clean}"

[ -f "$INPUT" ] || { echo "File not found: $INPUT" >&2; exit 1; }

BASE="$(basename "$INPUT")"
BASE_NO_EXT="${BASE%.*}"
OUT="$OUTPUT_DIR/${BASE_NO_EXT}_clean.mp4"

mkdir -p "$OUTPUT_DIR"

# Target: 70% of the original file size
INPUT_MIB=$(stat -c%s "$INPUT" | awk '{printf "%.2f", $1 / 1048576}')
TARGET_MIB=$(awk -v s="$INPUT_MIB" 'BEGIN {printf "%.2f", s * 0.70}')

DURATION=$(ffprobe -v error -show_entries format=duration \
  -of default=noprint_wrappers=1:nokey=1 "$INPUT")

AUDIO_KBPS=96

VIDEO_KBPS=$(awk -v size="$TARGET_MIB" -v dur="$DURATION" -v audio="$AUDIO_KBPS" \
  'BEGIN {
    total = (size * 8192 * 0.97) / dur;
    video = total - audio;
    if (video < 100) video = 100;
    printf "%d", int(video);
  }')

ffmpeg -y \
  -i "$INPUT" \
  -map 0:v:0 \
  -map 0:a:0? \
  -map_metadata -1 \
  -map_metadata:s:v:0 -1 \
  -map_metadata:s:a:0 -1 \
  -map_chapters -1 \
  -fflags +bitexact \
  -c:v libx264 \
  -preset medium \
  -b:v "${VIDEO_KBPS}k" \
  -pass 2 \
  -c:a aac \
  -b:a "${AUDIO_KBPS}k" \
  -movflags +faststart \
  "$OUT"

exiftool -overwrite_original -all= "$OUT"

rm -f ffmpeg2pass-0.log*

echo "Cleaned video created: $OUT"
