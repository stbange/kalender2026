"""Verify the released sprites at display size and the timing of the loose snowcaster samples."""

import math
from pathlib import Path
import struct
import wave
from PIL import Image, ImageChops

assets = Path(__file__).resolve().parents[1] / "games/kalender2026/assets"
for width in (16, 22):
    for suffix in ("", "-contrast"):
        shown = []
        for name in ("ticks", "finish"):
            with Image.open(assets / (name + suffix + ".png")) as src:
                pattern = src.convert("RGBA").resize((width, width), Image.Resampling.NEAREST)
            assert pattern.getpixel((width // 2, width // 2))[3] == 0
            for background in (232, 159, 45):  # snow, brass, timber in grayscale
                backdrop = Image.new("RGBA", pattern.size, (background, background, background, 255))
                gray = Image.alpha_composite(backdrop, pattern).convert("L")
                assert gray.getpixel((width // 2, width // 2)) == background
                lo, hi = gray.getextrema()
                assert hi - lo > 135
            shown.append(gray)
        assert ImageChops.difference(*shown).getbbox()


def samples(name):
    with wave.open(str(assets / (name + ".wav"))) as audio:
        frames = audio.getnframes()
        assert audio.getframerate() == 22050 and audio.getnchannels() == 1
        data = struct.unpack("<" + "h" * frames, audio.readframes(frames))
        return data, frames / audio.getframerate()


for name, duration in {
    "snap1": 0.065,
    "snap2": 0.065,
    "snap3": 0.065,
    "flurry": 0.120,
    "ratchet1": 0.045,
    "ratchet2": 0.045,
    "release": 0.085,
    "spring": 0.090,
    "rocketthrow": 0.155,
    "gear": 0.055,
    "rustle": 0.110,
    "knock": 0.075,
    "brush": 0.085,
    "cadence": 0.240,
    "midnight": 0.300,
}.items():
    data, seconds = samples(name)
    assert abs(seconds - duration) < 0.001, (name, seconds)
    assert max(abs(x) for x in data[:220]) > 600 and max(abs(x) for x in data) < 32767

rms = []
for n in range(1, 4):
    data, _ = samples(f"snap{n}")
    rms.append(math.sqrt(sum(x * x for x in data) / len(data)))
assert 20 * math.log10(max(rms) / min(rms)) < 1.5
data, _ = samples("rocketthrow")


def energy(hz):
    part = data[: int(0.05 * 22050)]
    angle = 2 * math.pi * hz / 22050
    return math.hypot(
        sum(x * math.sin(i * angle) for i, x in enumerate(part)),
        sum(x * math.cos(i * angle) for i, x in enumerate(part)),
    )


assert energy(700) > energy(950) * 1.5
print(
    "Distinct open-centre marks in grayscale, clip onsets, pistol level matching and rocket's 700 Hz slap passed."
)
