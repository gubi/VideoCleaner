# PrivacyVideoSanitizer
Removes all unnecessary metadata from downloaded videos

The script processes all .mp4 video in a folder, then re-encodes them to be most supported though devices, removes metadata, chapters, and EXIF/GPS data.
It use only FFmpeg and ExifTool.
Simple, clean, direct.

&nbsp;

### Usage
Give file permission to execute:
```bash
$ chmod +x clean_videos.sh
```
Then launch:
```bash
$ ./clean_videos.sh . clean 2
```
- First argument: source folder
- Second argument: output folder
- Third argument: max thread/core to use (default `2`)

By reducing `-threads` (eg. with `-threads 1`) you obtain a minimal impact on your `CPU` but the waiting time comes more longer.
