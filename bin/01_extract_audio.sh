#!/bin/bash
# 
# Skript zur Audioextraktion aus allen Videodateien im gemappten Verzeichnis.
# Wird im FFmpeg Docker Container ausgeführt.
#
# Annahme: Das Verzeichnis /host_video ist gemountet und enthält die Videos.
# Annahme: Das Verzeichnis /host_audio ist gemountet und enthält die extrahierten Audios.

VIDEO_DIR="/host_video"
EXTRACTED_AUDIO_DIR="/host_extracted_audio"

echo "Starte Batch-Extraktion aus: $VIDEO_DIR"

# Sucht nach allen .mp4-Dateien im VIDEO_DIR
# Die Bash-Wildcard-Expansion funktioniert zuverlässig im Linux-Container.
# Wir setzen die Option 'nullglob', damit die Schleife nicht einmal mit "*.mp4" läuft, wenn keine Dateien gefunden werden.
shopt -s nullglob

# **WICHTIG:** Sicherstellen, dass die Dateinamen Leerzeichen enthalten können.
shopt -s nocaseglob
for VIDEO_PATH in "$VIDEO_DIR"/*.mp4 "$VIDEO_DIR"/*.mov; do
    echo "++++ $VIDEO_PATH"
    # Prüfen, ob eine Datei gefunden wurde (wird durch 'nullglob' sicherer)
    if [ -f "$VIDEO_PATH" ]; then
        
        # 1. Dateinamen extrahieren
        BASENAME=$(basename "$VIDEO_PATH")
        FILENAME_NO_EXT="${BASENAME%.*}"
        
        OUTPUT_PATH="$EXTRACTED_AUDIO_DIR/$FILENAME_NO_EXT.wav"

        echo "--------------------------------------------------------"
        echo ">> Bearbeite Video: $BASENAME"
        echo "   Speichere unter: $OUTPUT_PATH"
        
        # 2. FFmpeg Befehl ausführen
        ffmpeg -i "$VIDEO_PATH" \
               -vn \
               -acodec pcm_s16le \
               -ar 44100 \
               -ac 1 \
               "$OUTPUT_PATH"

        EXIT_CODE=$?

        if [ $EXIT_CODE -eq 0 ]; then
            echo "<< Extraktion erfolgreich."
        else
            echo "<< FEHLER bei der Extraktion (FFmpeg Exit Code $EXIT_CODE)."
        fi
    fi
done

echo "--------------------------------------------------------"
echo "--- Batch-Verarbeitung abgeschlossen. ---"

exit 0