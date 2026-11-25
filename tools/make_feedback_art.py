"""Original pixel silhouettes and synthesized foley for the hall's feedback cues."""

import math
import random
import struct
import wave


# Durations mirror the audible gestures in the loose feedback tuning.
SOUNDS = {
    "snap1": (0.065, 970, 0.65),
    "snap2": (0.065, 890, 0.65),
    "snap3": (0.065, 1050, 0.65),
    "thup1": (0.095, 180, 0.4),
    "thup2": (0.092, 165, 0.4),
    "thup3": (0.090, 195, 0.4),
    "flurry": (0.120, 410, 0.87),
    "ratchet1": (0.045, 720, 0.42),
    "ratchet2": (0.045, 845, 0.4),
    "release": (0.085, 1100, 0.22),
    "spring": (0.090, 420, 0.08),
    "rocketthrow": (0.155, 137, 0.46),
    "tok": (0.070, 530, 0.14),
    "rustle": (0.11, 240, 0.91),
    "brush": (0.085, 360, 0.89),
    "gear": (0.055, 1280, 0.25),
    "knock": (0.075, 240, 0.14),
    "cloth1": (0.09, 145, 0.73),
    "cloth2": (0.085, 162, 0.73),
    "cloth3": (0.095, 136, 0.73),
    "stone1": (0.08, 330, 0.32),
    "stone2": (0.075, 374, 0.32),
    "stone3": (0.085, 304, 0.32),
    "cadence": (0.240, 659, 0.015),
    "practice": (0.220, 392, 0.015),
    "midnight": (0.300, 784, 0.012),
}

PATTERNS = {
    "powder": ("   +   ", "  +#+  ", " +###+ ", "++###++", " +###+ ", "  +#+  ", "   +   "),
    "crumb": (" ## ", "####", " ## "),
    "gear": ("  # #  ", " ####  ", "##  ###", " ## ## ", "  # #  "),
    "mote": ("   #   ", "  #+#  ", " #+++# ", "#+++++#", " #+++# ", "  #+#  ", "   #   "),
    "boot": (" ##### ", " #+### ", " ##+## ", " ##### ", "  #### ", "  #####", "  #####"),
    "footprint": (" ##   ", "####  ", " ##   ", "    ##", "   ###", "    ##"),
    "bellcue": ("   #   ", "  ###  ", " ##### ", " ##### ", "#######", "   +   "),
    "clearcue": ("   #   ", "  #+#  ", " #+++# ", "#+++++#", " #+++# ", "  #+#  ", "   #   "),
    "practicecue": ("  #### ", " #    #", "##+   #", " ##   #", "     # ", "  ###  "),
    "doorcue": ("  ###  ", " #   # ", "#     #", "#   + #", "#     #", "#######"),
    "rearleft": ("   ##  ", " ####  ", "#######", " #### #", "   ## #", "     ##"),
    "rearright": ("  ##   ", "  #### ", "#######", "# #### ", "# ##   ", "##     "),
    "ticks": (
        "#         #",
        " #       # ",
        "  #     #  ",
        "           ",
        "           ",
        "           ",
        "           ",
        "           ",
        "  #     #  ",
        " #       # ",
        "#         #",
    ),
    "finish": (
        "     #     ",
        "    # #    ",
        "   #   #   ",
        "  #     #  ",
        " #       # ",
        "#         #",
        " #       # ",
        "  #     #  ",
        "   #   #   ",
        "    # #    ",
        "     #     ",
    ),
    "scratch": ("     ##", "   ##  ", " ##    "),
    "stamp": ("  ###  ", " ##### ", "#######", " ##### ", "  ###  "),
}


def generate(out, png):
    for name, (duration, freq, noise) in SOUNDS.items():
        rng = random.Random(name)
        data = bytearray()
        phase = low = 0.0
        for i in range(round(duration * 22050)):
            t = i / 22050
            u = t / duration
            second = name in ("midnight", "cadence") and u >= 0.5
            env_t = (u - 0.5) * 2 if second else u
            envelope = min(1, env_t * 90) * math.exp(-5 * env_t) * min(1, (1 - u) * 16)
            f = freq * (1.26 if second else 1)
            if name == "spring":
                f = 420 - 160 * u
            elif noise > 0.1:
                f *= 1 - 0.35 * u
            phase += 2 * math.pi * f / 22050
            low = 0.57 * low + 0.43 * rng.uniform(-1, 1)
            tonal = 0.72 * math.sin(phase) + 0.18 * math.sin(phase * 2.53)
            if name == "rocketthrow":
                tonal += 0.27 * math.sin(2 * math.pi * 700 * t) * math.exp(-50 * t)
            val = (tonal * (1 - noise) + noise * low * 1.6) * envelope
            data.extend(struct.pack("<h", round(22000 * val)))
        with wave.open(str(out / (name + ".wav")), "wb") as clip:
            clip.setparams((1, 2, 22050, 0, "NONE", "not compressed"))
            clip.writeframes(data)
    for name, pattern in PATTERNS.items():
        for border in (1, 2) if name in ("ticks", "finish", "boot") else (1,):
            filled = {(x, y): v for y, row in enumerate(pattern) for x, v in enumerate(row) if v != " "}
            w, h = max(map(len, pattern)) + border * 2, len(pattern) + border * 2
            pixels = []
            for y in range(-border, h - border):
                for x in range(-border, w - border):
                    col = (0, 0, 0, 0)
                    if (x, y) in filled:
                        col = (
                            (197, 137, 77, 255)
                            if name == "crumb"
                            else (244, 197, 103, 255)
                            if name in ("gear", "bellcue")
                            else (224, 246, 243, 255)
                        )
                    elif any(
                        (x + dx, y + dy) in filled
                        for dx in range(-border, border + 1)
                        for dy in range(-border, border + 1)
                    ):
                        col = (25, 45, 57, 220)
                    if name in ("ticks", "finish") and abs(x - 5) <= 1 and abs(y - 5) <= 1:
                        col = (0, 0, 0, 0)
                    if name == "boot" and filled.get((x, y)) == "+":
                        col = (69, 109, 133, 255)
                    pixels.extend(col)
            png(out / (name + ("-contrast" if border == 2 else "") + ".png"), w, h, pixels)
