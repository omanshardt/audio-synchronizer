#!/bin/bash
#
# Wrapper script to run the Python audio sync script.
# Executed inside the Docker container.

EXTRACTED_DIR="/host_extracted_audio"
AUDIO_DIR="/host_audio"
SYNCED_DIR="/host_synced_audio"
SCRIPT_PATH="/host_bin/audio_sync.py"

echo "Starting Audio Correlation..."
echo "Extracted Dir: $EXTRACTED_DIR"
echo "Audio Dir:     $AUDIO_DIR"
echo "Synced Dir:    $SYNCED_DIR"

python3 "$SCRIPT_PATH" "$EXTRACTED_DIR" "$AUDIO_DIR" "$SYNCED_DIR"

if [ $? -eq 0 ]; then
    echo "Audio Correlation completed successfully."
else
    echo "Audio Correlation failed."
    exit 1
fi
