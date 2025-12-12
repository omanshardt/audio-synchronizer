#!/bin/bash
#
# Skript zum Zusammenführen von Audio und Video.
# Wird im FFmpeg Docker Container ausgeführt.
#
# Argumente:
#   --add: Fügt das Audio als zusätzlichen Track hinzu, anstatt es zu ersetzen.
#
# Annahmen:
#   /host_video: Enthält die Originalvideos.
#   /host_synced: Enthält die zu mergenden Audiodateien (gleicher Basename).
#   /host_output: Zielverzeichnis.

VIDEO_DIR="/host_video"
SYNCED_DIR="/host_synced_audio"
OUTPUT_DIR="/host_output"

MODE="replace"

# Argumente parsen
for arg in "$@"
do
    case $arg in
        --add|-a)
        MODE="add"
        shift
        ;;
    esac
done

echo "Starte Audio-Merge-Prozess..."
echo "Modus: $MODE"

shopt -s nullglob nocaseglob

for VIDEO_PATH in "$VIDEO_DIR"/*.mp4; do
    if [ -f "$VIDEO_PATH" ]; then
        BASENAME=$(basename "$VIDEO_PATH")
        FILENAME_NO_EXT="${BASENAME%.*}"
        
        # Suche nach passender Audio-Datei (wir nehmen an .wav, aber prüfen flexibel)
        AUDIO_PATH="$SYNCED_DIR/$FILENAME_NO_EXT.wav"
        
        if [ ! -f "$AUDIO_PATH" ]; then
            echo ">> Kein passendes Audio gefunden für: $BASENAME (Erwarte $FILENAME_NO_EXT.wav)"
            continue
        fi
        
        OUTPUT_PATH="$OUTPUT_DIR/$BASENAME"
        
        echo "--------------------------------------------------------"
        echo ">> Bearbeite: $BASENAME"
        echo "   Audio: $AUDIO_PATH"
        echo "   Output: $OUTPUT_PATH"
        
        if [ "$MODE" == "replace" ]; then
            # Ersetze Audio: Video von Input 0, Audio von Input 1
            ffmpeg -y -i "$VIDEO_PATH" -i "$AUDIO_PATH" \
                -map 0:v -map 1:a \
                -c:v copy -c:a aac \
                "$OUTPUT_PATH"
        else
            # Füge Audio hinzu: Video von 0, Audio von 0, Audio von 1
            # Original-Audio (Stream 0:a) wird kopiert (Qualitätserhalt), neues Audio (Stream 1:a) wird nach AAC konvertiert
            ffmpeg -y -i "$VIDEO_PATH" -i "$AUDIO_PATH" \
                -map 0:v -map 0:a -map 1:a \
                -c:v copy -c:a:0 copy -c:a:1 aac \
                "$OUTPUT_PATH"
        fi
        
        if [ $? -eq 0 ]; then
            echo "<< Merge erfolgreich."
            # Zeitstempel vom Originalvideo auf das neue Video übertragen
            touch -r "$VIDEO_PATH" "$OUTPUT_PATH"
            echo "   Zeitstempel übertragen."
        else
            echo "<< FEHLER beim Merge."
        fi
    fi
done

echo "--------------------------------------------------------"
echo "--- Merge-Vorgang abgeschlossen. ---"
exit 0
