#!/usr/bin/env bash

# clean_up_video.sh
#
# Author: Alessandro Gubitosi
# License: public domain
# ---

# Batch-compress and clean .mp4 videos.
#
# The script processes every .mp4 file in a source folder, re-encodes it to
# H.264/AAC for broad compatibility, removes metadata, chapters, and EXIF/GPS
# data, and saves the cleaned copy in a separate output folder.
#
# The output size is targeted to approximately 70% of the original file size.
# Original files are never modified.
#
# USAGE
# -----
#
#   ./clean_up_video.sh [SOURCE_FOLDER] [OUTPUT_FOLDER] [THREADS] [AUDIO_KBPS]
#
# Arguments:
#
#   SOURCE_FOLDER  Folder containing the .mp4 files to process. Default: "."
#   OUTPUT_FOLDER  Folder where cleaned videos will be saved. Default: "clean"
#   THREADS        Maximum number of FFmpeg CPU threads. Default: 2
#   AUDIO_KBPS     Audio bitrate in kbps. Default: 96
#
# Examples:
#
#   Process MP4 files in the current folder and save them to ./clean:
#
#       ./clean_up_video.sh
#
#   Process /path/to/videos and save the results in /path/to/output:
#
#       ./clean_up_video.sh /path/to/videos /path/to/output
#
#   Process the current folder, save results to ./clean, use 2 CPU threads,
#   and encode audio at 96 kbps:
#
#       ./clean_up_video.sh . clean 2 96
#
#   Compress to approximately 50% of the original size:
#
#       Change "0.70" in the TARGET_RATIO variable below to "0.50".
#
# Requirements:
#
#   - ffmpeg
#   - ffprobe
#   - exiftool
#
# Install dependencies on Debian/Ubuntu:
#
#   sudo apt install ffmpeg libimage-exiftool-perl

# Stop the script on errors, undefined variables, or failed pipelines
set -euo pipefail

# Source folder containing the input MP4 files
SRC_DIR="${1:-.}"

# Destination folder for cleaned videos
OUT_DIR="${2:-clean}"

# Maximum number of CPU threads used by the x264 video encoder
THREADS="${3:-2}"

# Audio bitrate in kilobits per second
AUDIO_KBPS="${4:-96}"

# Desired output size as a ratio of the input size
# 0.70 means: target approximately 70% of the original file size
TARGET_RATIO="0.70"

# Create the output folder if it does not exist
mkdir -p "$OUT_DIR"

# Process every MP4 file in the source folder
for f in "$SRC_DIR"/*.mp4; do

  # Skip if the glob does not match any file
  [ -e "$f" ] || continue

  # Build the output filename from the input filename
  base="$(basename "$f" .mp4)"
  out="$OUT_DIR/${base}_clean.mp4"

  echo "Processing: $f"

  # Get the input file size in MiB
  input_mib=$(stat -c%s "$f" | awk '{printf "%.2f", $1 / 1048576}')

  # Get the input duration in seconds
  duration=$(ffprobe -v error -show_entries format=duration \
    -of default=noprint_wrappers=1:nokey=1 "$f")

  # Calculate the target output size in MiB
  target_mib=$(awk -v size="$input_mib" -v ratio="$TARGET_RATIO" \
    'BEGIN {printf "%.2f", size * ratio}')

  # Calculate the video bitrate required to reach the target size.
  #
  # Formula:
  #   total bitrate (kbps) =
  #     (target size in MiB * 8192 * safety factor) / duration in seconds
  #
  # The audio bitrate is then subtracted from the total bitrate.
  # The safety factor (0.97) reserves space for the MP4 container overhead.
  video_kbps=$(awk -v size="$target_mib" -v dur="$duration" -v audio="$AUDIO_KBPS" \
    'BEGIN {
      total = (size * 8192 * 0.97) / dur;
      video = total - audio;
      if (video < 100) video = 100;
      printf "%d", int(video);
    }')

  echo "Input size: ${input_mib} MiB"
  echo "Target size: ${target_mib} MiB"
  echo "Video bitrate: ${video_kbps} kbps"
  echo "Audio bitrate: ${AUDIO_KBPS} kbps"

  # First pass: analyze the video to prepare an efficient two-pass encode.
  #
  # -y: overwrite existing temporary/output files without asking
  # -i: input video file
  # -map 0:v:0: keep only the first video stream
  # -map 0:a:0?: keep the first audio stream only if it exists
  # -map_metadata -1: remove global container metadata
  # -map_metadata:s:v:0 -1: remove metadata attached to the first video stream
  # -map_metadata:s:a:0 -1: remove metadata attached to the first audio stream
  # -map_chapters -1: remove chapters
  # -c:v libx264: encode video using the H.264/AVC codec
  # -preset medium: balance encoding speed, CPU usage, and compression
  # -b:v: set the target video bitrate calculated above
  # -pass 1: first pass; analyzes the video without producing the final file
  # -an: disable audio processing in the analysis pass
  # -f null /dev/null: discard the temporary first-pass output
  ffmpeg -y \
    -i "$f" \
    -threads "$THREADS" \
    -map 0:v:0 \
    -map 0:a:0? \
    -map_metadata -1 \
    -map_metadata:s:v:0 -1 \
    -map_metadata:s:a:0 -1 \
    -map_chapters -1 \
    -c:v libx264 \
    -preset medium \
    -b:v "${video_kbps}k" \
    -pass 1 \
    -an \
    -f null /dev/null

  # Second pass: create the final compressed and cleaned MP4 file.
  #
  # -y: overwrite the output file without asking, if it exists
  # -i: input video file
  # -map 0:v:0: keep only the first video stream
  # -map 0:a:0?: keep the first audio stream only if it exists
  # -map_metadata -1: remove global container metadata
  # -map_metadata:s:v:0 -1: remove metadata attached to the first video stream
  # -map_metadata:s:a:0 -1: remove metadata attached to the first audio stream
  # -map_chapters -1: remove chapters
  # -fflags +bitexact: avoid writing unnecessary FFmpeg/encoder metadata
  # -c:v libx264: encode video using H.264/AVC for maximum compatibility
  # -preset medium: balance encoding speed, CPU usage, and compression
  # -b:v: apply the calculated target video bitrate
  # -pass 2: second pass; creates the final file using the first-pass analysis
  # -c:a aac: encode audio using AAC
  # -b:a: set the audio bitrate
  # -movflags +faststart: move the MP4 index to the beginning of the file,
  #                       improving preview and progressive playback
  # "$out": final cleaned output file
  ffmpeg -y \
    -i "$f" \
    -threads "$THREADS" \
    -map 0:v:0 \
    -map 0:a:0? \
    -map_metadata -1 \
    -map_metadata:s:v:0 -1 \
    -map_metadata:s:a:0 -1 \
    -map_chapters -1 \
    -fflags +bitexact \
    -c:v libx264 \
    -preset medium \
    -b:v "${video_kbps}k" \
    -pass 2 \
    -c:a aac \
    -b:a "${AUDIO_KBPS}k" \
    -movflags +faststart \
    "$out"

  # Remove any remaining writable metadata from the generated MP4.
  #
  # -overwrite_original: modify the file directly, without creating an "_original" backup
  # -all=: remove all writable embedded metadata
  exiftool \
    -overwrite_original \
    -all= \
    "$out"

  # Remove FFmpeg two-pass temporary log files
  rm -f ffmpeg2pass-0.log*

  echo "Created: $out"
done

echo "Done"
