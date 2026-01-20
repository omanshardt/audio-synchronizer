#!/bin/bash
# 
# Haupt-Steuerungsskript auf dem Host (Apple M1)
# Startet den FFmpeg-Container einmalig für den gesamten Batch-Job.

# --- KONFIGURATION ---
FFMPEG_IMAGE_NAME="sync-ffmpeg"
BIN_DIR_HOST="$(pwd)/bin"
OUTPUT_DIR_HOST="$(pwd)/Output"
EXTRACTED_AUDIO_DIR_HOST="$(pwd)/ExtractedAudio"
# --- ENDE KONFIGURATION ---

# Ensure directories exist
mkdir -p "$OUTPUT_DIR_HOST" "$EXTRACTED_AUDIO_DIR_HOST"

# 1. Image bauen (einmalig) - Muss immer noch zuerst ausgeführt werden
echo "--- 1. FFmpeg Docker Image bauen ---"
# Wir verwenden das korrigierte jrottenberg/ffmpeg-Image
docker build -t "$FFMPEG_IMAGE_NAME" -f Dockerfile.ffmpeg .

if [ $? -ne 0 ]; then
    echo "Fehler beim Bauen des Docker-Images. Abbruch."
    exit 1
fi
echo "FFmpeg Image '$FFMPEG_IMAGE_NAME' gebaut."


# 2. Starte den Container einmalig für alle Extraktionen
echo "--- 2. Starte Videoschnitt im Container ---"

# Definiere den Pfad zum Skript im Container
CONTAINER_SCRIPT_PATH="/host_bin/00_cut_video.sh"

docker run --rm \
    -v "$OUTPUT_DIR_HOST":/host_output:rw \
    -v "$EXTRACTED_AUDIO_DIR_HOST":/host_extracted_audio:rw \
    -v "$BIN_DIR_HOST":/host_bin:ro \
    -v "$(pwd)/video_cuts.json":/host_config/video_cuts.json:ro \
    --entrypoint /bin/bash \
    "$FFMPEG_IMAGE_NAME" \
    "$CONTAINER_SCRIPT_PATH"
    # WICHTIG: /bin/bash davor, um sicherzustellen, dass das Skript mit der korrekten Shell im Container ausgeführt wird

if [ $? -eq 0 ]; then
    echo "--- Batch-Verarbeitung erfolgreich abgeschlossen. ---"
else
    echo "--- FEHLER: Batch-Verarbeitung im Container fehlgeschlagen. ---"
fi