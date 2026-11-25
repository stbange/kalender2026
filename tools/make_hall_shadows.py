"""Bake the two practical lights' floor occlusion from the same triangles used in the hall."""

import math
from PIL import Image, ImageDraw, ImageFilter

EXTENT = 24
SIZE = 768


def below_light(vertices, ceiling):
    """Clip a triangle crossing the point light's height before perspective projection."""
    result = []
    previous = vertices[-1]
    for end in vertices:
        if (end[1] < ceiling) != (previous[1] < ceiling):
            t = (ceiling - previous[1]) / (end[1] - previous[1])
            result.append(tuple(previous[i] + t * (end[i] - previous[i]) for i in range(3)))
        if end[1] < ceiling:
            result.append(end)
        previous = end
    return result


def occlusion(models, lamp):
    _, (lx, ly, lz), _, reach = lamp
    mask = Image.new("L", (SIZE, SIZE))
    draw = ImageDraw.Draw(mask)
    scale = SIZE / (2 * EXTENT)
    for model in models:
        for i in range(0, len(model.verts), 3):
            tri = model.verts[i : i + 3]
            if max(p[1] for p in tri) <= 0.045 or min(p[1] for p in tri) >= ly - 0.045:
                continue
            # Reject only triangles wholly outside the square containing the light's falloff.
            if any(
                min(p[d] for p in tri) >= center + reach or max(p[d] for p in tri) <= center - reach
                for d, center in ((0, lx), (2, lz))
            ):
                continue
            projected = []
            for x, y, z, *_ in below_light(tri, ly - 0.045):
                k = ly / (ly - max(0, y))
                projected.append(
                    ((lx + (x - lx) * k + EXTENT) * scale, (lz + (z - lz) * k + EXTENT) * scale)
                )
            if len(projected) >= 3:
                draw.polygon(projected, fill=255)
    # Keep a contact core with a small soft edge from the extent of the flame or candle cluster.
    return mask.filter(ImageFilter.GaussianBlur(1.9 if ly < 2 else 2.8))


def floor_pixel(i, j):
    x, z = (i + 0.5) * 48 / SIZE - EXTENT, (j + 0.5) * 48 / SIZE - EXTENT
    ax, az = abs(x), abs(z)
    # An uninterrupted red runner crosses over the longer north-south runner.
    if ax < 2.78 or az < 2.23:
        d, s, half = (az, x, 2.23) if az < 2.23 else (ax, z, 2.78)
        weave = (i % 3 == 0) * 4 - (j % 4 == 0) * 3
        edge = half - d
        diamond = abs((s + 0.30) % 0.60 - 0.30) + abs(edge - 0.39)
        if 0.09 < edge < 0.16 or 0.26 < diamond < 0.34 and 0.18 < edge < 0.60:
            return (142 + weave, 97 + weave, 51 + weave)
        if edge < 0.075 or 0.57 < edge < 0.64:
            return (58 + weave, 30 + weave, 38 + weave)
        medallion = d + abs((s + 1.10) % 2.20 - 1.10)
        if 0.11 < medallion < 0.20:
            return (150 + weave, 92 + weave, 49 + weave)
        return (107 + weave, 37 + weave, 45 + weave)
    tile = SIZE // 16
    tx, tz = i // tile, j // tile
    u, v = i % tile, j % tile
    base = (60, 72, 83) if (tx + tz) % 2 else (76, 86, 91)
    tone = ((tx * 13 + tz * 19) % 9 - 4) + round(1.7 * math.sin(u * 0.21 + v * 0.09 + tx))
    if min(u, v, tile - u - 1, tile - v - 1) == 0:
        tone -= 11
    return tuple(c + tone for c in base)


def build_floor(out, model_type, casters, lamps):
    fire, candles = (occlusion(casters, light).tobytes() for light in lamps)
    linear = [round(255 * (v / 255) ** 1.85) for v in range(256)]
    data = bytearray()
    for j in range(SIZE):
        for i in range(SIZE):
            k = j * SIZE + i
            mask = round(fire[k] / 17) + 16 * round(candles[k] / 17)
            data.extend((*[linear[c] for c in floor_pixel(i, j)], mask))
    Image.frombytes("RGBA", (SIZE, SIZE), bytes(data)).save(out / "hall-floor.png", optimize=True)
    floor = model_type()
    floor.face(
        [(-EXTENT, 0, -EXTENT), (-EXTENT, 0, EXTENT), (EXTENT, 0, EXTENT), (EXTENT, 0, -EXTENT)],
        0,
        [(0, 0), (0, 1), (1, 1), (1, 0)],
    )
    floor.save("hall-floor")
