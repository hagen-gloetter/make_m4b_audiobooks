# create-m4b-audiobook

A small Python CLI tool that takes all MP3 files from an input folder, sorts them alphabetically, converts them to AAC-LC, merges them into a single **.m4b** audiobook, and creates one chapter per file.

------

## Features

- Reads all `.mp3` files from a given input directory.
- Sorts files alphabetically by filename.
- Creates one chapter for each source file.
- Uses the chapter name from the ID3 title tag or, if unavailable, from the filename (without extension).
- Converts audio to AAC-LC, forces stereo output.
- Dynamically chooses the target bitrate:
  - `192k` if the source is stereo and has sufficient bitrate.
  - `128k` otherwise.
- Preserves available metadata from ID3 tags:
  - title
  - artist
  - album
  - year
  - genre
  - cover art (if present)
- Writes the final file to:
  - `/music_out/audiobooks/<Title>.m4b`
- Automatically overwrites existing output files with the same name.
- Leaves the original MP3 files untouched.

------

## Requirements

## System packages

- `ffmpeg`
- `ffprobe`
- `AtomicParsley` (optional but recommended)
- `python3`
- `python3-pip`

## Python package

- `mutagen`

------

## Installation

### System packages

#### Ubuntu/Debian (Linux)

```bash
sudo apt update && sudo apt install -y ffmpeg atomicparsley python3-full
```

#### macOS

```bash
brew install ffmpeg atomicparsley python3
```

#### Windows

Install FFmpeg and AtomicParsley:
- **FFmpeg**: Download from [ffmpeg.org](https://ffmpeg.org/download.html) or use a package manager like Chocolatey:
  ```powershell
  choco install ffmpeg atomicparsley
  ```
- **Python3**: Download from [python.org](https://www.python.org/downloads/) or use Chocolatey:
  ```powershell
  choco install python
  ```

### Python Virtual Environment Setup

To avoid the `externally-managed-environment` error, create and activate a Python virtual environment:

#### Linux / macOS

```bash
# Create virtual environment
python3 -m venv venv

# Activate virtual environment
source venv/bin/activate

# Install Python packages
pip install mutagen
```

#### Windows

```powershell
# Create virtual environment
python -m venv venv

# Activate virtual environment
venv\Scripts\activate

# Install Python packages
pip install mutagen
```

After activation, your shell prompt should show `(venv)` at the beginning.

**Note**: Each time you use the script, remember to activate the virtual environment first:
- **Linux/macOS**: `source venv/bin/activate`
- **Windows**: `venv\Scripts\activate`

To deactivate the virtual environment later, simply type:
```bash
deactivate
```

---

**Optional**: You can check whether `ffmpeg` was built with `libfdk_aac`. If not, the script automatically falls back to the native `aac` encoder.

------

## Project structure

```
text.
├── create_m4b_audiobook.py
├── README.md
├── CHANGELOG.md
├── requirements.txt
├── .gitignore
└── prompts
    └── codegen_prompt.md
```

------

## Usage

## Automatic title from tags or folder name

```bash
python3 create_m4b_audiobook.py --input /music_in
```

## Set a custom title explicitly

```bash
python3 create_m4b_audiobook.py --input /music_in --output-title "My Audiobook"
```

------

## Example

If the input folder contains these files:

```
text/music_in
├── 01 - Intro.mp3
├── 02 - Chapter One.mp3
├── 03 - Chapter Two.mp3
```

the script creates:

```
/music_out/audiobooks/My Audiobook.m4b
```

with three chapters:

- Intro
- Chapter One
- Chapter Two

------

## Bitrate logic

For each MP3 file, the script inspects the audio properties (channels, bitrate) and then decides:

- Stereo + sufficient source bitrate → `192k`
- Everything else → `128k`

This keeps the output consistent without creating unnecessarily large files.

------

## Metadata

The script copies global metadata from the first MP3 file:

- title
- artist
- album
- year
- genre

If cover art is available, it is embedded. If no cover art is found, processing continues without error.

## Output title priority

The audiobook title is determined in this order:

1. CLI argument `--output-title`, if provided
2. Album tag of the first file
3. Title tag of the first file
4. Input folder name

------

## Chapters

One chapter is created for each MP3 file.

The chapter name is determined as follows:

1. ID3 title tag (`TIT2`)
2. Filename without `.mp3`

Chapter timestamps are based on the actual duration of the generated AAC files to avoid timing drift during the final merge.

------

## Logging

During processing, the script writes readable status messages to `stdout`, for example:

- found input files
- selected AAC encoder
- bitrate used per file
- chapter names
- warnings for missing tags or cover art
- output path
- total duration and chapter count

------

## Existing output files

If a `.m4b` file with the same name already exists in `/music_out/audiobooks`, it is overwritten without prompting.

------

## Error handling

The script exits with a clear error message if:

- no MP3 files were found in the input directory
- `ffmpeg` or `ffprobe` are missing
- `mutagen` is not installed
- an audio conversion fails

`AtomicParsley` is optional; if it is missing, only a warning is shown.

------

## iPhone compatibility

The tool produces an `.m4b` audiobook in an MP4-based container with AAC-LC audio and chapters, which is well supported by Apple devices and iPhone audiobook players.

------

## License

License for this project:

```
MIT License
```

------

## Roadmap

- Recursive input directory processing

- Custom output directory support

- Additional cover lookup from `cover.jpg` or `folder.jpg`

- Optional logfile output

- Batch processing for multiple audiobooks

  


# create-m4b-audiobook

Ein kleines Python-CLI-Tool, das alle MP3-Dateien eines Eingabeordners alphabetisch sortiert, in AAC-LC umwandelt, zu einem einzigen **.m4b**-Hörbuch zusammenführt und für jede Datei ein eigenes Kapitel anlegt.

Das Ergebnis ist für iPhone und andere MP4/M4B-kompatible Player geeignet, weil das Skript AAC im MP4-basierten Container erzeugt und Kapitelmetadaten mitführt [web:21].

## Features

- Liest alle `.mp3`-Dateien aus einem angegebenen Eingabeordner.
- Sortiert Dateien alphabetisch nach Dateinamen.
- Erstellt pro Quelldatei ein Kapitel.
- Verwendet den Kapitelnamen aus dem ID3-Titel oder alternativ aus dem Dateinamen.
- Konvertiert Audio nach AAC-LC.
- Erzwingt Stereo-Ausgabe.
- Wählt die Zielbitrate dynamisch:
  - `192k`, wenn die Quelle Stereo ist und ausreichend Bitrate hat.
  - sonst `128k`.
- Übernimmt verfügbare Metadaten aus ID3-Tags:
  - Titel
  - Künstler
  - Album
  - Jahr
  - Genre
  - Cover-Bild
- Schreibt die fertige Datei nach:
  - `/music_out/audiobooks/<Titel>.m4b`
- Überschreibt vorhandene Ausgabedateien automatisch.
- Lässt Original-MP3-Dateien unverändert.

## Voraussetzungen

Benötigte Tools:

- `ffmpeg`
- `ffprobe` (normalerweise Teil von FFmpeg)
- `AtomicParsley` (optional bzw. empfohlen für MP4/M4B-Metadaten-Workflows)
- Python 3.10+
- Python-Paket `mutagen` zum Lesen von ID3-Tags [web:29]

## Installation unter Ubuntu 22.04

```bash
sudo apt update && sudo apt install -y ffmpeg atomicparsley python3-pip
pip install mutagen
