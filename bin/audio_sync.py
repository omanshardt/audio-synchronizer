import os
import sys
import numpy as np
import librosa
import soundfile as sf
from scipy import signal
import subprocess

def find_offset(segment_path, master_path, sr=22050):
    """
    Finds the offset of segment within master using cross-correlation.
    Returns (offset_seconds, max_correlation).
    """
    try:
        # Load audio (downsample for speed, mono)
        y_segment, _ = librosa.load(segment_path, sr=sr, mono=True)
        y_master, _ = librosa.load(master_path, sr=sr, mono=True)
        
        # Normalize
        y_segment = (y_segment - np.mean(y_segment)) / (np.std(y_segment) + 1e-6)
        y_master = (y_master - np.mean(y_master)) / (np.std(y_master) + 1e-6)
        
        # Cross-correlation (FFT based is faster)
        correlation = signal.fftconvolve(y_master, y_segment[::-1], mode='valid')
        
        max_corr_idx = np.argmax(correlation)
        max_corr = correlation[max_corr_idx] / len(y_segment) # Normalize by length
        
        offset_seconds = max_corr_idx / sr
        
        return offset_seconds, max_corr
        
    except Exception as e:
        print(f"Error processing {segment_path} vs {master_path}: {e}")
        return None, 0

def extract_segment(master_path, output_path, start_time, duration):
    """
    Extracts a segment from master_path using ffmpeg.
    """
    cmd = [
        'ffmpeg', '-y',
        '-ss', str(start_time),
        '-t', str(duration),
        '-i', master_path,
        '-c', 'copy', # Try to copy first (fastest, no quality loss)
        output_path
    ]
    
    # If copy fails (e.g. different formats), re-encode to pcm_s16le wav
    # Actually, for precise cutting, re-encoding is often safer or using -c copy with -ss BEFORE -i
    # But -ss before -i with -c copy is not frame accurate.
    # For high quality sync, we should probably re-encode to wav or use the same codec.
    # Let's use pcm_s16le wav for the synced output as it's an intermediate format.
    
    cmd = [
        'ffmpeg', '-y',
        '-ss', str(start_time),
        '-t', str(duration),
        '-i', master_path,
        '-c:a', 'pcm_s16le',
        output_path
    ]
    
    subprocess.run(cmd, check=True, stderr=subprocess.DEVNULL)

def main():
    if len(sys.argv) < 4:
        print("Usage: python audio_sync.py <extracted_audio_dir> <master_audio_dir> <synced_audio_dir>")
        sys.exit(1)

    extracted_dir = sys.argv[1]
    master_dir = sys.argv[2]
    synced_dir = sys.argv[3]

    # Threshold for correlation match (experimental)
    CORR_THRESHOLD = 0.01

    extracted_files = [f for f in os.listdir(extracted_dir) if f.lower().endswith(('.aif', '.wav', '.mp3', '.aac', '.m4a'))]
    master_files = [f for f in os.listdir(master_dir) if f.lower().endswith(('.aif', '.wav', '.mp3', '.aac', '.m4a'))]

    if not extracted_files:
        print("No extracted audio files found.")
        return

    if not master_files:
        print("No master audio files found.")
        return

    for ext_file in extracted_files:
        ext_path = os.path.join(extracted_dir, ext_file)
        basename = os.path.splitext(ext_file)[0]
        output_path = os.path.join(synced_dir, f"{basename}.wav") # Always save as wav
        
        print(f"Processing: {ext_file}")
        
        # Get duration of the extracted clip (we need this for cutting)
        # Using librosa.get_duration with path argument for newer versions compatibility
        try:
            duration = librosa.get_duration(path=ext_path)
        except TypeError:
             # Fallback for older librosa versions
            duration = librosa.get_duration(filename=ext_path)
        
        best_match = None
        best_corr = -1
        best_offset = 0
        
        for mast_file in master_files:
            mast_path = os.path.join(master_dir, mast_file)
            
            # Optimization: Check if master is shorter than segment, skip if so
            # (omitted for simplicity, librosa handles it but returns low corr)
            
            offset, corr = find_offset(ext_path, mast_path)
            
            if corr > best_corr:
                best_corr = corr
                best_match = mast_path
                best_offset = offset
        
        print(f"  Best match: {os.path.basename(best_match) if best_match else 'None'} (Corr: {best_corr:.2f})")
        
        if best_match and best_corr > CORR_THRESHOLD:
            print(f"  Syncing... Offset: {best_offset:.2f}s, Duration: {duration:.2f}s")
            extract_segment(best_match, output_path, best_offset, duration)
            print(f"  Saved to: {output_path}")
        else:
            print("  No matching master file found (correlation too low).")

if __name__ == "__main__":
    main()
