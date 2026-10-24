# VideoSanitizer

A simple Bash script to batch-clean `.mp4` videos for private sharing.

It re-encodes videos to widely supported **H.264/AAC MP4**, removes unnecessary metadata, chapters, and EXIF/GPS data, and saves the cleaned copies in a separate output folder. Original files are never modified.

Uses only [FFmpeg](https://ffmpeg.org/) and [ExifTool](https://exiftool.org/).

## Features

- Batch-processes every `.mp4` file in a source folder
- Re-encodes video to H.264 and audio to AAC for broad device compatibility
- Scales video to 1080p while preserving the original aspect ratio
- Removes container metadata, chapters, XMP, EXIF, and GPS data
- Keeps original videos untouched
- Lets you limit CPU usage by setting the number of FFmpeg threads

## Requirements

- Bash
- FFmpeg
- ExifTool

On Debian/Ubuntu, install them with:

```bash
sudo apt update
sudo apt install ffmpeg libimage-exiftool-perl
```

## Installation

Clone the repository:

```bash
git clone [https://github.com/YOUR_USERNAME/PrivacyVideoSanitizer.git](https://github.com/YOUR_USERNAME/PrivacyVideoSanitizer.git)
cd PrivacyVideoSanitizer
```

Make the script executable:

```bash
chmod +x clean_videos.sh
```

## Usage

Run the script from the folder containing your videos:

```bash
./clean_videos.sh
```

Or specify the source folder, output folder, and maximum number of threads:

```bash
./clean_videos.sh ./videos ./clean 2
```

### Arguments

| Argument | Description | Default |
|---|---|---|
| `SOURCE_FOLDER` | Folder containing the `.mp4` files to process | `.` |
| `OUTPUT_FOLDER` | Folder where cleaned videos are saved | `clean` |
| `THREADS` | Maximum number of FFmpeg threads/cores to use | `2` |

### Examples

Process the current folder and save cleaned files to `./clean`:

```bash
./clean_videos.sh
```

Process `./videos`, save output to `./output`, and use 1 thread:

```bash
./clean_videos.sh ./videos ./output 1
```

Lower thread counts reduce CPU usage but increase processing time. For minimal CPU impact, use `1`.

## What the script does

For each input video, the script:

1. Re-encodes the video stream using `libx264` (H.264).
2. Re-encodes the audio stream using AAC at 128 kbps.
3. Scales the video to a maximum height of 1080 pixels.
4. Removes global metadata and chapters.
5. Removes XMP, EXIF, and GPS metadata with ExifTool.
6. Saves the result as `<original-name>_clean.mp4` in the output folder.

## Important notes

- The script processes files matching `*.mp4` in the **top level** of the source folder; it does not recursively process subfolders.
- Re-encoding is intentionally used to improve compatibility and remove potentially problematic codecs or metadata.
- Metadata removal reduces privacy risks, but it cannot guarantee the removal of information embedded in unusual tracks or visually present in the video itself.

## License

This project is licensed under the [MIT License](LICENSE).
