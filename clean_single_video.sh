#!/usr/bin/env bash

# clean_single_video.sh
#
# Author: Alessandro Gubitosi
# License: public domain
# ---

# Clean and compress a single downloaded MP4 video.
#
# The script re-encodes the input video to widely supported H.264/AAC,
# removes metadata, chapters, and EXIF/GPS data, and targets an output file
# size equal to a configurable percentage of the original file size.
#
# It is designed to be called by ReClip after a video download completes.
# The original input file is not modified: the cleaned video is written to
# the output path provided as the second argument.
#
# USAGE
# -----
#
#   clean_single_video.sh INPUT.mp4 OUTPUT.mp4
#
# Arguments:
#
#   INPUT.mp4   Path to the downloaded MP4 file to clean.
#   OUTPUT.mp4  Path where the cleaned MP4 file will be created.
#
# Example:
#
#   ./clean_single_video.sh /path/to/video.mp4 /path/to/video_cleaning.mp4
#
# Configuration:
#
#   TARGET_RATIO  Desired output size as a ratio of the input size.
#                 0.70 means: target approximately 70% of the original size.
#   AUDIO_KBPS    Audio bitrate in kilobits per second.
#   THREADS       Maximum number of FFmpeg CPU threads.
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

# Usage:
#   clean_single_video.sh INPUT.mp4 OUTPUT.mp4

INPUT="$1"
OUT="$2"

# Target output size: 70% of the input file size
TARGET_RATIO="0.70"

# Audio bitrate in kbps
AUDIO_KBPS="96"

# Maximum number of FFmpeg threads
THREADS="2"

# Input file size in MiB
INPUT_MIB=$(stat -c%s "$INPUT" | awk '{printf "%.2f", $1 / 1048576}')

# Target output size in MiB
TARGET_MIB=$(awk -v size="$INPUT_MIB" -v ratio="$TARGET_RATIO" \
  'BEGIN {printf "%.2f", size * ratio}')

# Input duration in seconds
DURATION=$(ffprobe -v error -show_entries format=duration \
  -of default=noprint_wrappers=1:nokey=1 "$INPUT")

# Calculate the video bitrate required to reach the target size.
#
# Formula:
#   total bitrate (kbps) =
#     (target size in MiB * 8192 * safety factor) / duration in seconds
#
# The audio bitrate is then subtracted from the total bitrate.
# The safety factor (0.97) reserves space for MP4 container overhead.
VIDEO_KBPS=$(awk -v size="$TARGET_MIB" -v dur="$DURATION" -v audio="$AUDIO_KBPS" \
  'BEGIN {
    total = (size * 8192 * 0.97) / dur;
    video = total - audio;
    if (video < 100) video = 100;
    printf "%d", int(video);
  }')

PASSLOG="$OUT.passlog"

# First pass: analyze the video to prepare an efficient two-pass encode.
#
# -y: overwrite temporary/output files without asking
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
# -passlogfile: set the location of the two-pass statistics file
# -an: disable audio processing in the analysis pass
# -f null /dev/null: discard the temporary first-pass output
ffmpeg -y -i "$INPUT" \
  -threads "$THREADS" \
  -map 0:v:0 -map 0:a:0? \
  -map_metadata -1 -map_metadata:s:v:0 -1 -map_metadata:s:a:0 -1 \
  -map_chapters -1 \
  -c:v libx264 -preset medium -b:v "${VIDEO_KBPS}k" \
  -pass 1 -passlogfile "$PASSLOG" \
  -an -f null /dev/null

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
# -passlogfile: use the same two-pass statistics file created above
# -c:a aac: encode audio using AAC
# -b:a: set the audio bitrate
# -movflags +faststart: move the MP4 index to the beginning of the file,
#                       improving preview and progressive playback
# "$OUT": final cleaned output file
ffmpeg -y -i "$INPUT" \
  -threads "$THREADS" \
  -map 0:v:0 -map 0:a:0? \
  -map_metadata -1 -map_metadata:s:v:0 -1 -map_metadata:s:a:0 -1 \
  -map_chapters -1 \
  -fflags +bitexact \
  -c:v libx264 -preset medium -b:v "${VIDEO_KBPS}k" \
  -pass 2 -passlogfile "$PASSLOG" \
  -c:a aac -b:a "${AUDIO_KBPS}k" \
  -movflags +faststart \
  "$OUT"

# Remove the temporary FFmpeg two-pass statistics files
rm -f "${PASSLOG}"-0.log* "${PASSLOG}".log*

# Remove any remaining writable metadata from the generated MP4.
#
# -overwrite_original: modify the file directly, without creating an "_original" backup
# -all=: remove all writable embedded metadata
exiftool -overwrite_original -all= "$OUT"
