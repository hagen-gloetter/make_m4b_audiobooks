
## CHANGELOG.md

```md
# Changelog

Alle nennenswerten Änderungen an diesem Projekt werden in dieser Datei dokumentiert.

Das Format orientiert sich an **Keep a Changelog** und kann bei Bedarf mit Semantic Versioning kombiniert werden [web:17][web:19].

## [Unreleased]

### Added
- Platzhalter für kommende Änderungen.

## [1.0.0] - 2026-03-25

### Added
- Erstveröffentlichung des Python-Skripts `create_m4b_audiobook.py`.
- Einlesen aller MP3-Dateien aus einem angegebenen Eingabeordner.
- Alphabetische Sortierung der Quelldateien nach Dateinamen.
- Kapitelerzeugung pro MP3-Datei.
- Kapitelname aus ID3-Titel oder alternativ aus dem Dateinamen.
- AAC-LC-Konvertierung über FFmpeg.
- Automatische Auswahl von `libfdk_aac`, falls verfügbar, sonst nativer `aac`-Encoder.
- Dynamische Bitratenwahl zwischen `192k` und `128k`.
- Erzwingen von Stereo-Ausgabe.
- Übernahme globaler Metadaten aus ID3-Tags der ersten Quelldatei.
- Übernahme eines vorhandenen Cover-Bilds.
- Zusammenführen aller temporären AAC-Dateien zu einem `.m4b`.
- Ausgabe nach `/music_out/audiobooks/<Titel>.m4b`.
- Automatisches Überschreiben bereits vorhandener Zieldateien.
- Lesbare Log-Ausgabe auf `stdout`.
- Prüfung externer Abhängigkeiten (`ffmpeg`, `ffprobe`).
- Fehlerbehandlung für fehlende Dateien, fehlende Tools und Konvertierungsfehler.

### Notes
- Originale MP3-Dateien bleiben unverändert.
- Das Tool ist auf iPhone-kompatible M4B-Ausgabe ausgelegt.
