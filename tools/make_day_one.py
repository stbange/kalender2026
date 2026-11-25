"""Original voxel scenery for Last Launch from Tinseltown. Run this file to regenerate."""

import json
import math
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont
from voxel_model import Model

ROOT = Path(__file__).resolve().parents[1] / "games/kalender2026/missions"
ART = ROOT / "day_01"
ART.mkdir(exist_ok=True)
files = []


def save(model, name):
    model.save(str(ART / name), indexed=True)
    files.append("missions/day_01/" + name + ".glb")


def sign(m, words, x, y, z, width, panel=10, ink=17):
    font = ImageFont.load_default()
    bbox = font.getbbox(words)
    im = Image.new("1", (bbox[2] + 1, bbox[3] + 1))
    ImageDraw.Draw(im).text((0, 0), words, font=font, fill=1)
    im = im.crop(im.getbbox())
    pixel = width / (im.width + 6)
    m.box(x, y, z, width, (im.height + 5) * pixel, 0.12, panel)
    for j in range(im.height):
        i = 0
        while i < im.width:
            start = i
            while i < im.width and im.getpixel((i, j)):
                i += 1
            if i > start:
                m.box(
                    x + ((start + i - im.width) / 2) * pixel,
                    y + ((im.height - 1) / 2 - j) * pixel,
                    z + 0.12,
                    (i - start) * pixel,
                    pixel,
                    0.04,
                    ink,
                )
            else:
                i += 1


def rocket(m, x, y, z, s, body=4):
    m.cone(x, y, z, 1.1 * s, 1.2 * s, 3.5 * s, body)
    m.cone(x, y + 3.48 * s, z, 1.22 * s, 0.04 * s, 1.8 * s, 12)
    for h, c in ((0.4, 11), (2.4, 12), (2.6, 5)):
        m.cone(x, y + h * s, z, 1.23 * s, 1.23 * s, 0.18 * s, c)
    m.box(x, y + 1.5 * s, z + 1.19 * s, 0.85 * s, 0.76 * s, 0.08 * s, 24)
    for d in (-1, 1):
        m.beam(
            (x + d * s, y + 1.3 * s, z),
            (x + d * 1.55 * s, y + 0.12 * s, z),
            0.4 * s,
            12,
        )


def room(i, front, back, width, floor, wall):
    m = Model()
    mid = (front + back) / 2
    m.box(0, -0.27, mid, width * 2, 0.5, front - back, floor)
    # Wide side galleries feed the film archive, dispatch, control and hatchery.
    wing = {
        1: (1, -21, "FILM ARCHIVE"),
        2: (-1, -80, "PARCEL EXCHANGE"),
        3: (-1, -125, "LAUNCH CONTROL"),
        5: (1, -234, "QUARANTINE"),
    }.get(i)
    if wing:
        side, center, title = wing
        m.transform = lambda x, y, z: (side * (14 + (x * side - 14) * 2.85), y, z)
        m.box(side * 53, -0.26, center, 79, 0.5, 28, floor)
        for v in (-14, 14):
            m.box(side * 53, 2, center + v, 79, 4, 0.5, wall)
        m.box(side * 92, 2, center, 0.6, 4, 28, wall)
        for j in range(1, 4):
            u = 18 + j * 19
            gap = (-1) ** j * 8
            for a, b in ((-14, gap - 3.4), (gap + 3.4, 14)):
                m.box(u * side, 1.85, center + (a + b) / 2, 0.8, 3.7, b - a, wall)
            m.box(u * side, 4, center, 0.8, 0.6, 28, 2)
        sign(m, title, 24 * side, 3.5, center - 12, 14, wall)
        for n, (u, v) in enumerate(((25, -9), (47, 9), (69, -9), (87, 8))):
            x, z = u * side, center + v
            m.box(x, 0.65, z, 2.4, 1.3, 1.3, wall)
            m.box(x, 1.39, z, 1.8, 0.18, 0.82, 16)
            sign(m, ("01", "02", "03", "04")[n], x, 1.9, z, 1.8, 1, 17)
            for dz in (-5, 5):
                if i == 1:
                    for h in (0.3, 0.85, 1.4):
                        m.cone(x + 3 * side, h, z + dz, 1.1, 1.1, 0.28, 3, 12)
                elif i == 2:
                    for h in (0.55, 1.65):
                        m.box(x + 3 * side, h, z + dz, 1.8, 1.08, 2, 8)
                        m.box(x + 3 * side, h, z + dz + 1.02, 0.23, 1.08, 0.08, 12)
                elif i == 3:
                    m.cone(x + 3 * side, 0, z + dz, 1.1, 1.1, 3.6, 2, 10)
                    m.cone(x + 3 * side, 2.8, z + dz, 1.14, 1.14, 0.25, 15)
                else:
                    m.cone(x + 3 * side, 0, z + dz, 1, 1.28, 1.6, 20, 8)
                    m.cone(x + 3 * side, 1.6, z + dz, 1.28, 0.1, 1.1, 22, 8)

        m.transform = None
        for u in range(17, 234, 7):
            m.box(side * u, 0.01, center, 0.24, 0.06, 25, 3)
            for dz in (-12, 12):
                m.box(side * u, 2.7, center + dz, 0.4, 5.4, 0.5, 2)
                m.box(side * u, 4.8, center + dz, 0.8, 0.4, 0.6, 17)
        track = [
            (14, 0),
            (20, -4),
            (25, -9),
            (37, -8),
            (42, 5),
            (47, 9),
            (56, 8),
            (62, -4),
            (69, -9),
            (75, -8),
            (81, 6),
            (87, 8),
        ]
        for (a, b), (c, d) in zip(track, track[1:]):
            for offset in (-0.65, 0.65):
                m.beam(
                    (side * (14 + (a - 14) * 2.85), 0.08, center + b + offset),
                    (side * (14 + (c - 14) * 2.85), 0.08, center + d + offset),
                    0.09,
                    15,
                )
    for d in (-1, 1):
        opening = wing[1] if wing and wing[0] == d else -261 if i == 6 and d == 1 else None
        spans = [(back, opening - 3.3), (opening + 3.3, front)] if opening is not None else [(back, front)]
        for a, b in spans:
            m.box(d * (width + 0.15), 2, (a + b) / 2, 0.32, 4, b - a, wall)
        for z in range(back + 3, front, 6):
            if opening is not None and abs(z - opening) < 3.3:
                continue
            m.box(d * (width - 0.15), 1.9, z, 0.52, 3.9, 0.5, 2)
            m.box(d * (width - 0.44), 2.9, z, 0.12, 0.45, 0.38, 17)
    for d in (-1, 1):
        m.box(d * (width + 3.5) / 2, 2, back, width - 3.5, 4, 0.5, wall)
    m.box(0, 4.35, back, 2 * width, 0.7, 0.5, wall)
    return m


def cinema():
    m = room(1, 8, -41, 14, 1, 10)
    m.face([(-13, 0, -9), (-13, 3.25, 2), (13, 3.25, 2), (13, 0, -9)], 3)
    m.box(0, 1.59, 5, 26, 3.2, 6, 3)
    for x in (-11, 11):
        for z in range(-36, 9, 7):
            if x > 0 and abs(z + 21) < 5:
                continue
            m.box(x, 4.2, z, 5, 9, 6, 1)
            for a in (-1.4, 0, 1.4):
                for h in (2, 4, 6, 8):
                    m.box(x + a, h, z + 3.03, 0.7, 0.8, 0.08, 15 if (h + z) % 3 else 23)
    # A stepped nickel-plated marquee, velvet ticket windows and a winter skyline.
    for i in range(23):
        x = (i - 11) * 5.3
        h = 5 + (i * 19) % 14
        z = -50 - (i % 4) * 3.2
        m.box(x, h / 2, z, 4.5, h, 3.3, 1 if i % 3 else 23)
        for j in range(2, int(h), 2):
            for off in (-1.3, 0, 1.3):
                m.box(x + off, j, z + 1.67, 0.53, 0.66, 0.08, 15 if (i + j) % 3 else 24)
    for x in (-7, 7):
        m.box(x, 2, -13.2, 3.3, 4.2, 1.3, 11)
        m.box(x, 3.3, -13.02, 2.86, 3.55, 0.4, 15)
        m.box(x, 0.85, -12.4, 3.4, 0.18, 0.7, 16)
    m.box(0, 4.83, -12.3, 14.7, 0.22, 2.1, 15)
    m.box(0, 6.78, -12.3, 14.6, 0.18, 2.1, 16)
    m.box(18, -0.25, -261, 8.5, 0.5, 7.3, 2)
    m.box(22, 1.9, -261, 0.35, 3.8, 7, 11)
    for z in (-264.4, -257.6):
        m.box(18, 0.5, z, 8, 1, 0.25, 15)
        m.box(18, 3.8, z, 8, 0.3, 0.25, 11)
    sign(m, "PRESS BOX", 18, 2.9, -264.5, 4, 10)
    sign(m, "MOON BOWL", 0, 5.85, -11.30, 13, 11)
    for n in range(27):
        m.box(n * 0.52 - 6.8, 4.95, -11.8, 0.2, 0.2, 0.2, 17 if n % 2 else 13)
    m.box(0, 3.3, -37, 15, 6.5, 0.6, 7)
    m.box(0, 3.3, -36.65, 14, 5.8, 0.1, 4)
    for x in (-11, 11):
        m.box(x, 2.8, -36, 4, 5.6, 1.7, 11)
    for z in (-18, -22, -26):
        for x in (-8, -6, -4, 4, 6, 8):
            m.box(x, 0.5, z, 1.25, 0.45, 1.2, 12)
            m.box(x, 0.98, z + 0.48, 1.25, 0.85, 0.24, 11)
    m.box(9, 1, -21, 1.6, 1.8, 1.2, 1)
    for x in (8.5, 9.5):
        m.cone(x, 1.9, -21, 0.38, 0.38, 0.3, 3)
    for x in range(-10, -5):
        m.box(x, 0.04, -9, 0.4, 0.05, 3, 3)
    m.cone(-11, 0.1, -27, 0.55, 0.7, 0.7, 4)
    save(m, "cinema")


def diner():
    m = room(2, -41, -97, 14, 4, 24)
    for z in range(-95, -41, 2):
        for x in range(-12, 13, 2):
            if (x + z) % 4 == 1:
                m.box(x, 0.007, z, 1.99, 0.02, 1.99, 1)
    for x in (-12, 12):
        for z in range(-74, -44, 5):
            m.box(x, 0.9, z, 2.5, 1.8, 1.3, 12)
            m.box(x, 1.1, z - 1.8, 2.6, 0.15, 1.3, 5)
    sign(m, "NIGHT SHIFT DINER", 0, 4.8, -52, 17, 24)
    m.box(9, 0.55, -66, 4, 1.1, 1.3, 25)
    m.cone(9, 1.13, -66, 0.44, 0.08, 0.27, 16)
    sign(m, "DEAD LETTER OFFICE", 0, 4.8, -79, 15, 11)
    for x in (-12, 12):
        for z in range(-94, -77, 4):
            for y in (0.6, 1.9):
                m.box(x, y, z, 2.4, 1.2, 2.1, 8)
                m.box(x, y, z + 1.07, 0.38, 1.2, 0.05, 16)
    save(m, "diner")


def silos():
    m = room(3, -97, -143, 14, 2, 23)
    for x in (-9, 9):
        for d in (-2.8, 2.8):
            m.box(x + d, 7, -122, 0.5, 14, 0.5, 12)
        for h in range(0, 15, 3):
            m.beam((x - 2.8, h, -122), (x + 2.8, h + 2.8, -122), 0.25, 15)
            m.box(x, h, -122, 6, 0.23, 2, 3)
    for z in range(-140, -98, 4):
        m.box(0, 0.04, z, 0.45, 0.05, 1.7, 16)
    rocket(m, 6, 0, -139, 2)
    sign(m, "EXPRESS  /  PAD 02", 0, 5, -139, 12, 23)
    save(m, "silos")


def flight():
    m = room(4, -143, -168, 6, 2, 1)
    for z in range(-165, -144, 4):
        for x in (-5, 5):
            m.box(x, 2.4, z, 1, 3, 2.7, 24)
            m.box(x, 2.4, z + 1.38, 0.92, 2.2, 0.05, 0)
    m.box(0, 2.5, -166, 10, 5, 0.4, 0)
    for i in range(38):
        x = math.sin(i * 23.4) * 4.8
        y = (i * 1.393) % 3.8 + 0.5
        m.box(x, y, -165.7, 0.05, 0.06, 0.05, 4)
    sign(m, "LUNAR MAIL SERVICE", 0, 4.8, -155, 9, 23)
    save(m, "cabin")


def luna():
    m = room(5, -168, -253, 14, 3, 1)
    for i in range(50):
        x = (-1) ** i * (9 + (i * 1.37) % 4)
        z = -171 - i * 1.57
        m.cone(x, 0, z, 0.5 + i % 4 * 0.24, 0.2, 0.16 + i % 3 * 0.16, 2, 7)
    sign(m, "LUNA  /  CUSTOMS", 0, 5, -181, 15, 23)
    for x in (-11, 11):
        m.box(x, 0.7, -191, 3, 1.4, 4, 24)
    for z in range(-220, -198, 2):
        m.box(0, 0.1, z, 24, 0.12, 0.33, 8)
    for x in (-9, 9):
        m.box(x, 0.23, -210, 0.25, 0.25, 25, 15)
    for x, z in ((-6, -205), (4, -211), (-4, -217)):
        m.box(x, 1.5, z, 3, 0.5, 2.2, 9)
        m.box(x, 2.7, z, 0.55, 2.4, 0.6, 12)
        m.box(x, 4, z, 3, 0.6, 1, 11)
    for x in (-11, 11):
        for z in range(-249, -225, 4):
            m.cone(x, 0.1, z, 1.2, 0.9, 2.1, 20, 8)
            m.cone(x, 2.2, z, 0.9, 0.1, 0.85, 22, 8)
    sign(m, "ORNAMENT INCUBATOR", 0, 4.9, -235, 14, 18)
    save(m, "luna")


def bowl():
    m = room(6, -253, -308, 14, 19, 1)
    for z in range(-305, -252, 4):
        m.box(0, 0.03, z, 25, 0.04, 0.15, 4)
        for x in (-4, 4):
            m.box(x, 0.04, z + 2, 0.3, 0.05, 0.62, 5)
    for side in (-1, 1):
        for row in range(4):
            x = side * (14 + row * 1.8)
            if side == 1:
                m.box(x, row * 0.7, -283.8, 2, 1.8, 38.4, 2)
            else:
                m.box(x, row * 0.7, -279, 2, 1.8, 48, 2)
            for n in range(20):
                z = -301 + n * 2.3
                if side == 1 and abs(z + 261) < 4:
                    continue
                m.box(
                    x,
                    1.5 + row * 0.7,
                    z,
                    0.65,
                    0.9,
                    0.25,
                    [12, 15, 25, 20][(n + row) % 4],
                )
                m.box(x, 2.16 + row * 0.7, z, 0.46, 0.46, 0.2, 9)
    m.box(0, 1.2, -278, 0.25, 2.4, 0.25, 16)
    m.box(0, 2.4, -278, 6, 0.24, 0.25, 16)
    for x in (-3, 3):
        m.box(x, 3.7, -278, 0.22, 2.7, 0.25, 16)
    for x, z in ((-8, -266), (8, -289)):
        m.box(x, 1.3, z, 0.35, 2.6, 0.35, 16)
        m.box(x, 2.65, z, 2.4, 0.25, 0.25, 15)
        for dx in (-1.15, 1.15):
            m.box(x + dx, 3.1, z, 0.22, 1, 0.24, 16)
    for x in (-12, 12):
        for z in (-263, -297):
            m.box(x, 5, z, 0.4, 10, 0.4, 2)
            m.box(x, 10, z, 3, 0.9, 1, 17)
    sign(m, "MOON BOWL", 0, 6.5, -303, 16, 10)
    save(m, "bowl")


def props():
    prize = Model()
    rocket(prize, 0, 0, 0, 0.30, 16)
    prize.cone(0, 1.58, 0, 0.08, 0.08, 0.14, 15)
    prize.beam((0, 1.7, 0), (0.16, 1.85, 0), 0.045, 16)
    prize.beam((0.16, 1.85, 0), (0, 2, 0), 0.045, 16)
    prize.beam((0, 2, 0), (-0.16, 1.85, 0), 0.045, 16)
    prize.beam((-0.16, 1.85, 0), (0, 1.7, 0), 0.045, 16)
    prize.save(str(ROOT.parent / "assets/brass-rocket"), indexed=True)
    for name in ("cracker", "freezer", "shrinker", "twins"):
        m = Model()
        if name == "cracker":
            m.box(0, 0, 0, 0.37, 0.45, 0.32, 1)
            m.box(0, 0.24, 0, 0.18, 0.12, 0.15, 12)
            m.box(0.12, 0.39, -0.08, 0.025, 0.48, 0.025, 3)
            m.box(0, 0.03, -0.16, 0.23, 0.09, 0.04, 16)
        else:
            barrels = (-0.24, 0.24) if name == "twins" else (0,)
            for x in barrels:
                c = 24 if name == "freezer" else 20 if name == "shrinker" else 11
                m.box(x, -0.13, 0.15, 0.20, 0.37, 0.22, 1)
                m.box(x, 0.02, -0.03, 0.35, 0.27, 0.77, c)
                for n in range(4):
                    m.box(
                        x,
                        0.04,
                        -0.45 + n * 0.13,
                        0.4,
                        0.32,
                        0.055,
                        26 if name == "freezer" else 22 if name == "shrinker" else 16,
                    )
                m.box(x, 0.04, -0.5, 0.24, 0.19, 0.1, 1)
        save(m, name)
    for key, caption in (
        ("use", "USE"),
        ("freeze", "FREEZE"),
        ("click", "REMOTE"),
        ("shrink", "SHRINK"),
        ("clear", "GOAL POST"),
        ("escort", "ESCORT"),
        ("launch", "LAUNCH"),
        ("home", "EXIT"),
        ("rocket", "ROCKET"),
    ):
        im = Image.new("RGBA", (90, 24))
        draw = ImageDraw.Draw(im)
        draw.rounded_rectangle((1, 1, 88, 22), radius=4, fill="#19333c", outline="#f7cb78", width=2)
        draw.text((45, 12), caption, anchor="mm", fill="#fff0c5")
        f = "cue-" + key + ".png"
        im.save(ART / f)
        files.append("missions/day_01/" + f)
    for frame in range(4):
        im = Image.new("RGBA", (32, 32))
        d = ImageDraw.Draw(im)
        bob = frame % 2
        d.ellipse((5, 8 + bob, 26, 26 + bob), fill="#31594a", outline="#152c2c", width=2)
        d.polygon(
            [(6, 13), (4, 3 + bob), (14, 11), (21, 8), (28, 3), (26, 15)],
            fill="#81bf8b",
        )
        d.rectangle((8, 14 + bob, 13, 17 + bob), fill="#ffdb86")
        d.rectangle((19, 14 + bob, 24, 17 + bob), fill="#ffdb86")
        d.rectangle((12, 21, 20, 22), fill="#152c2c")
        d.rectangle((5, 26 - bob, 12, 29 - bob), fill="#e7986e")
        d.rectangle((19, 25 + bob, 26, 28 + bob), fill="#e7986e")
        file = f"egg-{frame}.png"
        im.save(ART / file)
        files.append("missions/day_01/" + file)

    for i, name in enumerate(("usher", "courier", "skater", "loader", "guard", "queen", "hatchling")):
        m = Model()
        s = [1, 0.85, 1, 1.65, 1.3, 2.15, 0.53][i]
        color = [11, 24, 12, 15, 20, 29, 22][i]
        m.transform = lambda x, y, z: (x * s, y * s, z * s)
        for x in (-0.26, 0.26):
            m.box(x, 0.27, 0, 0.36, 0.54, 0.48, 1)
            m.box(x, 0.12, 0.17, 0.4, 0.2, 0.62, 3 if i == 2 else 0)
        m.box(0, 0.89, 0, 0.92, 0.83, 0.68, color)
        m.box(0, 1.55, 0.04, 0.79, 0.62, 0.61, 21 if i >= 4 else 8)
        m.box(0, 1.48, 0.39, 0.55, 0.24, 0.25, 13)
        for x in (-0.21, 0.21):
            m.box(x, 1.67, 0.36, 0.13, 0.12, 0.09, 17)
            m.box(x * 2.8, 1.02, 0.11, 0.27, 0.55, 0.35, color)
            m.box(x * 1.7, 1.89, 0, 0.18, 0.29, 0.2, 16 if i == 5 else 8)
        m.box(0, 1.91, 0.02, 0.85, 0.16, 0.76, 16 if i == 5 else color)
        if i == 2:
            for x in (-0.26, 0.26):
                m.box(x, 0.05, 0.12, 0.13, 0.1, 0.92, 3)
                for z in (-0.22, 0.34):
                    m.box(x, 0.08, z, 0.36, 0.16, 0.18, 0)
        if i == 3:
            for x in (-0.68, 0.68):
                m.box(x, 0.48, -0.1, 0.37, 0.9, 1.3, 1)
                for z in (-0.5, -0.12, 0.28):
                    m.box(x, 0.22, z, 0.39, 0.23, 0.26, 3)
                m.box(x * 1.22, 1.05, 0.2, 0.40, 0.62, 0.52, 15)
                m.beam((x * 1.22, 1.05, 0.2), (x * 1.5, 0.48, 0.65), 0.22, 3)
            m.box(0, 1.15, 0.53, 1.15, 0.75, 0.17, 8)
            m.box(0, 1.15, 0.64, 0.22, 0.75, 0.07, 16)
        if i == 5:
            for x in (-0.34, 0, 0.34):
                m.cone(x, 1.94, 0, 0.13, 0, 0.36, 16)
        if i == 1:
            for x in (-0.3, 0.3):
                m.cone(x, 0.54, -0.42, 0.2, 0.18, 0.8, 15)
        save(m, name)
    m = Model()
    rocket(m, 0, 0, 0, 1)
    save(m, "rocket")
    m = Model()
    m.box(0, 0.55, 0, 2.8, 0.33, 1.5, 3)
    m.box(0, 1, 0, 1.6, 0.8, 1, 11)
    m.box(0, 1, 0, 0.28, 0.84, 1.04, 16)
    for x in (-0.9, 0.9):
        m.box(x, 0.25, 0, 0.42, 0.45, 1.3, 1)
    save(m, "cart")
    m = Model()
    m.cone(0, 0, 0, 0.4, 1.6, 1.1, 15)
    m.cone(0, 1.1, 0, 1.6, 0.5, 1.55, 17)
    for x in (-0.4, 0.4):
        m.box(x, 1.38, 1, 0.24, 0.24, 0.13, 1)
    save(m, "plywood")
    m = Model()
    sign(m, "RETURN TO SENDER", 0, 0, 0, 14, 11)
    save(m, "score")
    m = Model()
    sign(m, "OUT OF ORDER", 0, 0, 0, 3, 11)
    save(m, "out")
    m = Model()
    m.cone(0, 0, 0, 0.8, 1.1, 1.3, 17, 8)
    m.cone(0.7, 0.8, 0, 0.5, 0.28, 0.9, 5, 7)
    save(m, "corn")
    m = Model()
    m.cone(0, 0, 0, 0.5, 1.15, 0.8, 24, 12)
    m.cone(0, 0.8, 0, 1.15, 0.4, 1.2, 25, 12)
    for x, y in ((-0.5, 0.9), (0.2, 1.3), (0.6, 0.7)):
        m.box(x, y, 0.9, 0.43, 0.25, 0.18, 21)
    save(m, "earth")


def flyers():
    im = Image.new("RGB", (128, 160), "#162134")
    d = ImageDraw.Draw(im)
    for y in range(100):
        d.line((0, y, 128, y), fill=(22 + y // 4, 32 + y // 6, 62 + y // 4))
    for n in range(84):
        x = (n * 43) % 126
        y = (n * 61) % 85
        d.point((x, y), fill="#e8ca8e")
    d.ellipse((46, 20, 112, 86), fill="#efd393")
    for x, y, r in ((70, 40, 6), (90, 61, 8), (79, 71, 3), (98, 44, 4)):
        d.ellipse((x - r, y - r, x + r, y + r), fill="#ddb274")
    d.polygon([(5, 116), (84, 35), (77, 68), (37, 113)], fill="#db7058")
    d.polygon([(37, 94), (53, 63), (69, 47), (84, 35), (76, 55), (59, 81)], fill="#faf0cb")
    d.polygon([(39, 90), (39, 72), (51, 68), (57, 63)], fill="#b64c4f")
    d.rectangle((0, 110, 127, 159), fill="#152334")
    for i in range(14):
        x = i * 10
        y = 88 + (i * 17) % 22
        d.rectangle((x, y, x + 8, 114), fill="#101e2c")
        for h in range(y + 3, 111, 5):
            d.point((x + 2, h), fill="#e9b870")
    for y in (3, 5, 122, 153, 156):
        d.line((4, y, 123, y), fill="#d78b59")
    d.text((12, 126), "THE LAST LAUNCH", fill="#fff0c5")
    d.text((21, 140), "ONE NIGHT ONLY", fill="#edb479")
    im.save(ART / "matinee.png")
    files.append("missions/day_01/matinee.png")
    m = Model()
    for x, z, y, w, h in (
        (-7, -12.15, 3.3, 2.6, 3.3),
        (7, -12.15, 3.3, 2.6, 3.3),
        (0, -36.5, 3.45, 10, 4.8),
    ):
        m.face(
            [
                (x - w / 2, y - h / 2, z),
                (x + w / 2, y - h / 2, z),
                (x + w / 2, y + h / 2, z),
                (x - w / 2, y + h / 2, z),
            ],
            0,
            [(0, 1), (1, 1), (1, 0), (0, 0)],
        )
    save(m, "poster")


def soundtrack():
    import struct
    import wave

    # Short original tracker cues. The cinema phrase resolves at the lunar landing.
    cues = {
        "d1-remote": ([910, 590], 0.045),
        "d1-freeze": ([950, 1160, 1440], 0.055),
        "d1-shrink": ([765, 574, 430, 322], 0.045),
        "d1-twins": ([155, 92], 0.038),
        "d1-marquee": ([330, 392, 494, 440, 392, 330, 294, 247], 0.165),
        "d1-earthrise": ([247, 330, 370, 440, 494, 659, 587, 494], 0.24),
        "d1-score": ([392, 494, 587, 784, 659, 784], 0.145),
    }
    for name, (notes, beat) in cues.items():
        samples = bytearray()
        for j, note in enumerate(notes):
            for i in range(int(22050 * beat)):
                t = i / 22050
                envelope = min(1, t / 0.007) * math.exp(-3 * t / beat)
                tone = math.sin(2 * math.pi * note * t) + 0.22 * math.sin(4 * math.pi * note * t)
                if len(notes) > 4:
                    tone += 0.37 * math.sin(2 * math.pi * (note / 2) * t)
                samples.extend(struct.pack("<h", int(tone * envelope * 10000)))
        with wave.open(str(ROOT.parent / "assets" / (name + ".wav")), "wb") as f:
            f.setparams((1, 2, 22050, 0, "NONE", "not compressed"))
            f.writeframes(samples)


if __name__ == "__main__":
    soundtrack()
    flyers()
    for build in (cinema, diner, silos, flight, luna, bowl, props):
        build()
    catalog = {
        "revision": "last-launch-open-1",
        "missions": [
            {
                "day": 1,
                "title": "Last Launch from Tinseltown",
                "script": "missions/day_01.lua",
                "files": files,
            }
        ],
    }
    (ROOT / "catalog.json").write_text(json.dumps(catalog, indent=2) + "\n")
