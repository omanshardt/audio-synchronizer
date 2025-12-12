#!/bin/bash

echo "START extracting audio from video files"
./01_process_videos.sh
echo "START correlating extracted audio with audio recordings."
./02_correlate_audio.sh
echo "START adding audio from audio recording to video files"
./03_process_merge.sh

echo "DONE, ENJOY"