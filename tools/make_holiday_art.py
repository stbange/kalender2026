"""Original Christmas fittings, Norway spruce and log-fire art for the loose hall assets."""

import math
import random
from PIL import Image, ImageDraw
from make_hall_shadows import build_floor

TAU = 2 * math.pi
GLASS = ("amber", "ruby", "green", "blue", "rose")

# The first two entries own the two floor visibility channels and the moving silhouettes.
LIGHTS = [
    ("hearth", (-22.83, 1.04, 0.02), (4.6, 2.19, 0.87), 11),
    ("entrance candles", (0, 6.87, 10), (3.05, 2.04, 1.24), 19.5),
    ("range candles", (0, 6.87, -13), (3.05, 2.04, 1.24), 19.5),
    ("spruce", (1.31, 2.65, 2.34), (1.35, 0.59, 1.14), 7.8),
    *(("festoon", (x, 5.74, z), (2.08, 1.23, 0.71), 17.8) for x in (-15.6, 15.6) for z in (-14, 14)),
]


def ring(model, x, z, profile, color, sides=8):
    """Turn a list of (height, radius) pairs into a closed faceted surface."""
    for (yb, rb), (yt, rt) in zip(profile, profile[1:]):
        for i in range(sides):
            a, b = TAU * i / sides, TAU * (i + 1) / sides

            def point(r, y, theta):
                return x + r * math.sin(theta), y, z + r * math.cos(theta)

            pts = [point(rb, yb, a), point(rb, yb, b), point(rt, yt, b), point(rt, yt, a)]
            if rb == 0:
                pts.pop(1)
            if rt == 0:
                pts.pop(2)
            model.face(pts, color)


def bauble(model, x, y, z, radius, color):
    ring(
        model,
        x,
        z,
        [
            (y - radius, 0),
            (y - 0.7 * radius, 0.71 * radius),
            (y, 0.99 * radius),
            (y + 0.7 * radius, 0.71 * radius),
            (y + radius, 0),
        ],
        color,
        9,
    )


def needle_texture(out):
    size = 128
    image = Image.new("RGBA", (size, size))
    pen = ImageDraw.Draw(image)
    rng = random.Random(734)

    def twig(start, end, width, needles):
        x, y = start
        dx, dy = end[0] - x, end[1] - y
        dist = math.hypot(dx, dy)
        ux, uy = dx / dist, dy / dist
        pen.line((start, end), fill=(51, 64, 29, 255), width=max(1, int(width * 0.23)))
        for i in range(needles):
            t = (i + 0.4) / needles
            px, py = x + t * dx, y + t * dy
            for side in (-1, 1):
                n = (1 - 0.68 * t) * width * rng.uniform(0.68, 1.18)
                tip = px + ux * n * 1.2 - uy * side * n, py + uy * n * 1.2 + ux * side * n
                g = rng.randrange(46, 104) + int(25 * t)
                pen.line(((px, py), tip), fill=(int(g * 0.31), g, int(g * 0.55), 255), width=2)
                if i % 3 == 0:
                    pen.point(tip, fill=(int(g * 0.64), g + 23, int(g * 0.65), 255))

    for i in range(12):
        y = 115 - i * 8.1
        span = 49 * (1 - i / 14) ** 0.72
        for side in (-1, 1):
            twig((64, y), (64 + side * span, y - 19 + i * 0.6 + rng.uniform(-3, 3)), 8 - i * 0.36, 20)
    twig((64, 124), (64, 8), 6.2, 51)
    image.save(out / "spruce-spray.png", optimize=True)


def flame_textures(out, png):
    width, height = 100, 84
    for frame in range(16):
        phase = TAU * frame / 16
        rgba = bytearray()
        for row in range(height):
            y = (height - row - 0.5) / height
            for col in range(width):
                x = (col + 0.5) / width * 2 - 1
                heat = 0.0
                for j, (base, span, high) in enumerate(
                    (
                        (-0.65, 0.22, 0.59),
                        (-0.36, 0.26, 0.84),
                        (-0.04, 0.23, 0.70),
                        (0.23, 0.24, 0.86),
                        (0.57, 0.21, 0.60),
                    )
                ):
                    a = phase + j * 2.31
                    h = high + 0.095 * math.sin(a) + 0.048 * math.cos(2 * a + 0.8)
                    v = y / h
                    if v >= 1:
                        continue
                    middle = base + v * (0.10 * math.sin(6 * v - a) + 0.13 * math.sin(10 * v - 2 * a + j))
                    radius = span * (1 - v) ** 0.73 * (1 + 0.19 * math.sin(13 * v - 2 * a))
                    shape = 1 - ((x - middle) / max(0.009, radius)) ** 2
                    heat = max(heat, max(0, shape) * (1 - 0.67 * v))
                heat = max(heat, 0.91 * max(0, 1 - (x / 0.86) ** 6) * max(0, 1 - (y / 0.24) ** 2))
                if heat <= 0.012:
                    rgba.extend((0, 0, 0, 0))
                    continue
                red = min(255, int(120 + heat * 290))
                green = min(248, int(10 + heat**1.3 * 255))
                blue = min(188, int(2 + heat**3.1 * 220))
                rgba.extend((red, green, blue, min(255, round(heat * 650))))
        png(out / f"hearth-fire-{frame + 1:02}.png", width, height, rgba)
    pixels = bytearray()
    for y in range(32):
        for x in range(32):
            r = math.hypot((x - 15.5) / 15.5, (y - 15.5) / 15.5)
            pixels.extend((255, 244, 210, round(255 * max(0, 1 - r) ** 3)))
    png(out / "lamp-halo.png", 32, 32, pixels)


def spray(model, a, b, width):
    """A folded needle spray has a readable silhouette even from below."""
    dx, dz = b[0] - a[0], b[2] - a[2]
    length = math.hypot(dx, dz) or 1
    sx, sz = dz / length, -dx / length
    rows = []
    for t, extent in ((0, 0.34), (0.48, 1), (1, 0.55)):
        x, y, z = (a[k] + (b[k] - a[k]) * t for k in range(3))
        rows.append(
            [
                (x + sx * w * width, y + (1 - abs(w)) * 0.19 * width, z + sz * w * width)
                for w in (-extent, 0, extent)
            ]
        )
    for j in (0, 1):
        for k in (0, 1):
            p = [rows[j][k], rows[j + 1][k], rows[j + 1][k + 1], rows[j][k + 1]]
            # glTF's texture origin is the upper left; the tip samples the top.
            uv = [
                (k * 0.5, 1 - j * 0.5),
                (k * 0.5, 0.5 - j * 0.5),
                ((k + 1) * 0.5, 0.5 - j * 0.5),
                ((k + 1) * 0.5, 1 - j * 0.5),
            ]
            model.face(p, 0, uv)
            model.face(p[::-1], 0, uv[::-1])


def bulb(fittings, glass, x, y, z, radius, shade, hanging=True):
    sign = -1 if hanging else 1
    fittings.cone(x, y - radius * 0.20, z, radius * 0.47, radius * 0.51, radius * 0.40, 18, 6)
    middle = y + sign * radius
    ring(
        glass[shade],
        x,
        z,
        [
            (middle - radius * 0.94, 0),
            (middle - radius * 0.52, radius * 0.68),
            (middle, radius * 0.8),
            (middle + radius * 0.65, radius * 0.49),
            (middle + radius * 0.94, 0),
        ],
        16,
        7,
    )
    return x, middle, z


def candle(fittings, glass, x, y, z, h):
    brass = 14
    fittings.cone(x, y, z, 0.145, 0.105, 0.095, brass, 10)
    fittings.cone(x, y + 0.09, z, 0.08, 0.078, h, 5, 9)
    fittings.cone(x, y + h + 0.09, z, 0.08, 0.056, 0.025, 9, 9)
    wick = y + h + 0.137
    fittings.box(x, wick - 0.015, z, 0.023, 0.07, 0.023, 0)
    ring(
        glass["flame"],
        x,
        z,
        [(wick, 0), (wick + 0.035, 0.042), (wick + 0.090, 0.036), (wick + 0.19, 0)],
        17,
        7,
    )


def spruce(fittings, needles, ornaments, glass, halos):
    rng = random.Random(241226)
    fittings.cone(0, 0.03, 0, 2.28, 2.20, 0.23, 7, 18)
    fittings.cone(0, 0.30, 0, 0.42, 0.065, 6.7, 7, 10)
    for tier in range(13):
        y = 1.02 + tier * 0.462
        radius = 3.00 * (1 - tier / 13.5) ** 0.84
        count = 14 - tier // 3
        for j in range(count):
            angle = TAU * (j + 0.32 * rng.random()) / count + tier * 2.42
            r = radius * rng.uniform(0.89, 1.07)

            def branch(distance, height, side=0):
                return (
                    math.sin(angle) * distance + math.cos(angle) * side,
                    height,
                    math.cos(angle) * distance - math.sin(angle) * side,
                )

            # Inside each whorl, two ridged faces give the branch volume under the fine needles.
            yj = y + rng.uniform(-0.14, 0.13)
            root = branch(0.10 * r, yj + 0.68)
            left = branch(0.48 * r, yj - 0.03, 0.23 * r)
            right = branch(0.48 * r, yj - 0.04, -0.21 * r)
            spine = branch(0.47 * r, yj + 0.34)
            tip = branch(0.82 * r, yj - 0.22)
            for tri, c in (
                ([root, spine, left], 18),
                ([root, right, spine], 18),
                ([spine, tip, left], 19),
                ([spine, right, tip], 18),
            ):
                fittings.face(tri, c)
                fittings.face(tri[::-1], 18)
            for step in range(4):
                dist = 0.23 + 0.158 * step
                side_span = r * (0.32 - step * 0.04)
                for side in (-1, 1):
                    a = branch(r * dist, yj + 0.63 - 0.42 * dist)
                    b = branch(
                        r * (dist + 0.32),
                        yj - 0.29 - 0.08 * step + rng.uniform(-0.16, 0.11),
                        side * side_span,
                    )
                    spray(needles, a, b, r * (0.16 + 0.012 * step))
            for side in (-1, 1):
                spray(
                    needles,
                    branch(r * 0.71, yj + 0.18),
                    branch(r * 1.04, yj - 0.45, side * 0.12 * r),
                    r * 0.14,
                )
            spray(needles, branch(r * 0.77, yj + 0.14), branch(r * 1.10, yj - 0.27), r * 0.15)
            if tier < 10 and (j + 2 * tier) % 5 == 0:
                x, by, z = branch(r * 0.98, y - 0.16)
                rad = 0.13 + rng.random() * 0.073
                fittings.cone(x, by - 0.01, z, rad * 0.24, rad * 0.24, 0.09, 15, 6)
                bauble(ornaments, x, by - rad, z, rad, (12, 15, 28, 24, 11)[(j + tier) % 5])
    previous = None
    for i in range(118):
        f = i / 117
        y = 1.00 + 5.77 * f
        angle = f * TAU * 6.7 + 0.4
        r = 3.03 * (1 - f) ** 0.86 + 0.09 + (0.09 * math.sin(angle * 3))
        x, z = r * math.sin(angle), r * math.cos(angle)
        position = (x, y + 0.05, z)
        if previous:
            fittings.beam(previous, position, 0.034, 18)
        previous = position
        if i % 2 == 0 or i < 26:
            shade = GLASS[(i * 3 + i // 7) % len(GLASS)]
            pos = bulb(fittings, glass, x, y, z, 0.093 if f < 0.75 else 0.072, shade)
            if i % 4 == 0:
                halos.append((shade, *pos, 0.58 if f < 0.75 else 0.42))
    # Two back-to-back faceted star faces and a narrow brass stem.
    fittings.cone(0, 6.68, 0, 0.095, 0.055, 0.55, 15, 8)
    for side in (-1, 1):
        points = []
        for i in range(10):
            angle = math.pi / 2 + i * math.pi / 5
            r = 0.62 if i % 2 == 0 else 0.266
            points.append((r * math.cos(angle), 7.45 + r * math.sin(angle), side * 0.035))
        for i in range(10):
            p = [(0, 7.45, side * 0.22), points[i], points[(i + 1) % 10]]
            glass["star"].face(p if side > 0 else p[::-1], 16 if i % 2 == 0 else 15)


def masonry_texture(out, png):
    rng = random.Random(8041)
    tones = ((120, 57, 43), (155, 72, 49), (111, 60, 50), (143, 82, 60), (99, 60, 49), (87, 61, 53))
    data = bytearray()
    for y in range(64):
        for x in range(192):
            base = tones[x // 64 + 3 * (y // 32)]
            u, v = x % 64, y % 32
            grain = (
                rng.gauss(0, 7)
                + 5 * math.sin(u * 0.14 + math.sin(v * 0.33))
                + 3 * math.sin(v * 0.86 + u * 0.13)
            )
            if min(u, 63 - u, v, 31 - v) < 1 + rng.random() * 1.4:
                grain += 13 if v < 3 or u < 3 else -18
            data.extend([round(255 * (max(0, min(255, c + grain)) / 255) ** 1.85) for c in base] + [255])
    png(out / "hearth-brick.png", 192, 64, data)


def prism(model, points, back, front, color):
    """Extrude a convex outline in the local mantel plane."""
    face = [(u, y, front) for u, y in points]
    model.face(face, color)
    model.face([(u, y, back) for u, y in reversed(points)], color)
    for i, (u, y) in enumerate(points):
        v, h = points[(i + 1) % len(points)]
        model.face([(u, y, back), (v, h, back), (v, h, front), (u, y, front)], color)


def wall_sprig(needles, u, y, d, du, dy, w):
    length = math.hypot(du, dy)
    sx, sy = -dy * w / length, du * w / length
    points = [
        (u - sx, y - sy, d),
        (u + sx, y + sy, d),
        (u + du + sx, y + dy + sy, d + 0.045),
        (u + du - sx, y + dy - sy, d + 0.045),
    ]
    uv = [(0, 1), (1, 1), (1, 0), (0, 0)]
    needles.face(points, 0, uv)
    needles.face(points[::-1], 0, uv[::-1])


def chimney(fittings, bricks, needles, glass):
    rng = random.Random(1664)
    # Local +Z faces the room. The two west doors flank the chimney on either side.
    for m in (fittings, bricks, needles, *glass.values()):
        m.transform = lambda u, y, d: (-23.80 + d, y, -u)
    box = fittings.box
    # Honed slate hearthstone and two courses of projecting bullnose trim.
    for y, w, h, d, c in ((0.09, 4.20, 0.18, 2.34, 2), (0.21, 4.14, 0.10, 2.30, 3)):
        box(0, y, d / 2, w, h, d, c)
    for i in range(5):
        box((i - 2) * 0.806, 0.274, 1.26, 0.79, 0.04, 2.04, 2 if i % 2 else 3)
    box(0, 1.53, 0.14, 3.52, 2.52, 0.33, 10)
    box(0, 3.94, 0.28, 3.32, 3.94, 0.74, 5)
    box(0, 6.64, 0.13, 2.04, 3.1, 0.54, 7)
    # Recessed firebrick at the back, brick reveals and the arched brick face.
    for x in (-1, 1):
        box(x * 1.47, 1.18, 0.75, 0.55, 1.88, 1.18, 7)
    box(0, 2.12, 0.79, 3.38, 0.46, 1.12, 7)

    def brick(u, y, width, height, depth, tile):
        pts = [
            (u - width / 2, y - height / 2, depth),
            (u + width / 2, y - height / 2, depth),
            (u + width / 2, y + height / 2, depth),
            (u - width / 2, y + height / 2, depth),
        ]
        a, b = (tile % 3) / 3, (tile // 3) / 2
        bricks.face(
            pts,
            0,
            [
                (a + 0.005, b + 0.484),
                (a + 0.328, b + 0.484),
                (a + 0.328, b + 0.008),
                (a + 0.005, b + 0.008),
            ],
        )

    for row in range(9):
        y = 0.39 + row * 0.205
        for col in range(10):
            left = -1.72 + (col - 0.5 * (row % 2)) * 0.414
            a, b = max(-1.70, left), min(1.70, left + 0.393)
            if b <= a:
                continue
            brick((a + b) / 2, y, b - a, 0.183, 0.325, rng.choice((3, 4, 5)))
            if abs((a + b) / 2) > 1.29 or row == 8:
                brick((a + b) / 2, y, b - a, 0.181, 1.364, rng.randrange(4))
    for i in range(13):
        a, b = math.pi * i / 13 + 0.009, math.pi * (i + 1) / 13 - 0.009
        points = [
            (r * math.cos(t), 1.45 + (r * 0.50) * math.sin(t))
            for r, t in ((1.21, a), (1.52, a), (1.52, b), (1.21, b))
        ]
        prism(fittings, points, 1.22, 1.39, 8 if i % 3 == 0 else 7)
    # Painted pilasters, carved flutes, dentils and stepped crown moulding.
    for s in (-1, 1):
        u = 1.62 * s
        box(u, 1.28, 1.22, 0.39, 2.07, 0.46, 5)
        for k in (-1, 0, 1):
            box(u + k * 0.10, 1.30, 1.462, 0.030, 1.48, 0.07, 4)
        for y, w, h, d in (
            (0.40, 0.56, 0.24, 0.57),
            (0.57, 0.47, 0.11, 0.53),
            (2.05, 0.49, 0.12, 0.53),
            (2.18, 0.57, 0.15, 0.62),
        ):
            box(u, y, 1.23, w, h, d, 5)
    for y, w, h, d, c in (
        (2.27, 3.78, 0.16, 1.63, 5),
        (2.40, 3.90, 0.13, 1.72, 4),
        (2.52, 4.03, 0.14, 1.82, 5),
        (2.64, 4.18, 0.12, 1.91, 5),
    ):
        box(0, y, d * 0.5, w, h, d, c)
    for i in range(22):
        box((i - 10.5) * 0.171, 2.37, 1.72, 0.082, 0.10, 0.10, 5)
    # Evergreen overmantel panel, raised frame, wreath and a folded velvet bow.
    box(0, 3.93, 0.68, 2.81, 2.31, 0.10, 18)
    for s in (-1, 1):
        box(s * 1.43, 3.93, 0.77, 0.093, 2.40, 0.13, 9)
        box(s * 1.51, 3.93, 0.72, 0.055, 2.53, 0.10, 5)
    for y in (2.75, 5.1):
        box(0, y, 0.77, 2.96, 0.093, 0.13, 9)
    for i in range(76):
        a = TAU * i / 76
        radius = 0.72 + 0.055 * math.sin(i * 2.32)
        u, y = radius * math.cos(a), 4.01 + radius * math.sin(a)
        radial = (math.cos(a), math.sin(a))
        tangent = (-radial[1], radial[0])
        for s in (-1, 1):
            base = (u - 0.11 * tangent[0], y - 0.11 * tangent[1], 0.86)
            tip = (
                u + 0.24 * tangent[0] + s * 0.14 * radial[0],
                y + 0.24 * tangent[1] + s * 0.14 * radial[1],
                0.94,
            )
            for sign in (-1, 1):
                side = (u + sign * 0.10 * radial[0], y + sign * 0.10 * radial[1], 0.97)
                fittings.face([base, side, tip], 19 + (i + sign) % 4)
                fittings.face([tip, side, base], 19 + (i + sign) % 4)
        for s in (-1, 1):
            wall_sprig(
                needles,
                u - 0.13 * tangent[0],
                y - 0.13 * tangent[1],
                1.0,
                0.29 * tangent[0] + s * 0.20 * radial[0],
                0.29 * tangent[1] + s * 0.20 * radial[1],
                0.10,
            )
        if i % 9 == 0:
            bauble(fittings, u, y, 1.04, 0.049, 12)

    def bow(u, y, depth, size):
        for s in (-1, 1):
            p = [(u, y), (u + s * 0.50 * size, y + 0.22 * size), (u + s * 0.53 * size, y - 0.13 * size)]
            prism(fittings, p, depth - 0.06, depth, 12)
            p = [
                (u + s * 0.04 * size, y),
                (u + s * 0.28 * size, y - 0.44 * size),
                (u + s * 0.14 * size, y - 0.39 * size),
            ]
            prism(fittings, p, depth - 0.04, depth + 0.03, 11)
        bauble(fittings, u, y, depth + 0.04, 0.095 * size, 13)

    bow(0, 4.72, 1.08, 0.95)
    # A swag follows the edge of the mantel. Each stocking has a heel, turned toe and knit cuff.
    for i in range(39):
        u = -1.94 + i * 0.102
        y = 2.68 - 0.10 * math.cos(u * 3.5)
        fittings.beam((u - 0.10, y, 1.76), (u + 0.08, y + 0.02, 1.78), 0.062, 18)
        for side in (-1, 1):
            wall_sprig(needles, u, y, 1.91, 0.19 * side, -0.22 + 0.08 * math.sin(i * 2.1), 0.095)
        if i % 5 == 0:
            bauble(fittings, u, y - 0.035, 1.96, 0.046, 12)
    for j, u in enumerate((-1.37, -0.73, 0.75, 1.38)):
        top = 2.53
        c = (11, 20, 12, 11)[j]
        box(u, top + 0.06, 1.77, 0.055, 0.27, 0.08, 15)
        leg = [(u - 0.11, top - 0.42), (u + 0.08, top - 0.45), (u + 0.16, top), (u - 0.09, top)]
        foot = [
            (u - 0.12, top - 0.57),
            (u + 0.16, top - 0.60),
            (u + 0.26, top - 0.55),
            (u + 0.24, top - 0.46),
            (u + 0.09, top - 0.40),
            (u - 0.10, top - 0.36),
        ]
        prism(fittings, leg, 1.72, 1.84, c)
        prism(fittings, foot, 1.72, 1.84, c)
        box(u + 0.025, top - 0.035, 1.80, 0.31, 0.145, 0.18, 5)
        for du, dy in ((0, 0), (-0.033, 0), (0.033, 0), (0, -0.037), (0, 0.037)):
            box(u + 0.018 + du, top - 0.235 + dy, 1.849, 0.027, 0.026, 0.022, 5)
    for u in (-1.55, -1.22, 1.30, 1.62):
        candle(fittings, glass, u, 2.71, 1.61, 0.28 + (abs(u) > 0.15 + 1.25) * 0.21)
    # Cast-iron basket and brass andirons sit in front of glowing coals and split logs.
    for s in (-1, 1):
        for depth in (0.66, 1.29):
            box(s * 0.92, 0.42, depth, 0.095, 0.30, 0.10, 0)
        fittings.beam((s * 0.91, 0.52, 0.62), (s * 0.91, 0.55, 1.46), 0.086, 0)
        fittings.cone(s * 0.93, 0.37, 1.49, 0.074, 0.055, 0.40, 14, 7)
        bauble(fittings, s * 0.93, 0.83, 1.49, 0.098, 15)
    for i in range(7):
        fittings.beam(((i - 3) * 0.27, 0.50, 0.66), ((i - 3) * 0.27, 0.53, 1.38), 0.043, 1)
    for i in range(68):
        u, d = rng.uniform(-1, 1), rng.uniform(0.62, 1.38)
        model = glass["coal"] if i % 3 else fittings
        bauble(
            model,
            u,
            0.37 + rng.random() * 0.06,
            d,
            rng.uniform(0.045, 0.115),
            7 if model is fittings else 12,
        )
    for u, y, d, tilt in ((-0.14, 0.63, 1.24, 0.16), (0.10, 0.59, 0.78, -0.15), (0.14, 0.77, 0.98, -0.20)):
        length = 0.72 + rng.random() * 0.13
        for j in range(9):
            a, b = TAU * j / 9, TAU * (j + 1) / 9

            def bark(side, theta):
                return (
                    u + side * length,
                    y + 0.15 * math.sin(theta) + 0.04 * side,
                    d + 0.15 * math.cos(theta) + side * tilt,
                )

            pts = [bark(-1, a), bark(1, a), bark(1, b), bark(-1, b)]
            fittings.face(pts, (10, 6, 1)[j % 3])
            fittings.face(pts[::-1], 6)
        for s in (-1, 1):
            pts = [bark(s, TAU * j / 9) for j in range(9)]
            fittings.face(pts if s == 1 else pts[::-1], 8)
        for k in range(4):
            x = u - 0.65 + k * 0.30
            glass["coal"].beam((x, y + 0.11, d + 0.12), (x + 0.19, y + 0.09, d + 0.13), 0.025, 13)
    for m in (fittings, bricks, needles, *glass.values()):
        m.transform = None


def hall_fixtures(fittings, glass, halos):
    # Open brass chandeliers let the ceiling and the wicks show through.
    for z in (-13, 10):
        fittings.beam((0, 8.36, z), (0, 7.54, z), 0.075, 14)
        for i in range(12):
            a, b = TAU * i / 12, TAU * (i + 1) / 12
            x, dz = 1.72 * math.cos(a), 1.72 * math.sin(a)
            fittings.beam((x, 6.32, z + dz), (1.72 * math.cos(b), 6.32, z + 1.72 * math.sin(b)), 0.105, 14)
            if i % 3 == 0:
                fittings.beam((0, 7.67, z), (x, 6.35, z + dz), 0.043, 15)
            if i % 3 != 1:
                fittings.cone(x, 6.25, z + dz, 0.10, 0.17, 0.10, 15, 9)
                h = 0.31 if i % 2 else 0.41
                candle(fittings, glass, x, 6.34, z + dz, h)
                halos.append(("flame", x, 6.56 + h, z + dz, 0.58))
    # Two suspended strings, with three shallow swags each and a warm lamp at the low points.
    for z in (-14, 14):
        last = None
        for i in range(61):
            x = -23.4 + i * 0.78
            y = 7.20 - 1.36 * math.sin(math.pi * (i % 20) / 20)
            p = (x, y, z)
            if last:
                fittings.beam(last, p, 0.036, 18)
            last = p
            if i % 2:
                fittings.beam((x, y, z), (x, y - 0.12, z), 0.037, 18)
                shade = ("amber", "amber", "ruby", "amber", "green")[i % 5]
                pos = bulb(fittings, glass, x, y - 0.14, z, 0.105, shade)
                if i % 6 == 3:
                    halos.append((shade, *pos, 0.49))
    # Wire on the existing wall garlands follows each arch and keeps every door visible.
    for wing in range(4):

        def local(u, y, d):
            return ((-24 + d, y, -u), (u, y, -24 + d), (24 - d, y, u), (-u, y, 24 - d))[wing]

        for portal in range(6):
            center = (portal - 2.5) * 7
            previous = None
            for i in range(11):
                u = center + (i - 5) * 0.70
                y = 4.91 + 0.52 * ((i - 5) / 5) ** 2
                p = local(u, y, 0.95)
                if previous:
                    fittings.beam(previous, p, 0.034, 18)
                previous = p
                if i % 2:
                    x, yy, z = local(u, y - 0.045, 1.0)
                    bulb(fittings, glass, x, yy, z, 0.087, "amber" if (i + portal) % 4 else "ruby")
            # Two candle sconces across each gallery flank the traffic lanes.
            if portal in (1, 4):
                u = center - 2.48
                fittings.beam(local(u, 2.37, 0.53), local(u, 2.60, 1.03), 0.09, 14)
                x, y, z = local(u, 2.59, 1.06)
                candle(fittings, glass, x, y, z, 0.36)


def build_holiday_art(out, Model, png, hall):
    fittings, needles, ornaments, bricks = Model(), Model(), Model(), Model()
    glass = {name: Model() for name in (*GLASS, "flame", "coal", "star")}
    halos = []
    spruce(fittings, needles, ornaments, glass, halos)
    chimney(fittings, bricks, needles, glass)
    hall_fixtures(fittings, glass, halos)
    build_floor(out, Model, (hall, fittings, ornaments, bricks), LIGHTS[:2])
    lines = [
        "-- Fixture positions in metres, generated by make_holiday_art.py. Regenerate after moving a caster.",
        "-- The hearth and entrance chandelier also cast shadows.",
        "HallLights = {",
    ]
    for name, pos, color, reach in LIGHTS:
        vec = lambda values: "{ " + ", ".join(str(v) for v in values) + " }"
        lines.append(
            f'    {{ type = "point", name = "{name}", pos = {vec(pos)}, color = {vec(color)}, range = {reach} }},'
        )
    lines.extend(["}", "HallHalos = {"])
    for color, x, y, z, diameter in halos:
        lines.append(f'    {{ "{color}", {x:.3f}, {y:.3f}, {z:.3f}, {diameter:.2f} }},')
    (out.parent / "scripts" / "lamps.lua").write_text("\n".join(lines + ["}", ""]))
    fittings.save("christmas-fittings", indexed=True)
    needles.save("spruce-boughs", indexed=True)
    ornaments.save("glass-ornaments", indexed=True)
    bricks.save("hearth-masonry", indexed=True)
    for name, model in glass.items():
        model.save("lamp-" + name, indexed=True)
    for name, model in winter_horizon(Model):
        model.save(name, indexed=True)
    needle_texture(out)
    masonry_texture(out, png)
    flame_textures(out, png)


def winter_horizon(Model):
    rng = random.Random(1206)
    ridges, snow, pines = Model(), Model(), Model()
    # A distant range and a closer tree line shift independently behind the window frames.
    ridgeline = []
    for i in range(152):
        a = TAU * i / 152
        height = (
            14
            + 16 * (0.5 + 0.5 * math.sin(11 * a + 0.8 * math.sin(7 * a))) ** 2
            + 3.5 * math.sin(5 * a)
            + rng.uniform(-0.95, 0.95)
        )
        r = 117 + 3 * math.sin(4 * a)
        ridgeline.append((r * math.cos(a), height, r * math.sin(a)))

    def both(m, face):
        m.face(face, 0)
        m.face(face[::-1], 0)

    for i, p in enumerate(ridgeline):
        q = ridgeline[(i + 1) % len(ridgeline)]
        both(ridges, [(p[0], -8, p[2]), (q[0], -8, q[2]), q, p])
        if p[1] > 13 or q[1] > 13:
            h = 1.4 + max(0, (p[1] + q[1]) * 0.5 - 14) * 0.32
            both(
                snow,
                [
                    p,
                    q,
                    (q[0] * 0.986, q[1] - h * 0.5, q[2] * 0.986),
                    (p[0] * 0.981, p[1] - h, p[2] * 0.981),
                ],
            )
    # Moonlit snow banks between the hall and the pines give the low windows a foreground.
    banks = []
    for i in range(95):
        a = TAU * i / 95
        height = 0.8 + 0.68 * math.sin(5 * a + 0.4) + 0.62 * math.sin(11 * a)
        radius = 44 + 3 * math.sin(7 * a)
        banks.append(
            [(math.cos(a) * r, y, math.sin(a) * r) for r, y in ((31, -1.6), (radius, height), (74, -0.35))]
        )
    for i, p in enumerate(banks):
        q = banks[(i + 1) % len(banks)]
        for k in (0, 1):
            both(snow, [p[k], q[k], q[k + 1], p[k + 1]])
    for count, forest, distances, heights in (
        (164, ridges, (78, 97), (6, 14)),
        (230, pines, (55, 72), (6.4, 12.9)),
    ):
        for i in range(count):
            a = TAU * (i + rng.uniform(-0.38, 0.38)) / count
            r = rng.uniform(*distances)
            x, z = math.cos(a) * r, math.sin(a) * r
            h = rng.uniform(*heights) + 2.0 * math.sin(5 * a)
            # Distinct stepped whorls read as firs even when their silhouettes occupy a few pixels.
            forest.cone(x, 0, z, h * 0.032, h * 0.023, h * 0.28, 18, 5)
            for low, high, width in (
                (0.12, 0.61, 0.21),
                (0.31, 0.76, 0.18),
                (0.50, 0.88, 0.137),
                (0.67, 1, 0.098),
            ):
                forest.cone(x, h * low, z, h * width, 0, h * (high - low), 18, 6)
    return (("winter-ridges", ridges), ("winter-snow", snow), ("winter-pines", pines))
