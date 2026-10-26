<img width="1200" height="450" alt="683437326-7f5d6f6b-d564-460e-bb64-c4c3eee5bcb9_github" src="https://github.com/user-attachments/assets/e9ab1631-b060-4191-8fd9-a5c687afa70b" />

# VideoCleaner

A simple Bash script to batch-clean `.mp4` videos for private sharing.

It re-encodes videos to widely supported **H.264/AAC MP4**, removes unnecessary metadata, chapters, and EXIF/GPS data, and saves the cleaned copies in a separate output folder. Original files are never modified.

Uses only [FFmpeg](https://ffmpeg.org/) and [ExifTool](https://exiftool.org/).<br>
Pure, simple, direct.<br>
100% Shell script.<br>

&nbsp;

> ### Always be paranoid
> _Congratulations! You’ve just downloaded a whole bunch of videos from the web!_<br>
> _But do you really know what’s hiding inside those files in your folder?!_<br>
> _Exactly how many videos are there?_<br>
>
> _Come on — do you honestly intend to examine every single downloaded clip, every video you’ve grabbed from social media or external libraries...?_<br>
> _Of course not._<br>
> _You’d end up wasting an endless amount of time inspetting data over dozens of videos in that folder..._<br>
>
> #### The problem
> Some files may contain tracking systems, cryptocurrency malware, or mining programs.<br>
> They can use them as a confirm that you actually possess the file... so I know that you saw.<br>
> Most of that are AI-generated files.<br>
> But the AI Agents are always active and can use us, exactly in this way: just waiting data comes back.<br>
> And by default, you simply AGREED the moment you performed the action...<br>
> <br>
> So, be careful — don’t let yourself get infected or leave any traces behind.
>
> <br>
>
> ##### See more
>
> - Shocking declarations: https://mega.nz/file/DX5zUDjJ#KMCsGXvCYgSiGwrVr3NDIM9ZTM55CInK_qKXRAFe-tM
> - [The Metadata Problem: How Your Documents Reveal Your Identity, Infrastructure, and Projects](https://medium.com/@ingvarpavlovich/the-metadata-problem-how-your-documents-reveal-your-identity-infrastructure-and-projects-d9dd0ea41efb)

&nbsp;

## Useful resources

Exif tool online service: [exif.tools](https://exif.tools/)

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
git clone https://github.com/gubi/VideoCleaner.git
cd VideoCleaner
```

Make the script executable:

```bash
chmod +x clean_up_video.sh
```

## Usage

Run the script from the folder containing your videos:

```bash
./clean_up_video.sh [SOURCE_FOLDER] [OUTPUT_FOLDER] [THREADS] [AUDIO_KBPS]
```

Or specify the source folder, output folder, and maximum number of threads:

```bash
./clean_up_video.sh ./videos ./clean 2
```

### Arguments

| Argument | Description | Default |
|---|---|---|
| `SOURCE_FOLDER` | Folder containing the `.mp4` files to process | `.` |
| `OUTPUT_FOLDER` | Folder where cleaned videos are saved | `clean` |
| `THREADS` | Maximum number of FFmpeg threads/cores to use | `2` |
| `AUDIO_KBPS` | Audio bitrate in kbps | `96` |
| `TARGET_RATIO` | The target output size (percentage) | `0.70` (70%) |

### Examples

Process the current folder and save cleaned files to `./clean`:

```bash
./clean_up_video.sh
```

Process `/path/to/videos` and save the results in `/path/to/output`:

```bash
./clean_up_video.sh /path/to/videos /path/to/output
```

Process `./videos`, save output to `./output`, and use 1 thread:

```bash
./clean_up_video.sh . clean 2 96 1
```

Compress to approximately 50% of the original size.
Change "0.70" in the TARGET_RATIO variable below to "0.50".
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

This project is licensed under the [Public Domain](https://github.com/gubi/VideoCleaner/blob/master/LICENSE)
