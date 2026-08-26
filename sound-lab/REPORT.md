# Sound Lab — Why `02-flick-ink-tap.mp3` Works

A decomposition of the winning Annotate toggle sound, the psychoacoustics behind it, and a recipe book for generating more sounds in its family.

Reference: `/Users/saint/Dev/Annotate/sfx-candidates/02-flick-ink-tap.mp3`
Saint's verdict: *"THE CLOSEST and best — it was quick, had a quick swoop, one noise, short."*

---

## 1. Measured anatomy of the file

All numbers from `analysis/metrics.json` (librosa, 44.1 kHz, hop 256). Plots in `analysis/`.

### The shape: one fusiform gesture

Despite the name "flick-ink-tap", the spectrogram and waveform show **one continuous spindle-shaped gesture**, not two discrete hits:

| Measurement | Value |
|---|---|
| Total duration | **1.000 s** (perceived sound ends far earlier) |
| Attack (10% of peak → peak amplitude) | **70.6 ms** |
| Amplitude peak | **0.098 s**; RMS peak at **0.122 s** |
| Decay (RMS peak → −40 dB) | **464 ms**, but the loud body is gone by **~0.25 s** |
| Active region | 0 – 0.93 s (last ~0.6 s is near-silent air) |
| Perceptually salient event | **~0 – 250 ms** — a quarter second |

So the *felt* sound is a **~250 ms swell-and-release**: a fast crescendo (the "swoop"), an instantaneous soft peak (the "tap"), and a rapid fall into a whisper-quiet air tail that gives it room to breathe. The 70 ms attack is the key fingerprint: it is *fast enough to feel instant* but *slow enough to feel swept* — a hard click would have a <10 ms attack. That in-between attack is what reads as a "flick" or brush gesture rather than a mechanical click.

### The color: it lives in the treble

Band energy distribution (share of total spectral energy):

| Band | Share |
|---|---|
| Sub (0–200 Hz) | 0.1% |
| Low (200–800 Hz) | 0.3% |
| Mid (800–2500 Hz) | 4.4% |
| Presence (2.5–6 kHz) | 21.8% |
| **Treble (6–12 kHz)** | **61.8%** |
| Air (12 kHz+) | 11.6% |

**95% of the energy sits above 2.5 kHz.** There is essentially no bass and no low-mid body. This is why the sound feels *light, papery, and physical* rather than synthetic or heavy — it is the spectrum of a fingertip brushing paper, not of a speaker thump. It also means it survives laptop/phone speakers perfectly, which roll off lows anyway (Toptal, below).

### The swoop: a falling brightness sweep

The spectral centroid (perceived brightness) over the active body:

- Starts at **~10,542 Hz** in the first frames
- Peaks at **10,826 Hz** during the rise
- Sits at **7,648 Hz** at the RMS peak (the tap moment)
- Settles to **~7,224 Hz** as the body decays (min 7,019 Hz)

So the "swoop" is a **downward brightness glide of roughly 3.5 kHz (≈10.5 kHz → 7.2 kHz) over ~200 ms**, riding on a rising loudness envelope. Bright-and-quiet → darker-and-loud → gone. The dominant spectral bin at the tap instant is **9,647 Hz** — the "ink tap" is a treble tick, not a thud.

### The tail: engineered silence

From 0.25 s to 0.93 s the file holds a faint air-noise bed (~−40 to −50 dB). This is deliberate negative space: the sound doesn't cut to digital zero, it *exhales*. It prevents the abrupt-truncation artifact that makes short SFX feel cheap.

### One-line formula

> **Broadband treble noise (6–12 kHz core), fusiform envelope: ~70 ms swept attack, peak at ~100 ms, dead by ~250 ms, with a falling ~10.5→7 kHz brightness glide and a whisper air tail. One gesture, zero bass.**

---

## 2. Why this works — the psychoacoustics

### Attack time is the emotion of a UI sound
The transient is where a listener decides what a sound *is* — perceptual attack time research shows onset character dominates identification of short sounds ([Collins, *Investigating computational models of perceptual attack time*](https://www.composerprogrammer.com/research/pat.pdf)). A <10 ms attack reads as *mechanical click*; a 50–100 ms swept attack reads as *gesture / motion / material*. This file's 70 ms attack is why it feels like a flick of a pen and not a keyboard key. Game-audio practice targets 100–300 ms total for microinteraction sounds for exactly this reason ([SFX Engine, *Best Practices for Game UI Sounds*](https://sfxengine.com/blog/best-practices-for-game-ui-sounds)).

### Short single gestures beat compound sounds
UX sound guidance is unanimous that interaction feedback must be one concise idea: "a transition or micro-interaction sound should never last more than 0.3 s longer than its associated animation… sounds should be concise in their intent, rather than excessive" ([Toptal, *A Quick Guide to Designing UX Sounds*](https://www.toptal.com/designers/ux/ux-sounds-guide)). Repetitive tolerance falls sharply with complexity — a toggle heard 100×/day must be subtle, short, warm (same source). This sound's salient body is 250 ms with one gesture: it will not wear out.

### Metaphor over skeuomorphism
The sound doesn't literally record a pen; it *evokes* the feeling of a flick on paper (sonic metaphor — Toptal, above). Material Design's sound guidance makes the same argument: UI sounds should express state and hierarchy with minimal, abstract material rather than literal foley ([Material Design, *Applying sound to UI*](https://m2.material.io/design/sound/applying-sound-to-ui.html); [Google Design, *Sound & Touch: Design Beyond the Screen*](https://design.google/library/ux-sound-haptic-material-design)).

### Pitch/brightness trajectory carries meaning
Rising contours read as *activation, arrival, positivity*; falling contours read as *dismissal, completion, departure* — the Discord join/leave pair is the canonical example (Toptal, above), and earcon research formalized pitch-contour as a semantic channel decades ago ([Brewster, Wright & Edwards, *A detailed investigation into the effectiveness of earcons*, ICAD 1992](https://www.dcs.gla.ac.uk/~stephen/papers/ICAD92.PDF); [Sonification Handbook, ch. 14 Earcons](https://sonification.de/handbook/chapters/chapter14/)). Interesting nuance here: this sound pairs a **rising loudness** with a **falling brightness** — the energy arrives (activation) while the color softens (landing). That's the "swoop into a settle" feel: motion that *completes*.

### Treble-forward spectra suit devices and attention
Phone/laptop speakers cut lows and boost mid-highs, so UI sounds should live where the speaker lives (Toptal, above). High-frequency content also cuts through ambience without needing loudness — frequency separation practice reserves the 8 kHz+ region for crisp attention cues (SFX Engine, above). Psychoacoustics work on product sounds confirms brightness/sharpness is a primary lever of perceived urgency and emotional tone ([IRCAM Amplify, *Designing emotional and intuitive sounds for technology*](https://soundexperience.ircamamplify.com/insights/designing-emotional-and-intuitive-sounds-for-technology-what-psychoacoustics-teaches-us)).

### Design principles distilled

1. **One gesture.** One envelope arc, one spectral idea. No "swoosh + click + chime" stacks.
2. **~250 ms salient body** inside a ~1 s file; let the tail exhale, never hard-cut.
3. **Swept attack, 50–100 ms.** Fast enough to feel responsive (<100 ms feels instant), slow enough to feel like motion.
4. **No bass.** Keep energy above ~2 kHz; center it 6–12 kHz for the paper/air family.
5. **Give brightness a direction.** Falling = settle/complete; rising = open/activate. The direction *is* the message.
6. **Toggle pairs are mirrors.** Same material and length; invert the pitch/brightness contour for on vs off (Discord pattern).
7. **Quiet is a feature.** The sound should sit under speech level; it's felt more than heard.

---

## 3. Prompt recipes

Derived from the measured anatomy. All for the `sfx` CLI (ElevenLabs): `sfx sfx "PROMPT" -d DURATION -o file.mp3 [-i INFLUENCE]`. Influence ~0.3–0.5 keeps interpretation loose (more organic); 0.6–0.8 follows the text tightly. Duration 1 s is right: the model fills the tail with air the way the original does.

### A. Activate (toggle ON — arrival, opening)

1. **The proven formula, restated from measurements**
   `"quick soft airy swoosh swelling into a single gentle high tick, like a fingertip flicking a paper page, bright and papery, no bass, very short, fades instantly to silence"` — `-d 1 -i 0.5`
2. **Rising-contour activate (opening feel)**
   `"tiny rising whoosh of air, quick upward sweep ending in one crisp light tap, delicate and bright, like flicking a small switch up, minimal, ultra short"` — `-d 1 -i 0.5`
3. **Ink-on-paper activate**
   `"single quick pen flick on paper, one short airy stroke with a soft ink dot landing at the end, high frequency, featherlight, no echo"` — `-d 1 -i 0.6`
4. **Brighter, more digital activate**
   `"short bright shimmer sweep upward ending in a single glassy tick, airy and clean, one quick gesture, subtle, immediate silence after"` — `-d 1 -i 0.4`

### B. Deactivate (toggle OFF — dismissal, settle)

5. **Mirror of the winner (falling contour)**
   `"quick soft airy swoosh sweeping downward into a muffled gentle tap, like a paper page settling closed, dark ending, very short, no bass, fades to silence"` — `-d 1 -i 0.5`
6. **Exhale off**
   `"tiny falling whoosh, a short breath of air sinking down with a soft felt dab at the end, quiet, warm, one gesture, ultra brief"` — `-d 1 -i 0.5`
7. **Pen-cap close**
   `"single soft click of a pen cap closing with a faint downward air puff, muted, papery, extremely short and quiet"` — `-d 1 -i 0.6`

### C. Swoop+tap family variations (same formula, new materials)

8. **Fabric/felt variant (warmer)**
   `"quick brush of felt fabric swelling into one soft dab, muted and warm but still airy, single short gesture, no reverb"` — `-d 1 -i 0.5`
9. **Water/glass variant (cooler, playful)**
   `"tiny droplet flick, a quick airy sweep ending in one small bright water blip, light and clean, very short, silence after"` — `-d 1 -i 0.4`
10. **Whisper variant (quieter, for frequent actions)**
    `"barely audible air flick, the faintest quick swoosh with a whisper-soft tick, extremely subtle and short, high frequency only"` — `-d 1 -i 0.5`
11. **Snappier variant (more confirmation weight)**
    `"quick airy flick sweeping into one confident crisp snap, papery and bright, single gesture, tight and short, instant decay"` — `-d 1 -i 0.6`
12. **Double-state pair seed (for future on/off mirroring)**
    `"one short paper flick rising in pitch, delicate airy texture, single gesture under half a second"` then the same prompt with *"falling in pitch"* — `-d 1 -i 0.5` each

**Rules of thumb when iterating:** keep "one/single", "short", "airy", "no bass", and a material word (paper, felt, glass) in every prompt; name the *contour direction* explicitly; ask for "fades to silence" to get the air tail; reject any candidate whose loud body exceeds ~300 ms or that contains two audible events.

---

## 4. Files in this lab

- `analysis/` — `waveform.png`, `mel_spectrogram.png`, `spectral_centroid.png`, `rms_envelope.png`, `onset_strength.png`, `metrics.json`
- `splits/` — `01-swoop-swell.wav` (0–85 ms rise), `02-tap-body.wav` (85–250 ms peak+release), `03-air-tail.wav` (250–930 ms air), `hpss-harmonic.wav` / `hpss-percussive.wav` (librosa HPSS layers), `full-mono.wav`
- `regen/` — new candidates generated from the recipes above, for A/B against the original
- `analyze.py` — reproducible uv script that produced everything in `analysis/` and `splits/`

## Sources

- Toptal — A Quick Guide to Designing UX Sounds: https://www.toptal.com/designers/ux/ux-sounds-guide
- SFX Engine — Best Practices for Game UI Sounds: https://sfxengine.com/blog/best-practices-for-game-ui-sounds
- Material Design — Applying sound to UI: https://m2.material.io/design/sound/applying-sound-to-ui.html
- Google Design — Sound & Touch: Design Beyond the Screen: https://design.google/library/ux-sound-haptic-material-design
- IRCAM Amplify — Designing emotional and intuitive sounds for technology: https://soundexperience.ircamamplify.com/insights/designing-emotional-and-intuitive-sounds-for-technology-what-psychoacoustics-teaches-us
- Brewster, Wright & Edwards — Effectiveness of Earcons (ICAD 1992): https://www.dcs.gla.ac.uk/~stephen/papers/ICAD92.PDF
- Sonification Handbook ch. 14, Earcons: https://sonification.de/handbook/chapters/chapter14/
- Collins — Investigating computational models of perceptual attack time: https://www.composerprogrammer.com/research/pat.pdf
- Google — How Google designers create sounds for Pixel: https://blog.google/products-and-platforms/devices/pixel/google-pixel-sound-design/
