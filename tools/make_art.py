"""Build the original loose GLB, pixel-art and audio files for The Lantern Hall."""

import json
import math
import random
import struct
import wave
import zlib
from pathlib import Path

from make_holiday_art import build_holiday_art

OUT = Path(__file__).resolve().parents[1] / "games/kalender2026/assets"
OUT.mkdir(exist_ok=True, parents=True)
rng = random.Random(20261201)
colors = [
    "141e30",
    "28374a",
    "43566a",
    "8495a6",
    "cad3ce",
    "f8eacb",
    "50312a",
    "764836",
    "ab7451",
    "c99a68",
    "38262b",
    "7f2831",
    "b93c41",
    "ee6959",
    "97713e",
    "cc9350",
    "ffd37a",
    "fff2a5",
    "183833",
    "245844",
    "367656",
    "529569",
    "88b887",
    "162d40",
    "25526b",
    "3c8294",
    "79c5d0",
    "c8f2e8",
    "392c4c",
    "755375",
    "bb8eab",
    "f4f4eb",
]


def png(path, w, h, pixels):
    def chunk(k, v):
        return struct.pack(">I", len(v)) + k + v + struct.pack(">I", zlib.crc32(k + v) & 0xFFFFFFFF)

    raw = b"".join(b"\0" + bytes(pixels[y * w * 4 : (y + 1) * w * 4]) for y in range(h))
    path.write_bytes(
        b"\x89PNG\r\n\x1a\n"
        + chunk(b"IHDR", struct.pack(">IIBBBBB", w, h, 8, 6, 0, 0, 0))
        + chunk(b"IDAT", zlib.compress(raw, 9))
        + chunk(b"IEND", b"")
    )


png(
    OUT / "palette.png",
    32,
    1,
    [v for c in colors for v in (*[round(255 * (ch / 255) ** 1.85) for ch in bytes.fromhex(c)], 255)],
)
for name in ("ember", "snow", "spark"):
    pixels = []
    for y in range(16):
        for x in range(16):
            dx, dy = x - 7.5, y - 7.5
            if name == "ember":
                radius = (6 - abs(dy) * 0.48) * (1 + dy * 0.06)
                col = (
                    255,
                    210 if abs(dx) < 2 else 132,
                    65,
                    245 if abs(dx + 0.18 * dy) < radius and y > 1 else 0,
                )
            else:
                on = abs(dx) < 1 or abs(dy) < 1 or (abs(abs(dx) - abs(dy)) < 1 and abs(dx) < 4)
                col = (185, 227, 242, 215 if on and abs(dx) + abs(dy) < 8 else 0)
            pixels.extend(col)
    png(OUT / (name + ".png"), 16, 16, pixels)


class Model:
    def __init__(self):
        self.verts = []
        self.transform = None

    def face(self, points, c, uv=None):
        if self.transform:
            points = [self.transform(*p) for p in points]
        a, b, d = points[:3]
        ab = [b[i] - a[i] for i in range(3)]
        ac = [d[i] - a[i] for i in range(3)]
        n = [ab[1] * ac[2] - ab[2] * ac[1], ab[2] * ac[0] - ab[0] * ac[2], ab[0] * ac[1] - ab[1] * ac[0]]
        length = math.sqrt(sum(x * x for x in n)) or 1
        for i in range(1, len(points) - 1):
            for j in (0, i, i + 1):
                coords = uv[j] if uv is not None else ((c + 0.5) / 32, 0.5)
                self.verts.append((*points[j], *(v / length for v in n), *coords))

    def box(self, x, y, z, w, h, d, c):
        a, b = x - w / 2, x + w / 2
        l, u = y - h / 2, y + h / 2
        f, k = z - d / 2, z + d / 2
        v = [(a, l, f), (b, l, f), (b, u, f), (a, u, f), (a, l, k), (b, l, k), (b, u, k), (a, u, k)]
        for ids in ((3, 2, 1, 0), (4, 5, 6, 7), (0, 4, 7, 3), (1, 2, 6, 5), (3, 7, 6, 2), (0, 1, 5, 4)):
            self.face([v[i] for i in ids], c)

    def cone(self, x, y, z, r1, r2, h, c, n=10):
        low = [
            (x + r1 * math.sin(i * 2 * math.pi / n), y, z + r1 * math.cos(i * 2 * math.pi / n))
            for i in range(n)
        ]
        high = [
            (x + r2 * math.sin(i * 2 * math.pi / n), y + h, z + r2 * math.cos(i * 2 * math.pi / n))
            for i in range(n)
        ]
        for i in range(n):
            j = (i + 1) % n
            self.face([low[i], low[j], high[j], high[i]], c)
        if r2:
            self.face(high, c)
        self.face(low[::-1], c)

    def beam(self, a, b, width, c):
        x, y, z = a
        dx, dy, dz = [b[i] - a[i] for i in range(3)]
        mag = math.sqrt(dx * dx + dy * dy + dz * dz)
        if not mag:
            return
        dx, dy, dz = dx / mag, dy / mag, dz / mag
        ux, uy, uz = (1, 0, 0) if abs(dy) > 0.98 else (0, 1, 0)
        sx, sy, sz = dy * uz - dz * uy, dz * ux - dx * uz, dx * uy - dy * ux
        mag = math.sqrt(sx * sx + sy * sy + sz * sz)
        sx, sy, sz = sx / mag, sy / mag, sz / mag
        ux, uy, uz = sy * dz - sz * dy, sz * dx - sx * dz, sx * dy - sy * dx
        rings = []
        for p in (a, b):
            rings.append(
                [
                    tuple(
                        p[i] + width * 0.5 * (u * (ux, uy, uz)[i] + v * (sx, sy, sz)[i]) for i in range(3)
                    )
                    for u, v in ((1, 1), (1, -1), (-1, -1), (-1, 1))
                ]
            )
        for i in range(4):
            j = (i + 1) % 4
            self.face([rings[0][i], rings[1][i], rings[1][j], rings[0][j]], c)

    def save(self, name, indexed=False, casts=False):
        vertices = [struct.pack("<8f", *v) for v in self.verts]
        if indexed or casts:
            lookup = {v: i for i, v in enumerate(dict.fromkeys(vertices))}
            indices = [lookup[v] for v in vertices]
            vertices = list(lookup)
            if casts:
                # Unreferenced bounds keep an offscreen visitor's projected silhouette in the draw list.
                vertices.extend(struct.pack("<8f", b, b, b, 0, 1, 0, 0, 0) for b in (-12, 12))
        n = len(vertices)
        data = b"".join(vertices)
        doc = {
            "asset": {"version": "2.0"},
            "buffers": [{"byteLength": len(data)}],
            "bufferViews": [{"buffer": 0, "byteOffset": 0, "byteLength": len(data), "byteStride": 32}],
            "accessors": [
                {"bufferView": 0, "byteOffset": offset, "componentType": 5126, "count": n, "type": kind}
                for offset, kind in ((0, "VEC3"), (12, "VEC3"), (24, "VEC2"))
            ],
            "meshes": [{"primitives": [{"attributes": {"POSITION": 0, "NORMAL": 1, "TEXCOORD_0": 2}}]}],
            "nodes": [{"mesh": 0}],
            "scenes": [{"nodes": [0]}],
            "scene": 0,
        }
        if indexed or casts:
            code, component = ("H", 5123) if n <= 65536 else ("I", 5125)
            packed = struct.pack(f"<{len(indices)}{code}", *indices)
            doc["bufferViews"].append({"buffer": 0, "byteOffset": len(data), "byteLength": len(packed)})
            doc["accessors"].append({"bufferView": 1, "componentType": component, "count": len(indices), "type": "SCALAR"})
            doc["meshes"][0]["primitives"][0]["indices"] = 3
            data += packed
            doc["buffers"][0]["byteLength"] = len(data)
            data += bytes(-len(data) % 4)
        desc = json.dumps(doc, separators=(",", ":")).encode()
        desc += b" " * (-len(desc) % 4)
        (OUT / (name + ".glb")).write_bytes(
            struct.pack("<4sII", b"glTF", 2, 28 + len(desc) + len(data))
            + struct.pack("<I4s", len(desc), b"JSON")
            + desc
            + struct.pack("<I4s", len(data), b"BIN\0")
            + data
        )


digits = [
    "111101101101111",
    "010110010010111",
    "111001111100111",
    "111001111001111",
    "101101111001001",
    "111100111001111",
    "111100111101111",
    "111001010010010",
    "111101111101111",
    "111101111001111",
]
hall = Model()
numerals = Model()
b = hall.box
for wing, rotation in enumerate((90, 0, -90, 180)):
    angle = math.radians(rotation)
    cs, sn = round(math.cos(angle)), round(math.sin(angle))
    hall.transform = lambda x, y, z, c=cs, s=sn: (c * x + s * (z - 24), y, -s * x + c * (z - 24))
    numerals.transform = hall.transform
    color = (11, 19, 24, 28)[wing]
    # Open clerestory apertures through the wall, with solid piers between the windows.
    b(0, 4.80, -0.2, 48, 1.0, 0.65, color)
    b(0, 8.43, -0.2, 48, 1.74, 0.65, color)
    edge = -24
    for i in range(6):
        center = (i - 2.5) * 7
        start = center - 1.55
        b((edge + start)/2, 6.43, -.2, start-edge, 2.26, .65, color)
        edge = center + 1.55
    b((edge+24)/2, 6.43, -.2, 24-edge, 2.26, .65, color)
    # Transoms close the portal arches. Low corner windows frame the landscape at eye level.
    b(0, 3.62, -.35, 42.12, 1.46, .24, 6)
    for side in (-1, 1):
        cx = side * 22.53
        b(cx, .52, -.2, 2.96, 1.04, .58, 6)
        b(cx, 4.04, -.2, 2.96, .74, .58, 6)
        for end in (-1, 1):
            b(cx + end * 1.23, 2.35, -.2, .5, 2.65, .58, 6)
            b(cx + end * 1.00, 2.35, .14, .10, 2.72, .24, 8)
        b(cx, 1.02, .21, 2.30, .13, .43, 9)
        b(cx, 1.10, -.28, 2.10, .08, .31, 27)
        b(cx, 3.64, .16, 2.13, .13, .24, 8)
        b(cx, 2.34, .12, .055, 2.55, .15, 8)
        b(cx, 2.49, .12, 2.01, .066, .14, 8)
    b(0, 8.9, 0.14, 48, 0.3, 0.65, 14)
    b(0, 4.8, 0.15, 48, 0.25, 0.55, 8)
    for i in range(6):
        x = (i - 2.5) * 7
        d = wing * 6 + i + 1
        for side in (-1, 1):
            b(x + side * 2.49, 2.2, 0, 2.1, 4.4, 0.6, 6)
            b(x + side * 2.66, 1.25, 0.32, 1.15, 1.65, 0.15, color)
            b(x + side * 1.52, 1.55, 0.36, 0.44, 3.1, 0.55, 8)
            b(x + side * 1.52, 0.25, 0.38, 0.7, 0.5, 0.73, 14)
        # Faceted arched lintel and a brass keystone.
        for j in range(8):
            t1 = math.pi * j / 8
            t2 = math.pi * (j + 1) / 8
            hall.beam(
                (x + 1.51 * math.cos(t1), 2.8 + 1.5 * math.sin(t1), 0.42),
                (x + 1.51 * math.cos(t2), 2.8 + 1.5 * math.sin(t2), 0.42),
                0.40,
                8 if j % 2 else 9,
            )
        b(x, 4.32, 0.49, 0.48, 0.5, 0.55, 15)
        b(x, 3.28, 0.22, 1.37, 0.81, 0.17, 10)
        for g, ch in enumerate(f"{d:02}"):
            for k, on in enumerate(digits[int(ch)]):
                if on == "1":
                    numerals.box(
                        x + (g * 4 + k % 3 - 3) * 0.143,
                        3.55 - (k // 3) * 0.133,
                        0.325,
                        0.134,
                        0.124,
                        0.06,
                        16,
                    )
        # Snowy clerestory, mullions and garlands.
        for side in (-1, 1):
            b(x+side*1.52,6.43,.19,.12,2.32,.28,8)
            b(x,6.43+side*1.09,.19,3.14,.12,.28,8)
        b(x,5.26,.27,3.35,.13,.43,9)
        b(x,5.37,-.23,3.08,.07,.32,27)
        b(x,6.43,.20,.085,2.10,.13,14)
        b(x,6.4,.20,3.02,.078,.13,14)
        for j in range(9):
            xx = x + (j - 4) * 0.77
            yy = 5.08 + 0.68 * ((j - 4) / 4) ** 2
            hall.cone(xx, yy - 0.22, 0.57, 0.41, 0.27, 0.44, 18 + j % 3, 6)
            if j % 2:
                b(xx, yy - 0.27, 0.87, 0.18, 0.20, 0.18, (12, 16)[j % 3 == 0])
    for x in (-23.67, 23.67):
        b(x, 3.4, 0.3, 0.75, 6.8, 0.85, 7)
hall.transform = None
# Tall timber roof with trusses and hanging lanterns.
for side in (-1, 1):
    for strip in range(24):
        inner = side * strip
        outer = side * (strip + 1)
        a = 14.1 - strip * 0.223
        btm = a - 0.223
        quad = [(inner, a, -24), (outer, btm, -24), (outer, btm, 24), (inner, a, 24)]
        hall.face(quad if side == 1 else quad[::-1], 6 if strip % 4 else 7)
    for z in (-24, 24):
        tri = [(0, 8.85, z), (side * 24, 8.85, z), (0, 14.1, z)]
        hall.face(tri, 6)
        hall.face(tri[::-1], 6)
for z in (-20, -12, -4, 4, 12, 20):
    for sign in (-1, 1):
        hall.beam((sign * 24, 8.2, z), (0, 13.8, z), 0.52, 7)
        hall.beam((sign * 17, 8.2, z), (sign * 10, 11.4, z), 0.33, 8)
    b(0, 8.3, z, 47.8, 0.32, 0.40, 6)
for x in (-18, -10, 0, 10, 18):
    b(x, 13.6 - abs(x) * 0.23, 0, 0.4, 0.35, 48, 7)
# Wrapped presents beneath the spruce.
for k in range(13):
    a = k * 2.4
    x, z = 2.45 * math.cos(a), 2.45 * math.sin(a)
    size = 0.43 + (k % 3) * 0.15
    b(x, size / 2, z, size, size, size, (11, 19, 24, 28)[k % 4])
    b(x, size / 2, z, size * 0.20, size + 0.04, size + 0.04, 15)
# Workshop train, frosted conservatory and clock gallery.
for i in range(4):
    b(-7 + i * 1.4, 4.95, -22.8, 1.24, 0.60, 0.72, (12, 15, 20, 24)[i])
    for j in (-1, 1):
        b(-7 + i * 1.4 + j * 0.38, 4.62, -22.4, 0.3, 0.28, 0.13, 0)
for i in range(7):
    hall.cone(22.4, 0, (i - 3) * 1.05, 0.5, 0, 1.4 + (i % 3) * 0.38, 26, 5)
hall.transform = lambda x, y, z: (-x, y, 23.3 - z)
hall.cone(0, 5.8, 0, 1, 1, 0.10, 15)
for i in range(12):
    a = i * math.pi / 6
    b(math.sin(a) * 0.9, 6.2 + math.cos(a) * 0.9, 0.16, 0.12, 0.20, 0.1, 16)
hall.beam((0, 6.2, 0.22), (0.52, 6.6, 0.22), 0.10, 5)
hall.beam((0, 6.2, 0.22), (-0.15, 6.91, 0.22), 0.08, 5)
hall.transform = None
for x, y, z in ((-5, 1.8, -14), (-2.6, 2.45, -16), (0, 1.85, -15), (2.6, 2.45, -16), (5, 1.8, -14)):
    b(x, 0.58, z, 0.19, 1.16, 0.19, 8)
    b(x, 0.09, z, 0.92, 0.16, 0.7, 7)
hall.save("great-hall", indexed=True)
numerals.save("door-numerals", indexed=True)
build_holiday_art(OUT, Model, png, hall)

for kind in ("snowman", "gingerbread", "penguin", "guard", "wisp", "friend"):
    m = Model()
    b = m.box
    def part(name, start, end, width, color, stripe=False):
        limb = Model()
        limb.beam((0, 0, 0), tuple(end[i] - start[i] for i in range(3)), width, color)
        if stripe:
            limb.box(*(0.76 * (end[i]-start[i]) for i in range(3)), width*1.06, 0.055, width*1.06, 5)
        limb.save(f"{kind}-{name}", casts=True)
    if kind == "snowman":
        m.cone(0, -0.92, 0, 0.52, 0.44, 0.75, 27)
        m.cone(0, -0.2, 0, 0.40, 0.34, 0.54, 31)
        m.cone(0, 0.32, 0, 0.35, 0.28, 0.46, 31)
        b(0, 0.82, 0, 0.78, 0.12, 0.65, 0)
        b(0, 1.01, 0, 0.57, 0.34, 0.50, 1)
        b(0, 0.25, 0, 0.78, 0.15, 0.69, 12)
        part("scarf", (0,0,0), (0.07,-0.47,0.03), 0.16, 12, True)
        for side, tag in ((-1,"left"),(1,"right")):
            part(tag, (0,0,0), (side*0.40,0.23,0.04), 0.085, 7)
        b(0, 0.51, 0.37, 0.14, 0.14, 0.32, 15)
    elif kind == "gingerbread":
        b(0, 0.0, 0, 0.62, 0.83, 0.28, 8)
        b(0, 0.59, 0, 0.62, 0.52, 0.29, 9)
        b(0, 0.33, 0.16, 0.61, 0.06, 0.04, 5)
        for s in (-1, 1):
            tag = "left" if s < 0 else "right"
            part(tag+"-leg",(0,0,0),(s*0.16,-0.57,0),0.24,8,True)
            part(tag+"-arm",(0,0,0),(s*0.35,0.18,0),0.23,9,True)
        for y in (0, 0.16):
            b(0, y, 0.17, 0.1, 0.1, 0.05, 12)
    elif kind == "penguin":
        m.cone(0, -0.78, 0, 0.41, 0.31, 1.2, 0)
        m.cone(0, 0.39, 0, 0.35, 0.27, 0.40, 0)
        b(0, -0.14, 0.28, 0.48, 0.78, 0.16, 5)
        b(0, 0.41, 0.38, 0.27, 0.12, 0.22, 15)
        for s in (-1, 1):
            tag = "left" if s < 0 else "right"
            skate = Model()
            skate.box(0,0,0.13,0.38,0.16,0.65,15)
            skate.box(0,-0.10,0.13,0.06,0.08,0.67,4)
            skate.save("penguin-"+tag+"-leg", casts=True)
            part(tag+"-arm",(0,0,0),(s*0.28,-0.55,0),0.20,1)
    elif kind in ("guard", "friend"):
        for s in (-1, 1):
            if kind == "friend":
                b(s * 0.18, -0.62, 0, 0.24, 0.62, 0.29, 1)
                b(s * 0.36, -0.02, 0, 0.19, 0.60, 0.24, 12)
            else:
                tag = "left" if s < 0 else "right"
                leg = Model()
                leg.box(0,-0.31,0,0.24,0.62,0.29,1)
                leg.box(0,-0.58,0.065,0.28,0.16,0.38,0)
                leg.save("guard-"+tag+"-leg", casts=True)
                arm = Model()
                arm.box(0,-0.30,0,0.19,0.60,0.24,12)
                arm.box(0,-0.47,0,0.20,0.08,0.25,15)
                arm.save("guard-"+tag+"-arm", casts=True)
        b(0, 0.01, 0, 0.55, 0.74, 0.37, 11 if kind == "guard" else 20)
        b(0, 0.45, 0, 0.43, 0.4, 0.39, 9)
        b(0, 0.85, 0, 0.54, 0.45, 0.50, 1 if kind == "guard" else 20)
        b(0, 0.67, 0.03, 0.59, 0.10, 0.55, 15)
        for j in range(3):
            b(0, j * 0.14, 0.21, 0.10, 0.08, 0.06, 16)
    else:
        m.cone(0, -0.58, 0, 0.04, 0.46, 0.55, 25, 6)
        m.cone(0, -0.03, 0, 0.46, 0.20, 0.59, 26, 6)
        m.cone(0, 0.56, 0, 0.20, 0, 0.4, 27, 6)
        for s in (-1, 1):
            part("left" if s < 0 else "right",(0,0,0),(s*0.43,0.38,0),0.14,27)
    for s in (-1, 1):
        b(
            s * 0.13,
            0.54 if kind != "wisp" else 0.22,
            0.32 if kind != "wisp" else 0.38,
            0.09,
            0.09,
            0.075,
            0 if kind != "penguin" else 31,
        )
    m.save(kind, casts=True)

for i, name in enumerate(("pistol", "fan", "spinner", "bank", "rocket")):
    m = Model()
    col = (12, 20, 25, 28, 11)[i]
    m.box(0, -0.11, 0.06, 0.12, 0.21, 0.14, 7)
    m.box(0, 0, -0.03, 0.22, 0.18, 0.39, col)
    count = (1, 3, 3, 1, 1)[i]
    for j in range(count):
        x = (j - (count - 1) / 2) * 0.105
        width = 0.105 if count > 1 else (0.29 if i == 4 else 0.15)
        m.box(x, 0.025, -0.30, width, 0.14 + i * 0.014, 0.41, col)
        m.box(x, 0.025, -0.46, width + 0.034, 0.18 + i * 0.014, 0.095, 15)
        m.box(x, 0.025, -0.514, width * 0.61, 0.09, 0.025, 0)
    m.box(0, 0.109, -0.02, 0.095, 0.040, 0.2, 16)
    m.box(0, 0.104, 0.10, 0.20, 0.036, 0.065, 14)
    m.box(0, 0.138, -0.39, 0.034, 0.052, 0.045, 17)
    m.box(0, -0.13, 0.12, 0.15, 0.12, 0.17, 19)
    for n in range(3):
        m.box(0, -0.10 + n * 0.036, 0.155, 0.17, 0.024, 0.10, 20)
    m.save(name)
bell = Model()
bell.cone(0, -0.36, 0, 0.54, 0.27, 0.50, 15)
bell.cone(0, 0.14, 0, 0.27, 0.13, 0.22, 16)
bell.cone(0, -0.48, 0, 0.1, 0.12, 0.15, 9)
bell.save("bell")
orb = Model()
orb.cone(0, -0.13, 0, 0.05, 0.15, 0.11, 26, 8)
orb.cone(0, -0.02, 0, 0.15, 0.06, 0.16, 31, 8)
orb.save("snowball")

splat = Model()
splat.cone(0, -0.012, 0, 0.50, 0.46, 0.025, 27, 8)
splat.cone(0.16, 0, -0.32, 0.24, 0.22, 0.018, 31, 6)
splat.save("snow-print")

for name, freq in (("throw", 480), ("bell", 784), ("poof", 185)):
    with wave.open(str(OUT / (name + ".wav")), "wb") as f:
        f.setparams((1, 2, 22050, 0, "NONE", "not compressed"))
        frames = []
        for i in range(11025):
            t = i / 22050
            s = math.sin(2 * math.pi * (freq * t + (0 if name == "bell" else -freq * 0.7 * t * t)))
            overtone = math.sin(2 * math.pi * freq * 2.7 * t)
            frames.append(
                struct.pack(
                    "<h", int(11500 * (s + 0.25 * overtone) * math.exp(-t * (8 if name == "bell" else 21)))
                )
            )
        f.writeframes(b"".join(frames))

from make_feedback_art import generate

generate(OUT, png)
