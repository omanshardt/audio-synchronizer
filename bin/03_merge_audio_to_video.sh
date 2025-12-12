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

for VIDEO_PATH in "$VIDEO_DIR"/*.mp4 "$VIDEO_DIR"/*.mov; do
    if [ -f "$VIDEO_PATH" ]; then
        BASENAME=$(basename "$VIDEO_PATH")
        FILENAME_NO_EXT="${BASENAME%.*}"
        
        # Suche nach passender Audio-Datei (wir nehmen an .wav, aber prüfen flexibel)
        AUDIO_PATH="$SYNCED_DIR/$FILENAME_NO_EXT.wav"
        
        if [ ! -f "$AUDIO_PATH" ]; then
            echo ">> Kein passendes Audio gefunden für: $BASENAME (Erwarte $FILENAME_NO_EXT.wav)"
            continue
        fi
        
        if [ "$MODE" == "replace" ]; then
            OUTPUT_PATH="$OUTPUT_DIR/${FILENAME_NO_EXT}-r.${BASENAME##*.}"
        else
            OUTPUT_PATH="$OUTPUT_DIR/${FILENAME_NO_EXT}-a.${BASENAME##*.}"
        fi
        
        echo "--------------------------------------------------------"
        echo ">> Bearbeite: $BASENAME"
        echo "   Audio: $AUDIO_PATH"
        echo "   Output: $OUTPUT_PATH"
        
        # Bitrate des Original-Audios ermitteln
        ORIG_BITRATE=$(ffprobe -v error -select_streams a:0 -show_entries stream=bit_rate -of default=noprint_wrappers=1:nokey=1 "$VIDEO_PATH")
        
        # Fallback, falls Bitrate nicht ermittelt werden kann (z.B. bei manchen Containern oder Codecs)
        if [ -z "$ORIG_BITRATE" ] || [ "$ORIG_BITRATE" == "N/A" ]; then
            echo "   WARNUNG: Konnte Bitrate nicht ermitteln. Nutze Standard 256k."
            ORIG_BITRATE="256k"
        fi
        
        echo "   Original Bitrate: $ORIG_BITRATE"

        if [ "$MODE" == "replace" ]; then
            # Ersetze Audio: Video von Input 0, Audio von Input 1
            ffmpeg -y -i "$VIDEO_PATH" -i "$AUDIO_PATH" \
                -map 0:v -map 1:a \
                -c:v copy -c:a aac -b:a "$ORIG_BITRATE" \
                "$OUTPUT_PATH"
        else
            # Füge Audio hinzu: Video von 0, Audio von 0, Audio von 1
            # NEU: Neues Audio (Stream 1:a) als Track 1 (AAC, Bitrate angepasst)
            #      Original-Audio (Stream 0:a) als Track 2 (Copy)
            #      Setze Track 1 als DEFAULT und Track 2 als NICHT-DEFAULT
            ffmpeg -y -i "$VIDEO_PATH" -i "$AUDIO_PATH" \
                -map 0:v -map 1:a -map 0:a \
                -c:v copy -c:a:0 aac -b:a:0 "$ORIG_BITRATE" -c:a:1 copy \
                -disposition:a:0 default -disposition:a:1 0 \
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
