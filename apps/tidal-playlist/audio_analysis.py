"""Local audio measurements using NumPy and FFmpeg; no streaming extraction."""
import hashlib
import math
from pathlib import Path
import shutil
import subprocess

NOTES = ['C', 'CSharp', 'D', 'Eb', 'E', 'F', 'FSharp', 'G', 'Ab', 'A', 'Bb', 'B']
MAJOR = [6.35, 2.23, 3.48, 2.33, 4.38, 4.09, 2.52, 5.19, 2.39, 3.66, 2.29, 2.88]
MINOR = [6.33, 2.68, 3.52, 5.38, 2.60, 3.53, 2.54, 4.75, 3.98, 2.69, 3.34, 3.17]


def measurements(samples, sr=22050):
    import numpy as np
    y = np.asarray(samples, dtype=float)
    if len(y) < sr * 5 or not np.isfinite(y).all():
        raise ValueError('Provide at least five seconds of finite audio.')
    y = y - np.mean(y)
    rms = float(np.sqrt(np.mean(y * y)))
    empty = {'bpm': None, 'key': None, 'scale': None, 'moods': [],
             'source': 'local_audio', 'seconds_analyzed': round(len(y) / sr, 2)}
    if rms < 1e-6:
        return {**empty, 'tempo_strength': 0.0, 'key_correlation': 0.0,
                'key_margin': 0.0, 'note': 'Audio is silent; no musical estimates.'}
    nfft, hop = 4096, 256
    frames = np.lib.stride_tricks.sliding_window_view(y, nfft)[::hop]
    frequencies = np.fft.rfftfreq(nfft, 1 / sr)
    window = np.hanning(nfft)
    energy_sum = np.zeros(len(frequencies))
    amplitude_sum = np.zeros(len(frequencies))
    flux_parts = []
    previous = None
    # Bounded FFT blocks avoid allocating a whole song's spectrogram.
    for offset in range(0, len(frames), 128):
        spectrum = np.abs(np.fft.rfft(frames[offset:offset + 128] * window, axis=1))
        energy_sum += (spectrum ** 2).sum(axis=0)
        amplitude_sum += spectrum.sum(axis=0)
        log_spectrum = np.log1p(spectrum)
        joined = np.vstack([previous, log_spectrum]) if previous is not None else log_spectrum
        flux_parts.append(np.maximum(np.diff(joined, axis=0), 0).mean(axis=1))
        previous = log_spectrum[-1:]
    # Positive spectral changes emphasize attacks, independently of absolute gain.
    flux = np.concatenate(flux_parts)
    onset_prominence = float(np.percentile(flux, 95) / max(float(np.mean(flux)), 1e-12))
    flux -= np.mean(flux)
    size = 1 << (2 * len(flux) - 1).bit_length()
    corr = np.fft.irfft(np.abs(np.fft.rfft(flux, n=size)) ** 2, n=size)[:len(flux)]
    corr /= np.maximum(np.arange(len(flux), 0, -1), 1)
    lag_min = max(1, round(60 * sr / (hop * 200)))
    lag_max = min(len(corr) - 1, round(60 * sr / (hop * 50)))
    bpm = None
    strength = 0.0
    if lag_max > lag_min and corr[0] > 1e-12 and onset_prominence >= 2.5:
        lag = lag_min + int(np.argmax(corr[lag_min:lag_max + 1]))
        strength = float(np.clip(corr[lag] / corr[0], 0, 1))
        if strength >= .08:
            bpm = round(60 * sr / (hop * lag), 1)
    # Aggregate spectral energy into pitch classes; correlate against major/minor
    # Krumhansl-Kessler profiles. Percussion and ambiguous harmony reduce confidence.
    mask = (frequencies >= 55) & (frequencies <= 5000)
    pitch_classes = np.rint(69 + 12 * np.log2(frequencies[mask] / 440)).astype(int) % 12
    energy = energy_sum[mask] / len(frames)
    chroma = np.bincount(pitch_classes, weights=energy, minlength=12)
    scored = []
    for scale, profile in [('MAJOR', MAJOR), ('MINOR', MINOR)]:
        for tonic in range(12):
            score = float(np.corrcoef(chroma, np.roll(profile, tonic))[0, 1]) if np.std(chroma) else 0.0
            scored.append((score, NOTES[tonic], scale))
    scored.sort(reverse=True)
    score, key, scale = scored[0]
    margin = score - scored[1][0]
    if score < .5 or margin < .03:
        key, scale = None, None
    centroid = float(np.sum(amplitude_sum * frequencies) / max(amplitude_sum.sum(), 1e-12))
    moods = []
    if centroid > 2500:
        moods.append('bright')
    elif centroid < 1200:
        moods.append('dark')
    if bpm is not None and bpm >= 115 and strength >= .15:
        moods.append('energetic')
    elif bpm is not None and bpm <= 95 and centroid < 2000:
        moods.append('calm')
    return {**empty, 'bpm': bpm, 'key': key, 'scale': scale, 'moods': moods,
            'tempo_strength': round(strength, 3), 'key_correlation': round(score, 3),
            'onset_prominence': round(onset_prominence, 3),
            'key_margin': round(margin, 3), 'spectral_centroid_hz': round(centroid),
            'note': 'Estimated tempo/key; half/double tempo is possible. Mood labels describe tempo/brightness heuristics, not emotions.'}


def analyze_file(filename, seconds=120):
    try:
        import numpy as np
    except ImportError:
        raise ValueError('Local analysis needs NumPy; install the optional requirements-audio.txt dependencies.') from None
    if not shutil.which('ffmpeg'):
        raise ValueError('Local analysis needs ffmpeg on PATH.')
    path = Path(filename).expanduser().resolve(strict=True)
    if not path.is_file():
        raise ValueError('Audio input must be a local file.')
    if not math.isfinite(seconds) or not 5 <= seconds <= 300:
        raise ValueError('Analyze between 5 and 300 seconds.')
    # file,pipe limits demuxers from following network references in local inputs.
    try:
        process = subprocess.run(['ffmpeg', '-nostdin', '-v', 'error', '-protocol_whitelist', 'file,pipe',
                                  '-i', str(path), '-t', str(seconds), '-vn', '-ac', '1', '-ar', '22050',
                                  '-f', 'f32le', 'pipe:1'], capture_output=True, timeout=120)
    except subprocess.TimeoutExpired:
        raise ValueError('FFmpeg decode exceeded the 120-second time limit.') from None
    if process.returncode:
        raise ValueError('FFmpeg could not decode this local audio file.')
    result = measurements(np.frombuffer(process.stdout, dtype='<f4'))
    result['audio_segment_sha256'] = hashlib.sha256(process.stdout).hexdigest()
    return result
