#!/usr/bin/env python3
"""
create_m4b_audiobook.py
Konvertiert MP3-Dateien in ein M4B-Hörbuch mit Kapitelmarken.

Verwendung:
  python3 create_m4b_audiobook.py --input /music_in
  python3 create_m4b_audiobook.py --input /music_in --output-title "Mein Hörbuch"

Installation der Abhängigkeiten (Ubuntu 22.04):
  sudo apt update && sudo apt install -y ffmpeg atomicparsley python3-pip
  pip install mutagen
"""
#!/usr/bin/env python3
"""
create_m4b_audiobook.py
Konvertiert MP3-Dateien in ein M4B-Hörbuch mit Kapitelmarken.

Installation:
  sudo apt update && sudo apt install -y ffmpeg atomicparsley python3-pip
  pip install mutagen

Verwendung:
  python3 create_m4b_audiobook.py --input /music_in
  python3 create_m4b_audiobook.py --input /music_in --output-title "Mein Hörbuch"

Cover-Bild:
  Lege einfach eine .jpg oder .jpeg Datei in den Eingabeordner.
  Bevorzugt werden cover.jpg und folder.jpg, sonst die erste gefundene .jpg.

Kapitel:
  Jede MP3-Datei bekommt ein Kapitel mit dem Namen Kapitel001, Kapitel002, ...
"""

import argparse
import json
import logging
import os
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

try:
    from mutagen.mp3 import MP3
    from mutagen.id3 import ID3, TIT2, TPE1, TALB, TDRC, TCON, APIC
    from mutagen.id3._util import ID3NoHeaderError
except ImportError:
    print("ERROR: 'mutagen' ist nicht installiert. Bitte mit 'pip install mutagen' nachinstallieren.")
    sys.exit(1)

# ─────────────────────────────────────────────
# Logging-Setup
# ─────────────────────────────────────────────
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s  %(levelname)-8s  %(message)s",
    datefmt="%H:%M:%S",
    handlers=[logging.StreamHandler(sys.stdout)],
)
log = logging.getLogger("m4b-creator")


# ─────────────────────────────────────────────
# Hilfsfunktionen
# ─────────────────────────────────────────────
def check_dependency(cmd: str) -> None:
    if not shutil.which(cmd):
        log.error(f"Abhängigkeit fehlt: '{cmd}' wurde nicht gefunden. Bitte installieren.")
        sys.exit(1)


def get_audio_info(filepath: str) -> dict:
    cmd = [
        "ffprobe", "-v", "quiet",
        "-print_format", "json",
        "-show_streams", "-show_format",
        filepath,
    ]
    result = subprocess.run(cmd, capture_output=True, text=True, check=True)
    data = json.loads(result.stdout)

    audio_stream = next(
        (s for s in data.get("streams", []) if s.get("codec_type") == "audio"), {}
    )
    duration = float(data.get("format", {}).get("duration", 0))
    channels = int(audio_stream.get("channels", 2))
    bit_rate = int(data.get("format", {}).get("bit_rate", 0)) // 1000

    return {"duration": duration, "channels": channels, "bit_rate": bit_rate}


def get_id3_tags(filepath: str) -> dict:
    tags = {
        "title": None,
        "artist": None,
        "album": None,
        "year": None,
        "genre": None,
        "cover": None,
    }
    try:
        audio = ID3(filepath)
        tags["title"]  = str(audio.get("TIT2", "")).strip() or None
        tags["artist"] = str(audio.get("TPE1", "")).strip() or None
        tags["album"]  = str(audio.get("TALB", "")).strip() or None
        tags["year"]   = str(audio.get("TDRC", "")).strip() or None
        tags["genre"]  = str(audio.get("TCON", "")).strip() or None
        for key in audio.keys():
            if key.startswith("APIC"):
                tags["cover"] = audio[key].data
                break
    except (ID3NoHeaderError, Exception) as e:
        log.warning(f"ID3-Tags konnten nicht gelesen werden ({Path(filepath).name}): {e}")
    return tags


def find_cover_image(input_dir: Path):
    """
    Sucht ein Cover-Bild direkt im Eingabeordner.
    Priorität: cover.jpg > folder.jpg > erste gefundene .jpg/.jpeg
    Gibt einen Path zurück oder None.
    """
    preferred = ["cover.jpg", "folder.jpg", "cover.jpeg", "folder.jpeg"]
    for name in preferred:
        candidate = input_dir / name
        if candidate.exists() and candidate.is_file():
            log.info(f"Cover-Bild gefunden (bevorzugt): {candidate.name}")
            return candidate

    images = sorted(
        [
            p for p in input_dir.iterdir()
            if p.is_file() and p.suffix.lower() in [".jpg", ".jpeg"]
        ],
        key=lambda p: p.name.lower(),
    )
    if images:
        log.info(f"Cover-Bild gefunden (erstes JPG im Ordner): {images[0].name}")
        return images[0]

    return None


def seconds_to_ffmpeg_ts(seconds: float) -> str:
    h = int(seconds // 3600)
    m = int((seconds % 3600) // 60)
    s = seconds % 60
    return f"{h:02d}:{m:02d}:{s:06.3f}"


def choose_bitrate(info: dict) -> str:
    if info["channels"] >= 2 and info["bit_rate"] >= 160:
        return "192k"
    return "128k"


# ─────────────────────────────────────────────
# Kernlogik
# ─────────────────────────────────────────────
def encode_mp3_to_m4a(mp3_path: str, m4a_path: str, bitrate: str, use_fdk: bool) -> None:
    encoder = "libfdk_aac" if use_fdk else "aac"
    cmd = [
        "ffmpeg", "-y",
        "-i", mp3_path,
        "-vn",
        "-c:a", encoder,
        "-b:a", bitrate,
        "-ac", "2",
        "-ar", "44100",
        m4a_path,
    ]
    subprocess.run(cmd, capture_output=True, check=True)


def build_ffmetadata(chapters: list, global_meta: dict) -> str:
    lines = [";FFMETADATA1"]
    if global_meta.get("title"):
        lines.append(f"title={global_meta['title']}")
    if global_meta.get("artist"):
        lines.append(f"artist={global_meta['artist']}")
    if global_meta.get("album"):
        lines.append(f"album={global_meta['album']}")
    if global_meta.get("year"):
        lines.append(f"date={global_meta['year']}")
    if global_meta.get("genre"):
        lines.append(f"genre={global_meta['genre']}")
    lines.append("")

    for chap in chapters:
        start_us = int(chap["start"] * 1_000_000)
        end_us   = int(chap["end"]   * 1_000_000)
        lines += [
            "[CHAPTER]",
            "TIMEBASE=1/1000000",
            f"START={start_us}",
            f"END={end_us}",
            f"title={chap['name']}",
            "",
        ]
    return "\n".join(lines)


def create_m4b(args) -> None:
    input_dir   = Path(args.input).resolve()
    output_base = Path("/music_out/audiobooks")

    # ── Abhängigkeiten prüfen ──────────────────
    for dep in ["ffmpeg", "ffprobe"]:
        check_dependency(dep)

    has_atomicparsley = bool(shutil.which("AtomicParsley"))
    if not has_atomicparsley:
        log.warning("AtomicParsley nicht gefunden – Cover wird direkt über ffmpeg eingebettet.")

    fdk_check = subprocess.run(["ffmpeg", "-encoders"], capture_output=True, text=True)
    use_fdk = "libfdk_aac" in fdk_check.stdout
    log.info(f"AAC-Encoder: {'libfdk_aac (FDK)' if use_fdk else 'aac (nativ)'}")

    # ── MP3-Dateien einlesen und sortieren ─────
    mp3_files = sorted(input_dir.glob("*.mp3"), key=lambda p: p.name)
    if not mp3_files:
        log.error(f"Keine MP3-Dateien in '{input_dir}' gefunden.")
        sys.exit(1)
    log.info(f"{len(mp3_files)} MP3-Datei(en) gefunden in: {input_dir}")

    # ── Cover-Bild aus Eingabeordner suchen ────
    cover_file = find_cover_image(input_dir)
    if not cover_file:
        log.warning("Kein JPG/JPEG im Eingabeordner gefunden – wird ohne Cover erstellt.")

    # ── Metadaten aus erster Datei / Argument ──
    first_tags = get_id3_tags(str(mp3_files[0]))

    if args.output_title:
        book_title = args.output_title
    elif first_tags.get("album"):
        book_title = first_tags["album"]
    elif first_tags.get("title"):
        book_title = first_tags["title"]
    else:
        book_title = input_dir.name

    log.info(f"Hörbuch-Titel: '{book_title}'")

    global_meta = {
        "title":  book_title,
        "artist": first_tags.get("artist"),
        "album":  book_title,
        "year":   first_tags.get("year"),
        "genre":  first_tags.get("genre"),
    }

    output_base.mkdir(parents=True, exist_ok=True)
    safe_title  = "".join(c for c in book_title if c not in r'\/:*?"<>|').strip()
    output_file = output_base / f"{safe_title}.m4b"
    log.info(f"Ausgabedatei: {output_file}")

    with tempfile.TemporaryDirectory(prefix="m4b_") as tmpdir:
        tmpdir    = Path(tmpdir)
        m4a_files = []
        chapters  = []
        cursor    = 0.0

        # ── Phase 1: MP3 → m4a konvertieren ───
        log.info("=" * 55)
        log.info("Phase 1: MP3-Dateien in AAC konvertieren")
        log.info("=" * 55)

        for idx, mp3 in enumerate(mp3_files, start=1):
            info    = get_audio_info(str(mp3))
            bitrate = choose_bitrate(info)

            # Kapitelnamen: immer KapitelNNN
            chapter_name = f"Kapitel{idx:03d}"

            m4a_out = tmpdir / f"{idx:04d}.m4a"

            log.info(
                f"[{idx:>3}/{len(mp3_files)}] {mp3.name} "
                f"| {info['channels']}ch | {info['bit_rate']} kbps src "
                f"→ Bitrate: {bitrate} | Kapitel: '{chapter_name}'"
            )

            try:
                encode_mp3_to_m4a(str(mp3), str(m4a_out), bitrate, use_fdk)
            except subprocess.CalledProcessError as e:
                log.error(f"Fehler beim Konvertieren von '{mp3.name}':\n{e.stderr.decode()}")
                sys.exit(1)

            actual_info = get_audio_info(str(m4a_out))
            duration    = actual_info["duration"]

            chapters.append({
                "name":  chapter_name,
                "start": cursor,
                "end":   cursor + duration,
            })
            cursor += duration
            m4a_files.append(m4a_out)

        # ── Phase 2: Concat-Liste schreiben ───
        log.info("=" * 55)
        log.info("Phase 2: Dateien zusammenführen und M4B erzeugen")
        log.info("=" * 55)

        concat_list = tmpdir / "concat.txt"
        with open(concat_list, "w") as f:
            for m4a in m4a_files:
                f.write(f"file '{m4a}'\n")

        # ── Phase 3: FFMETADATA schreiben ─────
        meta_file = tmpdir / "metadata.txt"
        meta_file.write_text(build_ffmetadata(chapters, global_meta), encoding="utf-8")

        # ── Phase 4: Finaler ffmpeg-Durchlauf ─
        tmp_m4b = tmpdir / "output.m4b"
        cmd = [
            "ffmpeg", "-y",
            "-f", "concat", "-safe", "0", "-i", str(concat_list),
            "-i", str(meta_file),
        ]

        map_args = ["-map", "0:a", "-map_metadata", "1", "-map_chapters", "1"]

        if cover_file:
            cmd += ["-i", str(cover_file)]
            map_args += ["-map", "2:v", "-disposition:v:0", "attached_pic"]
            log.info(f"Cover wird eingebettet: {cover_file.name}")

        cmd += map_args + [
            "-c:a", "copy",
            "-c:v", "copy",
            "-movflags", "+faststart",
            str(tmp_m4b),
        ]

        log.info("Führe finalen ffmpeg-Durchlauf aus …")
        try:
            subprocess.run(cmd, capture_output=True, check=True)
        except subprocess.CalledProcessError as e:
            log.error(f"ffmpeg-Fehler beim Zusammenführen:\n{e.stderr.decode()}")
            sys.exit(1)

        # ── Phase 5: Datei in Zielordner kopieren ─
        shutil.copy2(str(tmp_m4b), str(output_file))

    log.info("=" * 55)
    log.info("✓ Fertig! Hörbuch gespeichert unter:")
    log.info(f"  {output_file}")
    log.info(f"  Gesamtdauer : {seconds_to_ffmpeg_ts(cursor)}")
    log.info(f"  Kapitel     : {len(chapters)}")
    log.info("=" * 55)


# ─────────────────────────────────────────────
# Entry Point
# ─────────────────────────────────────────────
def main():
    parser = argparse.ArgumentParser(
        description="Konvertiert MP3-Dateien in ein M4B-Hörbuch mit Kapitelmarken."
    )
    parser.add_argument(
        "--input", "-i",
        required=True,
        help="Pfad zum Ordner mit den MP3-Eingabedateien (z. B. /music_in)",
    )
    parser.add_argument(
        "--output-title", "-t",
        default=None,
        help="Titel des Hörbuchs (überschreibt ID3-Tag). Wird auch als Dateiname verwendet.",
    )
    args = parser.parse_args()
    create_m4b(args)


if __name__ == "__main__":
    main()
    