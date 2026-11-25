"""Palette-indexed geometry for the loose game assets."""

import json
import math
import struct
from pathlib import Path


class Model:
    root = Path(".")

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
                    tuple(p[i] + width * 0.5 * (u * (ux, uy, uz)[i] + v * (sx, sy, sz)[i]) for i in range(3))
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
            doc["accessors"].append(
                {"bufferView": 1, "componentType": component, "count": len(indices), "type": "SCALAR"}
            )
            doc["meshes"][0]["primitives"][0]["indices"] = 3
            data += packed
            doc["buffers"][0]["byteLength"] = len(data)
            data += bytes(-len(data) % 4)
        desc = json.dumps(doc, separators=(",", ":")).encode()
        desc += b" " * (-len(desc) % 4)
        (self.root / (name + ".glb")).write_bytes(
            struct.pack("<4sII", b"glTF", 2, 28 + len(desc) + len(data))
            + struct.pack("<I4s", len(desc), b"JSON")
            + desc
            + struct.pack("<I4s", len(data), b"BIN\0")
            + data
        )
