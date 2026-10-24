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

  echo "Loading: $f"

  ffmpeg
    -y                      # Overwrite the output file (if exists) without asking
    -i "$f" \               # The input file
    -map_metadata -1 \      # Stripcontainer metadata: title, author, comments, creation date, GPS and others tags, when present
    -map_chapters -1 \      # Remove chapters if present
    -fflags +bitexact \     # Avoid FFmpeg version writing and other unnecessary encoding metadata
    -c:v libx264 \          # Recoved the video to `H.264/AVC`, majourly compatible
    -preset medium \        # Bilance speed and encoding, CPU usage and compression
    -crf 23 \               # Sets quality: lower values means more quality but bigger files
    -threads "$THREADS" \   # Limits the number of thread/cores used by `libx264`
    -vf "scale=-2:1080" \   # Ridimensiona il video a 1080p mantenendo le proporzioni originali; -2 calcola automaticamente la larghezza corretta
    -c:a aac -b:a 128k \    # Recode audio in AAC
    -movflags +faststart \  # Move MP4 metadata to the beginning of file, useful for previews and progressive loadings
    "$out"                  # The output file

  exiftool
    -overwrite_original \   # Edit directly this file, withount creating the `_original` copy
    -all= \                 # Remove all file writeable
    -tagsfromfile @ \       # Reload tags from the file itself - Ensure that subsequent removals are applied correctly
    -XMP:all= \             # Remove XMP metadata
    -EXIF:all= \            # Remove EXIF metadata
    -GPS:all= \             # Remove geolocaliation metadata
    "$out"                  # The output file

  echo "Created: $out"
done

echo "Done"
