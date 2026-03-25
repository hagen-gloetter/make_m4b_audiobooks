# Prompt: M4B Audiobook Generator

Schreibe ein vollständiges, produktionsnahes Skript in **Python 3**, das aus mehreren MP3-Dateien in einem angegebenen Ordner ein einziges Hörbuch im **m4b**-Format erstellt.

## Aufgabe

Das Skript soll alle MP3-Dateien in einem Eingabeordner einlesen, alphabetisch nach Dateinamen sortieren, jede Datei in AAC-LC umwandeln, alle Dateien zu einem einzigen `.m4b` zusammenführen und für jede Eingabedatei ein eigenes Kapitel erzeugen.

Das Ergebnis muss auf einem **iPhone** abspielbar sein.

## Anforderungen

### Eingabe
- Das Skript muss einen Eingabeordner als Argument akzeptieren, zum Beispiel:
  - `/music_in`
- Optional soll ein expliziter Ausgabetitel per CLI-Parameter gesetzt werden können.

### Sortierung
- Verwende alle `.mp3`-Dateien im Eingabeordner.
- Sortiere sie alphabetisch nach Dateinamen.
- Die Dateinamen enthalten bereits die korrekte Reihenfolge.

### Kapitel
- Erzeuge für jede MP3-Datei genau ein Kapitel.
- Der Kapitelname soll bevorzugt aus dem ID3-Titel-Tag (`TIT2`) gelesen werden.
- Falls kein Titel-Tag vorhanden ist, verwende den Dateinamen ohne Erweiterung.
- Die Kapitelzeiten sollen anhand der kumulativen Laufzeit korrekt berechnet werden.

### Audio-Konvertierung
- Konvertiere jede MP3-Datei zunächst in eine temporäre AAC-Datei (`.m4a`).
- Erzwinge Stereo-Ausgabe (`-ac 2`).
- Verwende **AAC-LC**.
- Nutze nach Möglichkeit `libfdk_aac`; falls nicht verfügbar, automatisch den nativen FFmpeg-Encoder `aac`.
- Wähle die Zielbitrate pro Datei dynamisch:
  - `192k`, wenn die Quelle Stereo ist und ausreichend Bitrate bietet
  - sonst `128k`
- Ermittle Kanäle, Dauer und Quellbitrate mit `ffprobe`.

### Metadaten
- Lies Metadaten aus den ID3-Tags der MP3-Dateien.
- Übernimm alle sinnvoll verfügbaren globalen Metadaten aus der ersten Datei:
  - Titel
  - Künstler
  - Album
  - Jahr
  - Genre
- Übernimm ein vorhandenes Cover-Bild aus der ersten passenden Datei.
- Wenn kein Cover vorhanden ist, soll das Skript ohne Fehler fortfahren.

### Ausgabetitel
- Bestimme den Hörbuch-Titel in dieser Reihenfolge:
  1. CLI-Argument `--output-title`, falls gesetzt
  2. Album-Tag der ersten Datei
  3. Titel-Tag der ersten Datei
  4. Name des Eingabeordners

### Ausgabe
- Speichere die fertige Datei unter:
  - `/music_out/audiobooks/"Titel des Hörbuchs".m4b`
- Falls eine gleichnamige Datei bereits existiert, soll sie ohne Rückfrage überschrieben werden.

### Logging
- Gib während der Verarbeitung gut lesbare Logs auf `stdout` aus.
- Das Logging soll enthalten:
  - gefundene Eingabedateien
  - gewählten AAC-Encoder
  - verwendete Bitrate pro Datei
  - Kapitelnamen
  - Warnungen bei fehlenden Tags oder fehlendem Cover
  - Zielpfad
  - Gesamtdauer und Anzahl der Kapitel

### Originaldateien
- Die ursprünglichen MP3-Dateien dürfen **nicht** verändert, gelöscht, verschoben oder umbenannt werden.

## Technische Vorgaben

### Tools
Verwende:
- `ffmpeg`
- `ffprobe`
- Python-Bibliothek `mutagen` zum Lesen von ID3-Tags
- optional `AtomicParsley` für MP4/M4B-Metadaten oder als Fallback-Hinweis

### Verarbeitung
- Erzeuge temporäre `.m4a`-Dateien in einem temporären Arbeitsverzeichnis.
- Erzeuge eine `concat`-Dateiliste für FFmpeg.
- Erzeuge eine Kapitel-/Metadatendatei im Format `FFMETADATA1`.
- Füge die Dateien mit FFmpeg zusammen.
- Binde Kapitel und globale Metadaten ein.
- Bette, falls vorhanden, das Cover-Bild ein.
- Verwende `-movflags +faststart`, damit die Datei MP4-kompatibel und für Apple-Geräte geeignet bleibt.

### Robustheit
- Prüfe alle benötigten externen Tools vor dem Start.
- Gib klare Fehlermeldungen aus, wenn Abhängigkeiten fehlen.
- Brich sauber ab, wenn keine MP3-Dateien gefunden wurden.
- Verwende temporäre Dateien nur innerhalb eines Temp-Verzeichnisses.
- Räume temporäre Dateien am Ende automatisch auf.
- Bereinige ungültige Zeichen im Ausgabedateinamen.

## CLI

Das Skript soll so aufrufbar sein:

```bash
python3 create_m4b_audiobook.py --input /music_in --output-title "Mein Hörbuch"
