#!/bin/bash

BASE_PATH=$1
echo $BASE_PATH

ln -s "$BASE_PATH/00 Footages/Audio" Audio
ln -s "$BASE_PATH/00 Footages/Video" Video
ln -s "$BASE_PATH/00 Footages/Processing/ExtractedAudio" ExtractedAudio
ln -s "$BASE_PATH/00 Footages/Processing/Output" Output
ln -s "$BASE_PATH/00 Footages/Processing/SyncedAudio" SyncedAudio
