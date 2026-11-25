"""Sculpt the Day 1 cast and paint its low-resolution materials. Original CC BY 4.0 art."""

import math
import random

from PIL import Image, ImageDraw

from voxel_model import Model


# One strip per painted material. Indexed strips avoid color bleed at mesh seams.
(
    INK,
    RUBBER,
    NAVY,
    BLUE,
    STEEL,
    SILVER,
    BONE,
    GOLD,
    AMBER,
    EMBER,
    WINE,
    RED,
    HIDE,
    PINK,
    MUZZLE,
    BRUISE,
    OLIVE,
    SCALE,
    LIME,
    TEAL,
    CHITIN,
    SHELL,
    VIOLET,
    LILAC,
) = range(24)
COLORS = (
    "19151d",
    "393038",
    "263244",
    "475771",
    "66747b",
    "bac4bd",
    "fff0bc",
    "dcae54",
    "ffe65b",
    "ff6736",
    "622d31",
    "b34137",
    "b57d75",
    "d59a89",
    "eeb599",
    "744c51",
    "514f31",
    "909447",
    "c1c675",
    "397e75",
    "332f42",
    "66536c",
    "95687e",
    "c49bab",
)


def paint_materials(path):
    rng = random.Random(611)
    tile = 24
    im = Image.new("RGB", (tile * len(COLORS), tile))
    for material, color in enumerate(COLORS):
        base = bytes.fromhex(color)
        for y in range(tile):
            for x in range(tile):
                tone = rng.uniform(-0.06, 0.06)
                if HIDE <= material <= BRUISE:
                    tone += 0.065 * math.sin(x * 0.7 + math.sin(y / 3)) - (0.14 if rng.random() < 0.05 else 0)
                elif material in (OLIVE, SCALE, LIME, CHITIN, SHELL, VIOLET):
                    ridge = (x + 2 * (y // 3 % 2)) % 5
                    tone += -0.16 if ridge == 0 and y % 3 != 0 else 0.11 if ridge == 1 else 0
                elif material in (STEEL, SILVER, GOLD):
                    tone += 0.16 if (x - 2 * y) % 29 == 0 else 0
                # The engine uploads an RGBA8 texture; the post pass applies display gamma.
                linear = tuple(round(255 * min(1, v * (1 + tone) / 255) ** 2.2) for v in base)
                im.putpixel((material * tile + x, y), linear)
    im.save(path)


class Sculpt(Model):
    def face(self, points, color, uv=None):
        # Project onto the dominant plane. Each facet samples only its own swatch.
        ranges = [max(p[i] for p in points) - min(p[i] for p in points) for i in range(3)]
        u, v = sorted(range(3), key=lambda i: -ranges[i])[:2]
        low = [min(p[i] for p in points) for i in (u, v)]
        uv = [
            (
                (color + 0.04 + 0.92 * (p[u] - low[0]) / max(ranges[u], 0.001)) / len(COLORS),
                0.04 + 0.92 * (p[v] - low[1]) / max(ranges[v], 0.001),
            )
            for p in points
        ]
        super().face(points, color, uv)

    def oval(self, x, y, z, rx, ry, rz, color, sides=10):
        rings = []
        for t in (-0.94, -0.58, 0, 0.61, 0.95):
            k = math.sqrt(1 - t * t)
            rings.append(
                [
                    (
                        x + rx * k * math.sin(a * math.tau / sides),
                        y + ry * t,
                        z + rz * k * math.cos(a * math.tau / sides),
                    )
                    for a in range(sides)
                ]
            )
        for low, high in zip(rings, rings[1:]):
            for j in range(sides):
                k = (j + 1) % sides
                self.face([low[j], low[k], high[k], high[j]], color)
        self.face(rings[0][::-1], color)
        self.face(rings[-1], color)

    def pipe(self, points, radii, color, sides=7):
        """Tapered continuous sweep for tusks, spines, tubing and bent limbs."""
        rings = []
        for i, (p, radius) in enumerate(zip(points, radii)):
            before, after = points[max(i - 1, 0)], points[min(i + 1, len(points) - 1)]
            axis = [a - b for a, b in zip(after, before)]
            length = math.sqrt(sum(v * v for v in axis))
            dx, dy, dz = (v / length for v in axis)
            # Stable basis for the short curves used here.
            h = math.hypot(dy, dz)
            uy, uz = (dz / h, -dy / h) if h > 0.0001 else (1, 0)
            vx, vy, vz = dy * uz - dz * uy, -dx * uz, dx * uy
            rings.append(
                [
                    (
                        p[0] + radius * vx * math.sin(a * math.tau / sides),
                        p[1]
                        + radius
                        * (uy * math.cos(a * math.tau / sides) + vy * math.sin(a * math.tau / sides)),
                        p[2]
                        + radius
                        * (uz * math.cos(a * math.tau / sides) + vz * math.sin(a * math.tau / sides)),
                    )
                    for a in range(sides)
                ]
            )
        for low, high in zip(rings, rings[1:]):
            for j in range(sides):
                k = (j + 1) % sides
                self.face([low[j], low[k], high[k], high[j]], color)
        self.face(rings[0][::-1], color)
        self.face(rings[-1], color)


def boar(m, riot):
    coat = WINE if riot else NAVY
    m.oval(0, 0.89, 0, 0.46, 0.53, 0.31, coat)
    m.oval(0, 1.23, -0.04, 0.64, 0.35, 0.39, coat)
    m.oval(0, 1.06, 0.23, 0.46, 0.38, 0.21, RUBBER)
    for side in (-1, 1):
        m.oval(side * 0.25, 1.25, 0.26, 0.26, 0.15, 0.13, BLUE if not riot else RED)
        m.box(side * 0.34, 0.78, 0.26, 0.14, 0.20, 0.11, RUBBER)
    m.box(0, 0.77, 0.31, 0.62, 0.09, 0.09, INK)
    m.box(0, 0.77, 0.37, 0.15, 0.08, 0.05, SILVER)
    m.oval(0.23, 1.27, 0.395, 0.074, 0.096, 0.028, GOLD, 6)
    m.oval(0, 1.62, 0.05, 0.35, 0.34, 0.33, HIDE)
    for side in (-1, 1):
        m.oval(side * 0.23, 1.54, 0.24, 0.20, 0.19, 0.22, PINK)
        m.pipe(
            [(side * 0.24, 1.75, 0), (side * 0.43, 1.9, -0.02), (side * 0.48, 2.01, -0.08)],
            [0.14, 0.09, 0.008],
            HIDE,
        )
        m.pipe([(side * 0.26, 1.75, 0.09), (side * 0.43, 1.91, 0.02)], [0.084, 0.012], BRUISE)
        m.oval(side * 0.19, 1.72, 0.322, 0.113, 0.066, 0.04, INK)
        m.oval(side * 0.18, 1.73, 0.355, 0.047, 0.032, 0.015, AMBER)
        m.beam((side * 0.08, 1.76, 0.36), (side * 0.295, 1.82, 0.29), 0.082, BRUISE)
    m.oval(0, 1.46, 0.37, 0.26, 0.11, 0.15, INK)
    m.oval(0, 1.56, 0.40, 0.24, 0.145, 0.22, MUZZLE)
    for side in (-1, 1):
        m.oval(side * 0.10, 1.57, 0.60, 0.054, 0.050, 0.018, INK, 8)
        m.pipe(
            [(side * 0.19, 1.43, 0.38), (side * 0.28, 1.47, 0.48), (side * 0.31, 1.62, 0.50)],
            [0.064, 0.043, 0.007],
            BONE,
        )
    if riot:
        m.oval(0, 1.84, 0.01, 0.37, 0.18, 0.34, RUBBER)
        m.box(0, 1.87, 0.13, 0.44, 0.065, 0.45, RED)
        for z in (-0.17, 0, 0.15):
            m.cone(0, 1.98, z, 0.055, 0.005, 0.11, SILVER, 6)
    else:
        m.oval(0, 1.88, 0.02, 0.33, 0.14, 0.33, NAVY)
        m.oval(0, 1.83, 0.29, 0.31, 0.044, 0.22, INK)
        m.box(0, 1.9, 0.336, 0.09, 0.095, 0.025, GOLD)


def reptile(m):
    m.oval(0, 0.91, 0, 0.32, 0.44, 0.27, OLIVE)
    m.oval(0, 1.23, -0.01, 0.48, 0.28, 0.34, WINE)
    for side in (-1, 1):
        m.beam((side * 0.3, 1.43, 0.19), (side * 0.09, 0.87, 0.29), 0.105, RED)
        m.pipe([(side * 0.39, 0.72, -0.35), (side * 0.39, 1.40, -0.39)], [0.17, 0.21], STEEL)
        m.cone(side * 0.39, 0.62, -0.35, 0.20, 0.13, 0.16, RUBBER)
        m.cone(side * 0.39, 0.54, -0.35, 0.06, 0.12, 0.10, AMBER)
        m.pipe(
            [(side * 0.32, 1.40, -0.35), (side * 0.55, 1.54, -0.60), (side * 0.68, 1.72, -0.78)],
            [0.12, 0.09, 0.006],
            RED,
        )
    m.pipe(
        [(0, 0.69, -0.14), (0, 0.46, -0.46), (0.12, 0.38, -0.69), (0.20, 0.48, -0.92)],
        [0.15, 0.11, 0.065, 0.006],
        SCALE,
    )
    m.oval(0, 1.60, 0.14, 0.26, 0.31, 0.34, SCALE)
    m.oval(0, 1.48, 0.43, 0.21, 0.08, 0.22, LIME)
    m.oval(0, 1.55, 0.41, 0.23, 0.105, 0.27, OLIVE)
    for side in (-1, 1):
        m.oval(side * 0.205, 1.68, 0.36, 0.065, 0.072, 0.087, AMBER)
        m.box(side * 0.222, 1.68, 0.432, 0.024, 0.073, 0.019, INK)
        for z in (0.41, 0.52):
            m.pipe([(side * 0.17, 1.53, z), (side * 0.16, 1.46, z + 0.03)], [0.024, 0.003], BONE)
    for y, z in ((1.83, 0.13), (1.84, -0.05), (1.72, -0.21)):
        m.pipe([(0, y, z), (0, y + 0.16, z - 0.16)], [0.087, 0.008], LIME)


def siege(m):
    # Tracked postal loader, with an exposed muscular pilot perched above its armored hull.
    m.oval(0, 0.65, -0.03, 0.67, 0.46, 0.46, STEEL)
    for side in (-1, 1):
        m.oval(side * 0.49, 0.37, -0.03, 0.23, 0.28, 0.58, RUBBER)
        for z in (-0.37, -0.12, 0.13, 0.38):
            m.box(side * 0.52, 0.19, z, 0.35, 0.10, 0.11, STEEL)
        m.oval(side * 0.28, 1.26, 0, 0.40, 0.35, 0.36, HIDE)
        m.pipe(
            [(side * 0.52, 1.37, -0.17), (side * 0.46, 1.57, -0.24), (side * 0.28, 1.66, -0.14)],
            [0.085] * 3,
            RUBBER,
        )
    m.oval(0, 1.13, 0.17, 0.49, 0.29, 0.30, BRUISE)
    for y in (0.93, 1.05, 1.17):
        m.box(0, y, 0.47, 0.64, 0.075, 0.09, STEEL)
    m.beam((-0.40, 1.41, 0.29), (0.36, 0.89, 0.43), 0.14, NAVY)
    m.oval(0, 1.64, 0.03, 0.32, 0.37, 0.30, MUZZLE)
    m.oval(0, 1.49, 0.28, 0.25, 0.13, 0.16, BRUISE)
    for side in (-1, 1):
        m.oval(side * 0.14, 1.72, 0.29, 0.072, 0.052, 0.032, EMBER)
        m.pipe([(side * 0.17, 1.46, 0.32), (side * 0.25, 1.64, 0.38)], [0.065, 0.006], BONE)
    m.box(0, 0.78, 0.48, 0.31, 0.28, 0.06, RED)


def cyclops(m):
    m.oval(0, 0.91, -0.04, 0.42, 0.58, 0.33, OLIVE)
    for side in (-1, 1):
        m.oval(side * 0.31, 1.29, -0.10, 0.34, 0.38, 0.34, SCALE)
        m.oval(side * 0.27, 1.06, 0.19, 0.26, 0.24, 0.19, TEAL)
    m.oval(0, 1.54, 0.06, 0.46, 0.45, 0.37, OLIVE)
    m.oval(0, 1.65, 0.34, 0.295, 0.21, 0.13, INK)
    m.oval(0, 1.65, 0.42, 0.23, 0.156, 0.10, AMBER)
    m.oval(0, 1.65, 0.505, 0.10, 0.12, 0.035, EMBER)
    m.oval(0, 1.65, 0.536, 0.033, 0.083, 0.014, INK)
    m.oval(-0.059, 1.705, 0.526, 0.036, 0.027, 0.015, BONE)
    for side in (-1, 1):
        m.pipe(
            [(side * 0.24, 1.4, 0.24), (side * 0.31, 1.19, 0.4), (side * 0.19, 1.14, 0.52)],
            [0.087, 0.061, 0.008],
            LIME,
        )
        m.pipe([(side * 0.31, 1.77, -0.05), (side * 0.46, 1.97, -0.21)], [0.10, 0.008], SCALE)


def sovereign(m):
    m.oval(0, 0.72, -0.08, 0.45, 0.44, 0.42, SHELL)
    m.oval(0, 1.18, 0, 0.34, 0.43, 0.27, CHITIN)
    m.oval(0, 1.53, 0, 0.30, 0.26, 0.36, VIOLET)
    # Swept carapace with a fan of crown spines, ribbed thorax and paired mandibles.
    m.oval(0, 1.72, -0.18, 0.53, 0.19, 0.51, SHELL)
    for side in (-1, 1):
        for j in range(3):
            x = side * (0.13 + 0.15 * j)
            m.pipe(
                [(x, 1.74, -0.11), (x * 1.3, 1.96 - 0.055 * j, -0.29), (x * 1.6, 2.23 - 0.09 * j, -0.41)],
                [0.13, 0.078, 0.007],
                VIOLET,
            )
            m.pipe(
                [
                    (side * 0.29, 1.32 - 0.13 * j, 0.08),
                    (side * 0.21, 1.28 - 0.13 * j, 0.25),
                    (side * 0.035, 1.20 - 0.13 * j, 0.28),
                ],
                [0.083, 0.065, 0.028],
                LILAC,
            )
        m.oval(side * 0.195, 1.57, 0.31, 0.088, 0.037, 0.045, EMBER)
        m.pipe(
            [(side * 0.18, 1.45, 0.26), (side * 0.26, 1.31, 0.4), (side * 0.13, 1.28, 0.57)],
            [0.08, 0.058, 0.006],
            BONE,
        )
        m.pipe(
            [(side * 0.27, 1.04, 0), (side * 0.57, 0.78, 0.13), (side * 0.63, 1.02, 0.45)],
            [0.10, 0.075, 0.006],
            SHELL,
        )
    m.pipe(
        [(0, 0.69, -0.31), (0, 0.40, -0.62), (0.18, 0.32, -0.96), (0.39, 0.54, -1.22), (0.40, 0.82, -1.29)],
        [0.20, 0.15, 0.10, 0.067, 0.006],
        VIOLET,
    )


def limbs(name):
    arm, leg = Sculpt(), Sculpt()
    boar_role = name in ("usher", "skater")
    plate = {"usher": NAVY, "skater": RED, "courier": WINE, "loader": STEEL, "guard": TEAL, "queen": SHELL}[
        name
    ]
    skin = HIDE if boar_role or name == "loader" else VIOLET if name == "queen" else SCALE
    arm.oval(0, -0.07, 0, 0.23, 0.23, 0.23, plate)
    arm.pipe([(0, -0.12, 0), (0, -0.36, 0.10), (0, -0.39, 0.31)], [0.145, 0.13, 0.12], skin)
    if name == "queen":
        arm.pipe([(0, -0.32, 0.13), (0, -0.5, 0.34), (0, -0.21, 0.69)], [0.11, 0.08, 0.006], BONE)
    elif name == "loader":
        arm.pipe([(0, -0.39, 0.13), (0, -0.35, 0.64)], [0.20, 0.19], STEEL)
        for j in range(4):
            x, y = 0.10 * math.cos(j * math.pi / 2), -0.35 + 0.10 * math.sin(j * math.pi / 2)
            arm.pipe([(x, y, 0.55), (x, y, 0.86)], [0.06, 0.059], RUBBER)
    elif name in ("usher", "courier"):
        arm.oval(0, -0.38, 0.28, 0.13, 0.105, 0.12, RUBBER)
    else:
        for x in (-0.06, 0.06):
            arm.pipe([(x, -0.39, 0.28), (x, -0.46, 0.47)], [0.055, 0.007], BONE)
    leg.oval(0, -0.12, -0.02, 0.18, 0.21, 0.23, skin if name == "queen" else RUBBER)
    leg.pipe([(0, -0.16, 0.04), (0, -0.30, 0.105), (0, -0.48, -0.06)], [0.14, 0.14, 0.095], plate)
    leg.oval(0, -0.45, 0.08, 0.17, 0.11, 0.27, RUBBER if boar_role or name == "loader" else skin)
    if name == "skater":
        leg.box(0, -0.53, 0.08, 0.11, 0.055, 0.65, SILVER)
        for z in (-0.14, 0.12, 0.31):
            leg.oval(0, -0.55, z, 0.13, 0.06, 0.068, GOLD, 8)
    elif name in ("courier", "guard", "queen"):
        for x in (-0.076, 0.076):
            leg.pipe([(x, -0.46, 0.2), (x * 1.5, -0.5, 0.40)], [0.064, 0.006], BONE)
    return arm, leg


def hatchling(frame):
    """A wet, tooth-ringed slimer. Its feelers plant and release on opposing beats."""
    im = Image.new("RGBA", (64, 64))
    d = ImageDraw.Draw(im)
    beat = (0, 2, 0, -2)[frame]
    for side in (-1, 1):
        for j in range(3):
            stride = (0, 3, 0, -3)[(frame + j + (2 if side > 0 else 0)) % 4]
            points = [
                (32 + side * 12, 38 + beat),
                (32 + side * (19 + j * 2), 35 + j * 4 + stride),
                (32 + side * (23 + j * 2), 37 + j * 5 + stride),
                (32 + side * (25 + j), 34 + j * 5 + stride),
            ]
            d.line(points, fill="#17201c", width=5)
            d.line(points, fill="#698036", width=3)
            d.line(points[1:], fill="#c1bf63", width=1)
    for py in range(10, 55):
        for px in range(9, 55):
            y = (py - 34 - beat) / (19 - beat * 0.5)
            x = (px - 32) / (18.5 - 2.8 * y)
            rr = x * x + y * y
            if rr >= 1:
                continue
            z = math.sqrt(1 - rr)
            light = 0.34 + 0.64 * max(0, -0.38 * x - 0.63 * y + 0.65 * z)
            wrinkle = 0.08 * math.sin(0.7 * px + math.cos(py * 0.5)) + 0.05 * math.sin(py * 1.4 + px * 0.36)
            d.point((px, py), fill=tuple(int((light + wrinkle) * v) for v in (160, 182, 83)) + (255,))
    for side in (-1, 1):
        x = 32 + side * 11
        d.ellipse((x - 4, 24 + beat, x + 3, 28 + beat), fill="#29351d")
        d.line((x - 2, 25 + beat, x + 2, 25 + beat), fill="#fff28b", width=2)
    cy = 38 + beat
    d.ellipse((18, cy - 10, 46, cy + 11), fill="#4d4428")
    d.ellipse((20, cy - 9, 44, cy + 10), fill="#8b4d46")
    d.ellipse((22, cy - 7, 42, cy + 8), fill="#220f1b")
    for j in range(12):
        a = j * math.tau / 12

        def rim(t, rx, ry):
            return (round(32 + rx * math.cos(t)), round(cy + ry * math.sin(t)))

        d.polygon(
            [
                rim(a - 0.15, 11, 8),
                rim(a + 0.15, 11, 8),
                rim(a + 0.12, 6 if j % 2 == 0 else 8, 4 + frame % 2),
            ],
            fill="#eedaaa",
        )
    d.arc((18, cy - 12, 46, cy + 12), 208, 303, fill="#d1ca7a", width=2)
    return im


def build_crew(art, files, save):
    paint_materials(art / "crew-hide.png")
    files.append("missions/day_01/crew-hide.png")
    for frame in range(4):
        name = f"egg-{frame}.png"
        hatchling(frame).save(art / name)
        files.append("missions/day_01/" + name)
    roles = (
        ("usher", 1),
        ("courier", 0.85),
        ("skater", 1),
        ("loader", 1.65),
        ("guard", 1.3),
        ("queen", 2.15),
    )
    for name, scale in roles:
        body = Sculpt()
        body.transform = lambda x, y, z: (x * scale, y * scale, z * scale)
        if name in ("usher", "skater"):
            boar(body, name == "skater")
        else:
            {"courier": reptile, "loader": siege, "guard": cyclops, "queen": sovereign}[name](body)
        arm, leg = limbs(name)
        save(body, name)
        save(leg, name + "-leg")
        save(arm, name + "-arm")
        if name in ("usher", "courier"):
            # Right-hand silhouette stays attached to the shoulder through recoil.
            arm.box(0, -0.33, 0.36, 0.14, 0.13, 0.40, RUBBER)
            if name == "usher":
                arm.box(0, -0.32, 0.53, 0.16, 0.14, 0.34, BRUISE)
                arm.pipe([(0, -0.28, 0.47), (0, -0.28, 0.92)], [0.080, 0.066], STEEL)
                arm.box(0, -0.30, 0.91, 0.10, 0.08, 0.03, INK)
            else:
                arm.oval(0, -0.32, 0.55, 0.13, 0.11, 0.24, TEAL)
                arm.box(0, -0.32, 0.76, 0.14, 0.11, 0.16, STEEL)
                arm.box(0, -0.32, 0.85, 0.087, 0.073, 0.025, AMBER)
            save(arm, name + "-armed")
