"""Synthesises the Rest & Rep alert sounds as 44.1 kHz mono 16-bit WAV files."""
import math, struct, sys, wave

RATE = 44100

def tone(freq, dur, amp=0.6, attack=0.005, release=0.08, harmonics=(1.0, 0.25, 0.08)):
    n = int(RATE * dur)
    out = []
    for i in range(n):
        t = i / RATE
        env = min(1.0, t / attack) * min(1.0, (dur - t) / release)
        decay = math.exp(-3.0 * t / dur)
        s = sum(h * math.sin(2 * math.pi * freq * (k + 1) * t) for k, h in enumerate(harmonics))
        out.append(amp * env * decay * s / sum(harmonics))
    return out

def silence(dur):
    return [0.0] * int(RATE * dur)

def write(path, samples):
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(b"".join(struct.pack("<h", int(max(-1, min(1, s)) * 32767)) for s in samples))

out = sys.argv[1]
write(f"{out}/tick.wav", tone(1760, 0.08, amp=0.5, release=0.04, harmonics=(1.0,)))
write(f"{out}/work.wav", tone(1046.5, 0.12, release=0.03) + tone(1568.0, 0.33))
write(f"{out}/rest.wav", tone(523.25, 0.12, release=0.03) + tone(392.0, 0.43))
write(f"{out}/finish.wav",
      tone(783.99, 0.22) + silence(0.03) + tone(987.77, 0.22) + silence(0.03) + tone(1174.66, 0.62))
