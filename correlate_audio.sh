#!/bin/bash
#
# Host script to run the audio correlation process.

IMAGE_NAME="sync-audio-python"
BIN_DIR_HOST="$(pwd)/bin"
EXTRACTED_DIR_HOST="$(pwd)/ExtractedAudio"
AUDIO_DIR_HOST="$(pwd)/Audio"
SYNCED_DIR_HOST="$(pwd)/SyncedAudio"

# Ensure directories exist
mkdir -p "$EXTRACTED_DIR_HOST" "$AUDIO_DIR_HOST" "$SYNCED_DIR_HOST"

echo "--- 1. Building Audio Sync Docker Image ---"
docker build --platform linux/amd64 -t "$IMAGE_NAME" -f Dockerfile.audio_sync .

if [ $? -ne 0 ]; then
    echo "Error building Docker image."
    exit 1
fi

echo "--- 2. Running Audio Correlation ---"
docker run --rm \
    --platform linux/amd64 \
    -v "$EXTRACTED_DIR_HOST":/host_extracted_audio:ro \
    -v "$AUDIO_DIR_HOST":/host_audio:ro \
    -v "$SYNCED_DIR_HOST":/host_synced_audio:rw \
    -v "$BIN_DIR_HOST":/host_bin:ro \
    "$IMAGE_NAME" \
    /bin/bash /host_bin/02_correlate_audio.sh

if [ $? -eq 0 ]; then
    echo "--- Correlation Process Finished Successfully ---"
else
    echo "--- Correlation Process Failed ---"
fi
