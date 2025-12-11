#!/bin/bash
# 
# Haupt-Steuerungsskript auf dem Host (Apple M1)
# Startet den FFmpeg-Container temporär für jeden Extraktions-Job.
#
# Annahmen zur Verzeichnisstruktur (relative zum Skript-Pfad):
# - Video/      (Eingabevideos)
# - Audio/      (Ausgabe der extrahierten Audiospuren)
# - bin/        (Enthält 01_extract_audio.sh)

# --- KONFIGURATION ---
FFMPEG_IMAGE_NAME="sync-ffmpeg"
BIN_DIR_HOST="$(pwd)/bin"
VIDEO_DIR_HOST="$(pwd)/Video"
AUDIO_DIR_HOST="$(pwd)/Audio"
# --- ENDE KONFIGURATION ---

# 1. Image bauen (einmalig)
echo "--- 1. FFmpeg Docker Image bauen ---"
docker build -t "$FFMPEG_IMAGE_NAME" -f Dockerfile.ffmpeg .

if [ $? -ne 0 ]; then
    echo "Fehler beim Bauen des Docker-Images. Abbruch."
    exit 1
fi
echo "FFmpeg Image '$FFMPEG_IMAGE_NAME' gebaut."

# 2. Schleife über alle Videos
echo "--- 2. Starte Verarbeitung der Videos in $VIDEO_DIR_HOST ---"

for VIDEO_FILE in "$VIDEO_DIR_HOST"/*.mp4; do
    if [ -f "$VIDEO_FILE" ]; then
        # Dateiname ohne Pfad (z.B. MeinFilm.mp4)
        BASENAME=$(basename "$VIDEO_FILE")
        
        # Dateiname ohne Endung (z.B. MeinFilm)
        FILENAME_NO_EXT="${BASENAME%.*}"
        
        # Definierter Output-Pfad für die extrahierte WAV-Datei im Host-Audio-Verzeichnis
        OUTPUT_WAV_HOST="$AUDIO_DIR_HOST/$FILENAME_NO_EXT.wav"
        
        # --- Docker Volume Mappings definieren ---
        # Alle benötigten Host-Verzeichnisse werden in den Container gemappt.
        # Im Container werden sie unter /host_video, /host_audio und /host_bin erreichbar.
        
        # WICHTIG: Die Pfade im Container müssen hart kodiert werden, 
        # damit das Skript die Eingabe/Ausgabe findet.
        CONTAINER_VIDEO_PATH="/host_video/$BASENAME"
        CONTAINER_OUTPUT_PATH="/host_audio/$FILENAME_NO_EXT.wav"
        CONTAINER_SCRIPT_PATH="/host_bin/01_extract_audio.sh"
        
        echo ""
        echo ">> Bearbeite Video: $BASENAME"
        
        # 3. Temporären Container starten und Skript ausführen
        docker run --rm \
            --platform linux/amd64 \
            -v "$VIDEO_DIR_HOST":/host_video:ro \
            -v "$AUDIO_DIR_HOST":/host_audio:rw \
            -v "$BIN_DIR_HOST":/host_bin:ro \
            "$FFMPEG_IMAGE_NAME" \
            "$CONTAINER_SCRIPT_PATH" "$CONTAINER_VIDEO_PATH" "$CONTAINER_OUTPUT_PATH"
            
        if [ $? -eq 0 ]; then
            echo "<< Verarbeitung abgeschlossen für $BASENAME"
        else
            echo "<< FEHLER bei der Verarbeitung von $BASENAME. Siehe Logs."
        fi
    fi
done

echo "--- Alle Videos verarbeitet. ---"