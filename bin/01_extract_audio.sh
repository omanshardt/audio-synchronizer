#!/bin/bash
# 
# Skript zur Audioextraktion aus einer Videodatei
# Wird im FFmpeg Docker Container ausgeführt.
#
# Usage: ./01_extract_audio.sh /path/to/Video.mp4 /path/to/Output_Audio.wav

VIDEO_PATH="$1"
OUTPUT_PATH="$2"

if [ -z "$VIDEO_PATH" ] || [ -z "$OUTPUT_PATH" ]; then
    echo "Fehler: Beide Pfade (Video-Input und Audio-Output) müssen angegeben werden."
    exit 1
fi

echo "Starte Extraktion von: $VIDEO_PATH"
echo "Speichere unter: $OUTPUT_PATH"

# FFmpeg Befehl:
# -i: Input-Datei
# -vn: Deaktiviere Video-Recording
# -acodec pcm_s16le: Verwende unkomprimiertes, lineares PCM Audio (am besten für Synchronisation)
# -ar 44100: Setze die Sample Rate auf 44.1 kHz
# -ac 1: Wandle in Mono um (optional, aber vereinfacht die spätere Korrelation)
ffmpeg -i "$VIDEO_PATH" \
       -vn \
       -acodec pcm_s16le \
       -ar 44100 \
       -ac 1 \
       "$OUTPUT_PATH"

EXIT_CODE=$?

if [ $EXIT_CODE -eq 0 ]; then
    echo "Extraktion erfolgreich."
else
    echo "Fehler bei der Extraktion (FFmpeg Exit Code $EXIT_CODE)."
fi

exit $EXIT_CODE