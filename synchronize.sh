#!/bin/bash

ADD_OPTION=$1


echo "START extracting audio from video files"
./01_process_videos.sh
echo "START correlating extracted audio with audio recordings."
./02_correlate_audio.sh
echo "START adding audio from audio recording to video files"
if [ "$ADD_OPTION" = "--add" ]; then
      ./03_process_merge.sh --add
else
      ./03_process_merge.sh
fi

echo "DONE, ENJOY"