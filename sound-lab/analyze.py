# /// script
# requires-python = ">=3.11"
# dependencies = ["librosa", "matplotlib", "soundfile", "numpy"]
# ///
import json
from pathlib import Path

import librosa
import librosa.display
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np
import soundfile as sf

SRC = Path("/Users/saint/Dev/Annotate/sfx-candidates/02-flick-ink-tap.mp3")
LAB = Path("/Users/saint/Dev/Annotate/sound-lab")
ANA = LAB / "analysis"
SPL = LAB / "splits"

y, sr = librosa.load(SRC, sr=None, mono=True)
dur = len(y) / sr
t = np.arange(len(y)) / sr

hop = 256
n_fft = 2048

rms = librosa.feature.rms(y=y, frame_length=n_fft, hop_length=hop)[0]
times_rms = librosa.frames_to_time(np.arange(len(rms)), sr=sr, hop_length=hop)
cent = librosa.feature.spectral_centroid(y=y, sr=sr, n_fft=n_fft, hop_length=hop)[0]
rolloff = librosa.feature.spectral_rolloff(y=y, sr=sr, n_fft=n_fft, hop_length=hop, roll_percent=0.85)[0]
onset_env = librosa.onset.onset_strength(y=y, sr=sr, hop_length=hop)
times_on = librosa.frames_to_time(np.arange(len(onset_env)), sr=sr, hop_length=hop)
onsets = librosa.onset.onset_detect(onset_envelope=onset_env, sr=sr, hop_length=hop,
                                    backtrack=True, units="time")
onsets_raw = librosa.onset.onset_detect(onset_envelope=onset_env, sr=sr, hop_length=hop,
                                        backtrack=False, units="time")

peak_i = int(np.argmax(np.abs(y)))
peak_t = peak_i / sr
rms_peak_i = int(np.argmax(rms))
rms_peak_t = times_rms[rms_peak_i]

# attack: time from first sample exceeding 10% of peak to peak amplitude
thresh = 0.1 * np.max(np.abs(y))
first_i = int(np.argmax(np.abs(y) > thresh))
attack_ms = (peak_t - first_i / sr) * 1000

# decay tail: after global RMS peak, time until RMS falls below -40 dB rel peak
rms_db = librosa.amplitude_to_db(rms, ref=np.max(rms))
tail_idx = np.where(rms_db[rms_peak_i:] < -40)[0]
decay_end_t = times_rms[rms_peak_i + tail_idx[0]] if len(tail_idx) else dur
decay_ms = (decay_end_t - rms_peak_t) * 1000

# active region (above -50 dB)
active = np.where(rms_db > -50)[0]
active_start, active_end = times_rms[active[0]], times_rms[active[-1]]

# centroid trajectory over the active region only
mask = (times_rms >= active_start) & (times_rms <= active_end) & (rms_db > -45)
cent_active = cent[mask]
cent_times_active = times_rms[mask]
cent_min, cent_max = float(cent_active.min()), float(cent_active.max())
cent_start = float(cent_active[:5].mean())
cent_end = float(cent_active[-5:].mean())
cent_at_peak = float(cent[rms_peak_i])

# band energy split
S = np.abs(librosa.stft(y, n_fft=n_fft, hop_length=hop)) ** 2
freqs = librosa.fft_frequencies(sr=sr, n_fft=n_fft)
def band_energy(lo, hi):
    sel = (freqs >= lo) & (freqs < hi)
    return float(S[sel].sum())
total = float(S.sum())
bands = {
    "sub_0_200": band_energy(0, 200),
    "low_200_800": band_energy(200, 800),
    "mid_800_2500": band_energy(800, 2500),
    "presence_2500_6000": band_energy(2500, 6000),
    "treble_6000_12000": band_energy(6000, 12000),
    "air_12000_up": band_energy(12000, sr / 2),
}
band_pct = {k: round(100 * v / total, 1) for k, v in bands.items()}

# dominant frequency at RMS peak frame (the "tap")
tap_frame = S[:, rms_peak_i]
tap_dom_hz = float(freqs[int(np.argmax(tap_frame))])

metrics = {
    "sample_rate": sr,
    "duration_s": round(dur, 4),
    "peak_amp_time_s": round(peak_t, 4),
    "rms_peak_time_s": round(rms_peak_t, 4),
    "attack_ms_10pct_to_peak": round(attack_ms, 1),
    "decay_ms_peak_to_minus40dB": round(decay_ms, 1),
    "active_region_s": [round(active_start, 4), round(active_end, 4)],
    "onsets_backtracked_s": [round(x, 4) for x in onsets.tolist()],
    "onsets_raw_s": [round(x, 4) for x in onsets_raw.tolist()],
    "centroid_min_hz": round(cent_min, 1),
    "centroid_max_hz": round(cent_max, 1),
    "centroid_start_hz": round(cent_start, 1),
    "centroid_end_hz": round(cent_end, 1),
    "centroid_at_rms_peak_hz": round(cent_at_peak, 1),
    "tap_dominant_bin_hz": round(tap_dom_hz, 1),
    "band_energy_pct": band_pct,
}
(ANA / "metrics.json").write_text(json.dumps(metrics, indent=2))
print(json.dumps(metrics, indent=2))

# ---- plots ----
plt.rcParams.update({"figure.dpi": 130})

fig, ax = plt.subplots(figsize=(10, 3.2))
ax.plot(t, y, lw=0.4, color="#2b6cb0")
for o in onsets:
    ax.axvline(o, color="crimson", ls="--", lw=0.8)
ax.set(title="Waveform — 02-flick-ink-tap (onsets dashed)", xlabel="time (s)", ylabel="amplitude")
fig.tight_layout(); fig.savefig(ANA / "waveform.png"); plt.close(fig)

fig, ax = plt.subplots(figsize=(10, 4))
M = librosa.feature.melspectrogram(y=y, sr=sr, n_fft=n_fft, hop_length=hop, n_mels=128, fmax=sr / 2)
img = librosa.display.specshow(librosa.power_to_db(M, ref=np.max), sr=sr, hop_length=hop,
                               x_axis="time", y_axis="mel", fmax=sr / 2, ax=ax, cmap="magma")
fig.colorbar(img, ax=ax, format="%+2.0f dB")
ax.set(title="Mel spectrogram")
fig.tight_layout(); fig.savefig(ANA / "mel_spectrogram.png"); plt.close(fig)

fig, ax = plt.subplots(figsize=(10, 3.2))
ax.plot(times_rms, cent, color="#6b46c1", lw=1.2, label="spectral centroid")
ax.plot(times_rms, rolloff, color="#38a169", lw=0.9, alpha=0.7, label="85% rolloff")
ax.axvline(rms_peak_t, color="crimson", ls="--", lw=0.8, label="RMS peak (tap)")
ax.set(title="Spectral centroid over time (the swoop trajectory)", xlabel="time (s)", ylabel="Hz")
ax.legend(fontsize=8)
fig.tight_layout(); fig.savefig(ANA / "spectral_centroid.png"); plt.close(fig)

fig, ax = plt.subplots(figsize=(10, 3.2))
ax.plot(times_rms, rms, color="#dd6b20", lw=1.2)
ax.axvline(rms_peak_t, color="crimson", ls="--", lw=0.8)
ax.set(title="RMS envelope", xlabel="time (s)", ylabel="RMS")
fig.tight_layout(); fig.savefig(ANA / "rms_envelope.png"); plt.close(fig)

fig, ax = plt.subplots(figsize=(10, 3.2))
ax.plot(times_on, onset_env, color="#2c7a7b", lw=1.2)
for o in onsets_raw:
    ax.axvline(o, color="crimson", ls="--", lw=0.8)
ax.set(title="Onset strength (detected onsets dashed)", xlabel="time (s)", ylabel="strength")
fig.tight_layout(); fig.savefig(ANA / "onset_strength.png"); plt.close(fig)

# ---- splits ----
# segment boundaries from backtracked onsets within the active region
bounds = [active_start] + [o for o in onsets if active_start < o < active_end] + [decay_end_t, active_end]
bounds = sorted(set(round(b, 4) for b in bounds))
segs = []
for a, b in zip(bounds, bounds[1:]):
    if b - a > 0.02:
        segs.append((a, b))

names = []
for i, (a, b) in enumerate(segs):
    # name heuristically: segment containing rms peak = tap; before = swoop; after = tail
    if a <= rms_peak_t < b:
        name = f"seg{i+1}-tap"
    elif b <= rms_peak_t:
        name = f"seg{i+1}-swoop"
    else:
        name = f"seg{i+1}-tail"
    names.append((name, a, b))
    sf.write(SPL / f"{name}.wav", y[int(a * sr):int(b * sr)], sr)

print("segments:", names)

y_h, y_p = librosa.effects.hpss(y)
sf.write(SPL / "hpss-harmonic.wav", y_h, sr)
sf.write(SPL / "hpss-percussive.wav", y_p, sr)
sf.write(SPL / "full-mono.wav", y, sr)
print("done")
