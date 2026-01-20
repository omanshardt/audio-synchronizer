# Audio Synchronizer

This project is a collection of scripts and docker containers to synchronize audio from video files with external audio recordings.
It also provides a function to perform lossless cuts in a batch process. See section **Usage** for more information.

If you have a video file and an audio recording, you can use this project to synchronize the external recorded audio with the audio from the video file. This works with sample acuracy provided that

- both the internal audio recording of the camera and the external audio recording is of good quality.
- the external recorded audio covers the entire duration of the video file.

In this cases chances are very high that the audio is synchronized perfectly with the video file.

This task is performed in three steps:

1. Extract the audio from the video file using ffmpeg.
2. Synchronize the audio from the video files with the external audio recording via audio correlation using python and librosa and convertig and cutting the audio file via ffmpeg.
3. Add the audio to the video file either as a replacement for the original audio track or as an additional audio track using ffmpeg

## Docker

The docker containers are used to run the scripts in a containerized environment providing ffmpeg, python and librosa.

For now we have two containers:

- **Container 1** (Dockerfile.ffmpeg): This container is used to extract the audio from the video file and to add the final new audio file to the video file.
- **Container 2** (Dockerfile.audio_sync): This container is used to synchronize the audio of the video file with the external audio recording via audio correlation using python and librosa and convertig and cutting the audio file via ffmpeg.

As both containers use python and ffmpeg it would be possible to only have one container but during development it was not clear, that cutting the audio would be done using ffmpeg and not using python. So initially ffmpeg was not foreseen in the second container. This might be changed in a later version of this project.

## Dockerfile

- Dockerfile.ffmpeg
- Dockerfile.audio_sync

The docker containers are **not** persitant. They are started by the script and stopped after the task is finished.

## How to use

### Prerequisites

- Docker needs to be installed and running.
- The scripts in this project rely on the following directories to be present in the project:
  - Audio
    - This directory should contain the external audio recording(s) that should be synchronized with the video file. It is possible to have multiple audio files in this directory. The script matches all audio files with each video file. As long as one audio file covers the entire duration of a video file, the script will most likely be able to synchronize the audio with the video file.
  - Video
    - This directory should contain the video files that should be synchronized with the external audio recording(s). For now .mp4 video files are supported.
  - ExtractedAudio
    - This directory will contain the extracted audio from the video file.
  - SyncedAudio
    - This directory will contain the synchronized and cut audio file. These files were cut from the external audio recording(s) and should match the internal camera audio with sample acuracy. After the procesisng this folder should contain as many files as there are video files in the **Video** directory and extracted audio files in the **ExtractedAudio** directory. All audio files have the same name as the corresponding video file apart from the file extension.
- Output
    - This directory will contain the output video file with the synchronized audio.

### Usage

#### Synchronization

In the terminal navigate to the project's root directory and run the following command:

```bash
./synchronize.sh
```

This will replace the audio in the video file with the synchronized audio.

If you want to add the synchronized audio as an additional audio track to the video file run the following command: This is recommended and allows to easily compare the original audio and the synchronized external audio recording for example in Final Cut Pro and also to switch back to the original audio if synchronization has failed in some way. When adding the audio to the video file it isplaced as the first track and activated as default track. The original audio form teh video file is placed as the second track.

```bash
./snchronize.sh --add
```

After synchronization is done check the Output directory to ensure that the audio was synchronized correctly. If so you can delete the **ExtractedAudio** and **SyncedAudio** directories. You can also delete the original video files if you want to. The video in the new video files has **not** been re-compressed or re-encoded so the same quality as the original video file is preserved. 

You can execute the single steps individually by executing the following scripts independently.

- 01_process_videos.sh
- 02_correlate_audio.sh
- 03_process_merge.sh (with or without the --add flag)

It is recommended to symlink the **Audio** and **Video** directories to the project's root directory, so the files can stay in their original location. It's also possible to symlink **ExtractedAudio**, **SyncedAudio** and **Output** from corresponding directories in your original video project to the root directory.

The script **create_symlinks.sh** is included to demonstrate how I create my symlinks for the working directories. I just hand over the path to the video project's root directory to the script and it creates the symlinks accordingly.

```
./create_symlinks.sh /path/to/video/project
```

Your project structure might look different, so you can modify the script to create your symlinks accordingly. Make sure that you have the correct permissions to create symlinks in the project's root directory and that you properly target the sub-directories in your video project within the create_symlinks.sh script.

#### Cutting

The script **00_cut_video.sh** allows to cut video files in a lossless process. For now this process is intended to be executed after the synchronization process - video files are retrieved from the /Output directory which is the directory where the synchronized files are saved. The cuts are defined in the file **video_cuts.json** which is located in the project's root directory but should be stored with each video project and symlinked to the project's root just as the directories **Audio**, **ExtractedAudio**, **Output**, **SyncedAudio**, **Video**

