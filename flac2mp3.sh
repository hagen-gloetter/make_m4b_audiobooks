#!/bin/bash

#! /bin/bash

# written by hagen glötter in 2025
# contact hagen@gloetter.de

find . -name "*.flac" -exec ffmpeg -i {} -ab 160k -map_metadata 0 -id3v2_version 3 {}.mp3 \;

# Überprüfe, ob ffmpeg installiert ist
if ! command -v ffmpeg &> /dev/null; then
    echo "Fehler: ffmpeg ist nicht installiert. Bitte installiere es mit:"
    echo "sudo apt install ffmpeg"
    exit 1
fi

# Konvertiere alle FLAC-Dateien im aktuellen Verzeichnis
for flac_file in *.flac; do
    if [ -f "$flac_file" ]; then  # Überprüfe, ob die Datei existiert (falls *.flac keine Treffer liefert)
        mp3_file="${flac_file%.flac}.mp3"
        echo "Konvertiere: $flac_file → $mp3_file"
        
        # FFmpeg-Befehl mit korrekter Behandlung von Leerzeichen und Metadaten
        ffmpeg -i "$flac_file" -b:a 196k -acodec libmp3lame -map_metadata 0 "$mp3_file" -v quiet -stats
        
        if [ $? -eq 0 ]; then
            echo "✔ Erfolgreich: $mp3_file"
        else
            echo "❌ Fehler bei der Konvertierung von $flac_file"
        fi
    fi
done

echo "Fertig! Alle FLAC-Dateien wurden konvertiert."