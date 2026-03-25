#! /bin/bash
# hg_make-m4b-Audiobook_working_v3.sh
# Script to convert a directory of MP3 files to a single M4B audiobook file.
# !! Requires ffmpeg to be installed.
# Author:
# hagen@gloetter.de
# Date:
# 2021-09-26
# Version:
# 3.0
# License:
# Public Domain
# Description:
# This script takes a directory containing MP3 files and combines them into a single M4B audiobook file.
# The script extracts metadata from the first MP3 file and applies it to the M4B file.
# The resulting M4B file is saved in a subdirectory named "m4b" within the input directory.
# The script requires ffmpeg to be installed.
# The script takes one argument: the path to the directory containing the MP3 files.
# The script creates temporary files during the conversion process, which are cleaned up at the end.
# The script outputs the path to the resulting M4B file.
# The script is intended for personal use and may require modification for other use cases.
# Dependencies:
# - ffmpeg
# Usage: 
# c:\work\make_m4b_audiobooks\hg_make-m4b-Audiobook_working.sh c:\work\make_m4b_audiobooks\Buchtitel


# Überprüfen, ob ein Startpfad angegeben wurde
if [ -z "$1" ]; then
    echo "Fehler: Kein Startordner angegeben." >&2
    echo "Verwendung: $0 <start_verzeichnis>" >&2
    exit 1
fi

start_dir="$1"

# Überprüfen, ob das Verzeichnis existiert
if [ ! -d "$start_dir" ]; then
    echo "Fehler: Verzeichnis '$start_dir' existiert nicht." >&2
    exit 1
fi

# Basisnamen des Verzeichnisses extrahieren
dir_basename=$(basename "$start_dir")

# Temporäre Dateien erstellen
filenames_tmp=$(mktemp)
output_tmp=$(mktemp --suffix=.mp3)
output_m4a=$(mktemp --suffix=.m4a)
output_m4b="m4b/${dir_basename}.m4b"

# MP3-Dateien suchen und in die temporäre Liste schreiben
find "$start_dir" -type f -name "*.mp3" -printf "file '%p'\n" > "$filenames_tmp"

# Überprüfen, ob MP3-Dateien gefunden wurden
if [ ! -s "$filenames_tmp" ]; then
    echo "Fehler: Keine MP3-Dateien in '$start_dir' gefunden." >&2
    rm "$filenames_tmp"
    exit 1
fi

# Erste MP3-Datei für Metadaten ermitteln
first_mp3=$(head -n 1 "$filenames_tmp" | sed "s/file '\(.*\)'/\1/")

# Metadaten extrahieren
echo "Extrahiere Metadaten aus der ersten MP3-Datei..."
metadata=$(ffmpeg -i "$first_mp3" -f ffmetadata - 2>&1 | sed -n '/^ *\(title\|artist\|album\|date\|track\|genre\):/p')

# MP3s zusammenfügen
echo "Verarbeite MP3-Dateien..."
ffmpeg -f concat -safe 0 -i "$filenames_tmp" -c copy "$output_tmp" 2>/dev/null

# In M4A konvertieren und Metadaten hinzufügen
echo "Konvertiere zu M4B mit Metadaten..."
if [ -n "$metadata" ]; then
    echo "$metadata" | ffmpeg -i "$output_tmp" -i - -map_metadata 1 -c:a aac "$output_m4a" 2>/dev/null
else
    ffmpeg -i "$output_tmp" -c:a aac "$output_m4a" 2>/dev/null
fi

# M4B-Ordner erstellen und Datei umbenennen
mkdir -p m4b
mv "$output_m4a" "$output_m4b"

# Aufräumen
rm "$output_tmp" "$filenames_tmp"

echo "Konvertierung erfolgreich abgeschlossen. Ergebnis: $output_m4b"