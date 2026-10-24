#!/usr/bin/env bash
#
# clean_videos.sh
#
# Processes all .mp4 files in a folder:
# - Re-encodes them to H.264/AAC for better compatibility (e.g. SimpleX)
# - Removes metadata, chapters, and EXIF/GPS data using FFmpeg and ExifTool
# - Saves the results to a separate output folder without modifying the originals
#
# Usage:
#   ./clean_videos.sh [SOURCE_FOLDER] [OUTPUT_FOLDER] [THREADS]
#
# Examples:
#   ./clean_videos.sh
#       Processes MP4 files in the current folder and saves them to ./clean
#
#   ./clean_videos.sh /path/to/videos /path/to/output
#       Processes /path/to/videos and saves the results in /path/to/output
#
#   ./clean_videos.sh . clean 2
#       Processes the current folder, saves results to ./clean,
#       and limits FFmpeg to 2 threads
#
# Requirements:
#   - ffmpeg
#   - exiftool
#
# Install dependencies on Debian/Ubuntu:
#   sudo apt install ffmpeg libimage-exiftool-perl

set -euo pipefail

SRC_DIR="${1:-.}"
OUT_DIR="${2:-clean}"
THREADS="${3:-2}"

mkdir -p "$OUT_DIR"

for f in "$SRC_DIR"/*.mp4; do
  [ -e "$f" ] || continue

  base="$(basename "$f" .mp4)"
  out="$OUT_DIR/${base}_clean.mp4"

  echo "Elaboro: $f"

  ffmpeg -y -i "$f" \
    -map_metadata -1 \
    -map_chapters -1 \
    -fflags +bitexact \
    -c:v libx264 \
    -preset medium \
    -crf 23 \
    -threads "$THREADS" \
    -vf "scale=-2:1080" \
    -c:a aac -b:a 128k \
    -movflags +faststart \
    "$out"

  exiftool -overwrite_original \
    -all= \
    -tagsfromfile @ \
    -XMP:all= \
    -EXIF:all= \
    -GPS:all= \
    "$out"

  echo "Creato: $out"
done

echo "Completato."
