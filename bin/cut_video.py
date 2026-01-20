#!/usr/bin/env python3
import json
import subprocess
import os
import sys

# Paths inside the container
VIDEO_DIR = "/host_output"
CONFIG_FILE = "/host_config/video_cuts.json"

def timecode_to_seconds(tc):
    """
    Parses "MM:SS:FF" or "HH:MM:SS:FF" (implied 25/30fps? No, user didn't specify FPS).
    Actually, to be precise with Frames (FF), we need the video Framerate.
    However, the user asked for simple logic.
    Let's assume standard SMPTE format. Without knowing the FPS, FF is ambiguous.
    
    Workaround: We will use ffprobe to get the FPS of the video file first.
    """
    parts = tc.split(':')
    if len(parts) == 3: # MM:SS:FF
        m, s, f = parts
        h = 0
    elif len(parts) == 4: # HH:MM:SS:FF
        h, m, s, f = parts
    else:
        raise ValueError(f"Invalid timecode format: {tc}. Expected MM:SS:FF or HH:MM:SS:FF")
    
    return int(h), int(m), int(s), int(f)

def get_fps(video_path):
    cmd = [
        "ffprobe", 
        "-v", "0", 
        "-of", "csv=p=0", 
        "-select_streams", "v:0", 
        "-show_entries", "stream=r_frame_rate", 
        video_path
    ]
    try:
        output = subprocess.check_output(cmd).decode("utf-8").strip()
        num, den = map(int, output.split('/'))
        return num / den
    except Exception as e:
        print(f"Error checking FPS for {video_path}: {e}")
        return 25.0 # Fallback

def parse_timecode(tc, fps):
    h, m, s, f = timecode_to_seconds(tc)
    total_seconds = (h * 3600) + (m * 60) + s + (f / fps)
    return total_seconds

def main():
    if not os.path.exists(CONFIG_FILE):
        print(f"Config file not found: {CONFIG_FILE}")
        sys.exit(1)

    with open(CONFIG_FILE, 'r') as f:
        try:
            data = json.load(f)
        except json.JSONDecodeError as e:
            print(f"Error parsing JSON: {e}")
            sys.exit(1)

    for item in data:
        original_name = item.get("origina_video_name")
        ranges = item.get("ranges", [])
        
        video_path = os.path.join(VIDEO_DIR, original_name)
        if not os.path.exists(video_path):
            print(f"Video not found: {video_path}")
            continue

        fps = get_fps(video_path)
        print(f"Processing {original_name} (FPS: {fps:.2f})")

        base_name, ext = os.path.splitext(original_name)
        # ext includes the dot, commonly .MP4 or .mov

        for i, rng in enumerate(ranges):
            start_tc = rng.get("from")
            end_tc = rng.get("to")
            
            if not start_tc:
                print(f"Skipping invalid range in {original_name}: missing 'from'")
                continue

            start_seconds = parse_timecode(start_tc, fps)
            
            # Using 1-based index for part number
            part_num = i + 1
            output_name = f"{base_name}_part_{part_num}{ext}"
            output_path = os.path.join(VIDEO_DIR, output_name)

            # Build FFmpeg command
            cmd = ["ffmpeg", "-y", "-ss", str(start_seconds)]
            
            # Handle optional end time
            if end_tc and end_tc != "-":
                end_seconds = parse_timecode(end_tc, fps)
                cmd.extend(["-to", str(end_seconds)])
            
            cmd.extend([
                "-i", video_path,
                "-c", "copy",
                "-map", "0",
                output_path
            ])
            
            range_str = f"{start_tc} -> {end_tc if end_tc else 'END'}"
            print(f"Cutting Part {part_num}: {range_str} ({output_name})")
            
            subprocess.run(cmd, check=False)
            
            # Preserve timestamps
            if os.path.exists(output_path):
                print(f"Preserving timestamp for {output_name}")
                subprocess.run(["touch", "-r", video_path, output_path], check=False)

if __name__ == "__main__":
    main()
