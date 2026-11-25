"""Original low-poly view weapons and tiled architecture for Last Launch. Art: CC BY 4.0."""

import math
import random

from PIL import Image, ImageDraw

from make_dispatch_crew import (
    COLORS,
    BLUE,
    BONE,
    EMBER,
    GOLD,
    INK,
    LIME,
    NAVY,
    RED,
    RUBBER,
    SCALE,
    SHELL,
    SILVER,
    STEEL,
    TEAL,
    WINE,
    Sculpt,
)
from voxel_model import Model


def rack_icon(m, path):
    """Rasterize the same silhouette in three-quarter profile for the touch rack."""
    faces = []
    for i in range(0, len(m.verts), 3):
        tri = m.verts[i : i + 3]
        points = [(0.84 * z + 0.54 * x, -y + 0.18 * x - 0.12 * z) for x, y, z, *_ in tri]
        depth = sum(0.54 * v[2] - 0.84 * v[0] - 0.24 * v[1] for v in tri)
        nx, ny, nz = tri[0][3:6]
        shade = 0.73 + 0.32 * max(0, -0.5 * nx + 0.75 * ny + 0.30 * nz)
        base = bytes.fromhex(COLORS[int(tri[0][6] * len(COLORS))])
        faces.append((depth, points, tuple(min(255, round(v * shade)) for v in base)))
    coords = [point for _, points, _ in faces for point in points]
    xs, ys = zip(*coords)
    scale = min(58 / (max(xs) - min(xs)), 32 / (max(ys) - min(ys)))
    cx, cy = (min(xs) + max(xs)) / 2, (min(ys) + max(ys)) / 2
    im = Image.new("RGBA", (64, 38))
    draw = ImageDraw.Draw(im)
    for _, points, color in sorted(faces, key=lambda f: f[0], reverse=True):
        draw.polygon(
            [(round(32 + (x - cx) * scale), round(19 + (y - cy) * scale)) for x, y in points], fill=color
        )
    im.save(path)


def muzzle_sprite(name, path):
    im = Image.new("RGBA", (32, 32))
    d = ImageDraw.Draw(im)
    if name in ("sidearm", "twins"):
        tips = 7 if name == "sidearm" else 5
        for r1, r2, color in ((15, 5, "#f57832"), (10, 4, "#ffcc5b"), (5, 3, "#fff9ce")):
            pts = []
            for i in range(tips * 2):
                a = i * math.pi / tips
                r = r1 if i % 2 == 0 else r2
                pts.append((16 + math.cos(a) * r, 16 + math.sin(a) * r))
            d.polygon(pts, fill=color)
    elif name == "freezer":
        for i in range(6):
            a = i * math.tau / 6
            d.line((16, 16, 16 + 14 * math.cos(a), 16 + 14 * math.sin(a)), fill="#77d8ff", width=3)
        d.polygon([(16, 4), (21, 16), (16, 28), (11, 16)], fill="#edffff")
    elif name == "shrinker":
        d.ellipse((2, 2, 29, 29), outline="#59ff91", width=3)
        d.ellipse((8, 8, 23, 23), outline="#c5ff80", width=2)
        d.rectangle((14, 14, 17, 17), fill="#f4ffc2")
    else:
        for radius, color in ((12, "#ce482b"), (8, "#ff9840"), (4, "#fff3b2")):
            d.ellipse((16 - radius, 16 - radius, 16 + radius, 16 + radius), fill=color)
    im.save(path)


def weapons(art, files, save):
    # Forward is negative Z; details on the breech are visible from first person.
    for name in ("sidearm", "freezer", "rpg", "shrinker", "twins"):
        m, action = Sculpt(), Sculpt()

        def tube(x, y, rear, front, radius, color, end_radius=None):
            m.pipe(
                [(x, y, rear), (x, y, front)],
                [radius, radius if end_radius is None else end_radius],
                color,
                12,
            )

        def grip(x):
            m.box(x, -0.17, 0.17, 0.18, 0.32, 0.22, RUBBER)
            m.oval(x, -0.22, 0.29, 0.15, 0.14, 0.24, NAVY)
            m.oval(x, -0.26, 0.47, 0.13, 0.13, 0.16, WINE)
            for i in range(3):
                m.oval(x - 0.07, -0.13 - i * 0.065, 0.14, 0.105, 0.052, 0.11, RUBBER)

        if name == "sidearm":
            grip(0)
            m.box(0, 0, -0.11, 0.24, 0.17, 0.77, INK)
            action.box(0, 0.085, -0.14, 0.22, 0.11, 0.78, STEEL)
            action.box(0, 0.149, -0.19, 0.12, 0.025, 0.57, SILVER)
            for x in (-0.075, 0.075):
                action.box(x, 0.17, 0.18, 0.046, 0.08, 0.065, INK)
                action.box(x, 0.18, 0.216, 0.024, 0.023, 0.012, BONE)
            action.box(0, 0.18, -0.47, 0.032, 0.074, 0.045, EMBER)
            for i in range(5):
                action.box(0, 0.085, 0.10 - i * 0.044, 0.232, 0.097, 0.013, RUBBER)
            tube(0, 0.035, -0.5, -0.56, 0.066, INK)
        elif name == "freezer":
            grip(0)
            tube(0, 0.02, 0.25, -0.37, 0.245, NAVY, 0.18)
            for i in range(4):
                tube(0, 0.03, 0.16 - i * 0.145, 0.095 - i * 0.145, 0.25 - i * 0.012, STEEL)
            action.oval(0, 0.245, -0.28, 0.115, 0.14, 0.45, TEAL)
            action.oval(0, 0.30, -0.23, 0.065, 0.095, 0.26, BONE, 6)
            for x in (-0.22, 0.22):
                m.pipe(
                    [
                        (x * 0.64, 0.12, 0.13),
                        (x * 1.3, 0.17, -0.22),
                        (x * 1.25, 0.21, -0.57),
                        (x * 0.69, 0.17, -0.86),
                    ],
                    [0.1, 0.088, 0.072, 0.023],
                    SILVER,
                )
                tube(x, 0.22, -0.1, -0.56, 0.045, TEAL)
            m.oval(0, 0.10, -0.62, 0.11, 0.13, 0.28, BONE, 6)
        elif name == "rpg":
            grip(0)
            tube(0, 0.025, 0.42, -0.83, 0.255, SCALE)
            for z, radius in ((0.37, 0.28), (0.01, 0.26), (-0.52, 0.27), (-0.83, 0.29)):
                tube(0, 0.025, z, z - 0.09, radius, RUBBER)
            tube(0, 0.025, -0.85, -1.02, 0.27, STEEL, 0.31)
            tube(0, 0.025, -1.02, -1.11, 0.18, EMBER, 0.04)
            m.box(-0.20, 0.23, -0.22, 0.06, 0.26, 0.11, INK)
            m.box(-0.20, 0.37, -0.22, 0.16, 0.045, 0.1, GOLD)
            tube(0, 0.025, 0.446, 0.408, 0.20, STEEL)
            tube(0, 0.025, 0.462, 0.44, 0.145, RUBBER)
            action.box(0, 0.26, -0.17, 0.23, 0.08, 0.39, STEEL)
            action.box(0, 0.32, -0.14, 0.13, 0.065, 0.10, EMBER)
            for x in (-0.07, 0.07):
                m.box(x, 0.273, 0.1, 0.05, 0.025, 0.27, GOLD)
        elif name == "shrinker":
            grip(0)
            m.oval(0, 0.02, 0.025, 0.23, 0.19, 0.39, SHELL)
            for x in (-0.23, 0.23):
                m.pipe(
                    [(0, 0.02, 0.28), (x, 0.07, 0.06), (x * 1.18, 0.09, -0.49), (x * 0.64, 0.19, -0.69)],
                    [0.13, 0.13, 0.087, 0.015],
                    WINE,
                )
                for j in range(3):
                    m.oval(x, 0.14, -0.05 - j * 0.115, 0.09, 0.06, 0.035, GOLD, 7)
            action.oval(0, 0.17, -0.31, 0.13, 0.17, 0.37, LIME, 5)
            m.oval(0, 0.20, -0.06, 0.09, 0.105, 0.11, TEAL, 6)
        else:
            m.box(-0.43, -0.12, 0.08, 1.0, 0.09, 0.18, RUBBER)
            for x in (-0.93, 0.07):
                grip(x)
                tube(x, 0.025, 0.22, -0.61, 0.165, STEEL)
                tube(x, 0.025, 0.31, 0.20, 0.19, INK)
                tube(x, 0.025, -0.53, -0.78, 0.19, RUBBER)
                if x > 0:
                    action.box(0, 0.18, -0.16, 0.24, 0.095, 0.68, BLUE)
                    for j in range(3):
                        action.box(0, 0.235, 0.06 - j * 0.12, 0.18, 0.024, 0.042, EMBER)
                tube(x, 0.025, -0.78, -0.84, 0.155, RED)
        save(m, name)
        save(action, name + "-action")
        for dx in (-0.93, 0.07) if name == "twins" else (0,):
            m.verts.extend((x + dx, *rest) for x, *rest in action.verts)
        icon = "rack-" + name + ".png"
        rack_icon(m, art / icon)
        files.append("missions/day_01/" + icon)
        bolt = "shot-" + name + ".png"
        muzzle_sprite(name, art / bolt)
        files.append("missions/day_01/" + bolt)


# These faces use repeating UVs. A room can be re-skinned with one editable image.
def sector_skins(art, files, save):
    themes = {
        "brick": [(14, 8, -41), (14, -41, -97)],
        "bulkhead": [(14, -97, -143), (6, -143, -168), (14, -168, -222)],
        "hive": [(14, -222, -253)],
    }
    for name, spans in themes.items():
        im = Image.new("RGB", (64, 64))
        d = ImageDraw.Draw(im)
        if name == "brick":
            d.rectangle((0, 0, 63, 63), fill="#2b252a")
            for row in range(8):
                for col in range(-1, 5):
                    x, y = col * 16 + (row % 2) * 8, row * 8
                    color = ["#804840", "#77423d", "#67423f"][(row + col) % 3]
                    d.rectangle((x + 1, y + 1, x + 15, y + 6), fill=color)
                    d.line((x + 2, y + 1, x + 13, y + 1), fill="#996052")
        elif name == "bulkhead":
            d.rectangle((0, 0, 63, 63), fill="#283742")
            d.rectangle((2, 2, 61, 61), fill="#475763", outline="#71818c", width=2)
            d.rectangle((7, 7, 56, 38), fill="#3a4853", outline="#24313b")
            for y in range(12, 36, 4):
                d.line((13, y, 51, y), fill="#1b272e", width=2)
            for x, y in [(5, 5), (58, 5), (5, 58), (58, 58)]:
                d.rectangle((x, y, x + 1, y + 1), fill="#bac0af")
            d.rectangle((10, 49, 38, 52), fill="#bc964a")
            for x in range(11, 38, 7):
                d.line((x, 52, x + 3, 49), fill="#374248", width=2)
        else:
            for y in range(64):
                for x in range(64):
                    ridge = (math.cos(x * math.tau / 16 + 1.4 * math.sin(y * math.tau / 32)) + 1) / 2
                    vein = (math.cos(y * math.tau / 16 + x * math.tau / 32) + 1) / 2
                    d.point(
                        (x, y),
                        fill=(int(35 + 42 * ridge), int(39 + 41 * ridge + 18 * vein), int(44 + 33 * vein)),
                    )
        rng = random.Random(95)
        pixels = list(im.getdata())
        for i, color in enumerate(pixels):
            shade = rng.uniform(0.91, 1.07)
            pixels[i] = tuple(round(255 * (min(255, c * shade) / 255) ** 1.85) for c in color)
        im.putdata(pixels)
        path = f"wall-{name}.png"
        im.save(art / path)
        files.append("missions/day_01/" + path)
        m = Model()
        for width, front, back in spans:
            for side in (-1, 1):
                x = side * (width - 0.035)
                bay = {8: (1, -23, 29), -41: (-1, -80, 33), -97: (-1, -124, 35), -222: (1, -233, 31)}.get(
                    front
                )
                sections = [(x, front, back)]
                if bay and bay[0] == side:
                    sections = [
                        (x, front, bay[1] + 10),
                        (side * (bay[2] - 0.20), bay[1] + 10, bay[1] - 10),
                        (x, bay[1] - 10, back),
                    ]
                for x, frontZ, backZ in sections:
                    points = [(x, 0, frontZ), (x, 0, backZ), (x, 4, backZ), (x, 4, frontZ)]
                    if side == 1:
                        points.reverse()
                    m.face(points, 0, [(z / 4, y / 4) for _, y, z in points])
        save(m, "wall-" + name)


def floor_tiles(art, files, save):
    # Sheets sit just above the structural floor and below inlaid route markings.
    for name, spans in {
        "deck": [(0, 28, 8, -41), (0, 28, -97, -143), (0, 12, -143, -168), (-24.5, 21, -114, -134)],
        "regolith": [(0, 28, -168, -253), (22.5, 17, -223, -243)],
    }.items():
        rng = random.Random(406)
        im = Image.new("RGB", (64, 64))
        d = ImageDraw.Draw(im)
        if name == "deck":
            d.rectangle((0, 0, 63, 63), fill="#444c55", outline="#242c36", width=2)
            d.line((2, 60, 2, 2, 60, 2), fill="#61676b")
            for x in (5, 58):
                for y in (5, 58):
                    d.rectangle((x - 1, y - 1, x + 1, y + 1), fill="#29313a")
                    d.point((x - 1, y - 1), fill="#858581")
            for i in range(5):
                d.line((22 + 4 * i, 49, 25 + 4 * i, 44), fill="#363c44", width=2)
        else:
            for y in range(64):
                for x in range(64):
                    grit = int(
                        rng.randrange(-6, 7) + 4 * math.sin(x * math.pi / 16 + math.cos(y * math.pi / 16))
                    )
                    im.putpixel((x, y), (85 + grit, 85 + grit, 96 + grit))
            for _ in range(17):
                x, y = rng.randrange(4, 60), rng.randrange(4, 60)
                size = rng.randrange(2, 6)
                d.ellipse((x - size, y - size // 2, x + size, y + size // 2), outline="#45454f")
                d.line((x - size + 1, y + size // 2, x + 1, y + size // 2), fill="#75747c")
        im.putdata([tuple(round(255 * (v / 255) ** 1.85) for v in color) for color in im.getdata()])
        file = "floor-" + name + ".png"
        im.save(art / file)
        files.append("missions/day_01/" + file)
        m = Model()
        for x, width, front, back in spans:
            points = [
                (x - width / 2, -0.006, front),
                (x + width / 2, -0.006, front),
                (x + width / 2, -0.006, back),
                (x - width / 2, -0.006, back),
            ]
            m.face(points, 0, [(px / 4, z / 4) for px, _, z in points])
        save(m, "floor-" + name)
