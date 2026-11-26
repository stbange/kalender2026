"""Original modular roadside sets for the three World Tour maps."""

from math import cos, sin, pi
from voxel_model import Model


def tour_art(save, sign):
    m = Model()
    m.box(0, 0.47, 0, 1.65, 0.94, 0.75, 2)
    sign(m, "WORLD TOUR", 0, 1.48, 0, 2.45, 23, 17)
    sign(m, "USE TO DEPART", 0, 0.86, 0.43, 1.60, 10, 16)
    save(m, "tour-kiosk")
    m = Model()
    m.box(0, 0.65, 0, 0.14, 1.3, 0.15, 9)
    sign(m, "RETURN TO HALL", 0, 1.48, 0, 2.6, 20, 5)
    save(m, "tour-return")
    m = Model()
    m.box(0, 2.4, 0, 6.8, 4.8, 4, 21)
    for xx in (-3.15, -2.75, 2.75, 3.15):
        m.box(xx, 2.6, 2.03, 0.17, 5.2, 0.17, 16)
    for y in (3.65, 3.9):
        m.box(0, y, 2.3, 7.5, 0.13, 0.8, 12)
    sign(m, "SUNSET", 0, 4.95, 2, 5.9, 10, 17)
    for xx in (-1.9, 0, 1.9):
        m.box(xx, 1.35, 2.05, 1.55, 2.6, 0.13, 1)
        m.box(xx, 1.47, 2.14, 1.16, 1.6, 0.09, 24)
    for xx in (-5, 5):
        m.beam((xx, 0, 0), (xx + 0.45, 5.5, 0), 0.40, 9)
        for j in range(8):
            a = j * pi / 4
            peak = (xx + 0.45 + 1.1 * cos(a), 6.2, 1.1 * sin(a))
            m.beam((xx + 0.45, 5.5, 0), peak, 0.45, 22)
            m.beam(peak, (xx + 0.45 + 2.2 * cos(a), 5.25, 2.2 * sin(a)), 0.32, 21)
    save(m, "tour-sunset")
    m = Model()
    m.cone(0, 0, 0, 3.4, 3.6, 0.65, 2, 16)
    for i in range(5):
        m.cone(
            0,
            0.65 + i * 0.49,
            0,
            3.6 * cos(pi * i / 10),
            3.6 * cos(pi * (i + 1) / 10),
            0.49,
            24 if i % 2 else 4,
            16,
        )
    m.box(0, 0.9, 3.1, 1.5, 1.8, 1, 2)
    m.box(0, 1.1, 3.64, 1.05, 1.6, 0.10, 24)
    for j in range(3):
        for k in range(2):
            m.box(5 + j * 0.9, 1.50, -1 + k * 0.9, 0.82, 0.12, 0.82, 24)
    m.beam((6, 0, -0.5), (6, 1.5, -0.5), 0.2, 4)
    m.beam((-4, 0, 0), (-4, 5.0, 0), 0.18, 4)
    m.cone(-4, 3.7, 0, 0.25, 1.25, 0.9, 4)
    sign(m, "LUNA RELAY", 0, 2.65, 3.2, 3.1, 1, 16)
    save(m, "tour-relay")
    m = Model()
    m.box(0, 1.7, 0, 5.8, 3.4, 4.5, 5)
    for i in range(8):
        width = 5.9 - i * 0.68
        m.box(0, 3.45 + i * 0.25, 0, width, 0.26, 4.65, 8)
        for side in (-1, 1):
            m.box(side * width / 2, 3.45 + i * 0.25, 0, 0.44, 0.32, 4.95, 12)
    for xx in (-2.8, -1.4, 0, 1.4, 2.8):
        m.box(xx, 1.7, 2.3, 0.16, 3.45, 0.16, 7)
    for yy in (0.25, 1.8, 3.25):
        m.box(0, yy, 2.3, 5.8, 0.17, 0.17, 7)
    for xx in (-2.1, 2.1):
        m.beam((xx - 0.65, 0.3, 2.35), (xx + 0.65, 1.75, 2.35), 0.14, 7)
        m.box(xx, 2.45, 2.32, 0.85, 0.9, 0.13, 17)
    m.box(0, 0.95, 2.37, 1.08, 1.82, 0.2, 9)
    sign(m, "AHSEWEG", 0, 3.02, 2.42, 2.3, 13, 5)
    save(m, "tour-farm")
    # These modules are 3 x 2.5 x 3 metres before being fitted to the map.
    for city, name in enumerate(("tour-props", "tour-lander", "tour-hay")):
        m = Model()
        if city == 0:
            m.box(0, 1.08, 0, 2.95, 2.08, 2.95, 29)
            for side in (-1, 1):
                for y in (0.18, 1.75, 2.08):
                    m.box(0, y, side * 1.48, 3.02, 0.1, 0.08, 30)
                    m.box(side * 1.48, y, 0, 0.08, 0.1, 3.02, 30)
                for x in (-1.28, 1.28):
                    m.box(x, 1.02, 1.51 * side, 0.11, 1.85, 0.07, 4)
            m.box(0, 2.27, 0, 2.68, 0.36, 2.66, 2)
            sign(m, "PICTURES", 0, 1.27, 1.52, 2.2, 10, 17)
        elif city == 1:
            m.cone(0, 0.43, 0, 1.42, 1.2, 1.30, 15, 8)
            m.cone(0, 1.73, 0, 1.15, 0.78, 0.75, 4, 6)
            m.box(0, 2.03, 0.86, 1.14, 0.42, 0.17, 25)
            for a in (-1, 1):
                for b in (-1, 1):
                    m.beam((a * 0.86, 1.1, b * 0.86), (a * 1.38, 0.13, b * 1.38), 0.13, 5)
                    m.box(a * 1.34, 0.12, b * 1.34, 0.31, 0.23, 0.31, 16)
        else:
            for y in range(3):
                for x in (-0.74, 0.74):
                    m.box(x, y * 0.81 + 0.41, 0, 1.46, 0.8, 2.96, 15 if y % 2 else 9)
                    for z in (-0.9, 0.86):
                        m.box(x, y * 0.81 + 0.82, z, 1.49, 0.04, 0.09, 7)
                        for side in (-1, 1):
                            m.box(x + 0.72 * side, y * 0.81 + 0.42, z, 0.07, 0.81, 0.10, 7)
                    for j in range(5):
                        m.box(
                            x + (j % 2) * 0.38 - 0.26, y * 0.81 + 0.12 + j * 0.12, 1.49, 0.64, 0.035, 0.04, 16
                        )
        save(m, name)
    # Shallow regolith craters with a raised broken rim are a repeating terrain tile.
    m = Model()
    for j in range(9):
        x, z = (j * 11 % 21) - 10, (j * 13 % 17) - 8
        radius = 0.48 + (j % 3) * 0.46
        m.cone(x, 0.02, z, radius, radius * 0.90, 0.035, 3, 10)
        for i in range(8):
            a = pi * i / 4
            m.cone(x + radius * cos(a), 0.035, z + radius * sin(a), 0.16, 0.08, 0.13, 4, 5)
    save(m, "tour-craters")
    for city in range(3):
        m = Model()
        if city == 0:
            for j in range(19):
                x = (j - 9) * 3.5
                h = 4 + (j * 13) % 12
                m.box(x, h / 2, 0, 3.2, h, 2, 23)
                for y in range(2, h, 2):
                    for dx in (-0.85, 0.85):
                        m.box(x + dx, y, 1.03, 0.48, 0.6, 0.07, 16 if (j + y) % 3 else 17)
            sign(m, "HOLLYWOOD", 0, 13, 2, 18, 1, 5)
        elif city == 1:
            # Stepped pixel Earth, with lit continents, beyond a crater rim.
            for i in range(-7, 8):
                for j in range(-7, 8):
                    if i * i + j * j < 52:
                        c = (
                            31
                            if abs(j) > 5
                            else 23
                            if i < -3
                            else 22
                            if sin(i * 1.2 + j * 0.8) + cos(j) > 0.65
                            else 26
                        )
                        m.box(i * 0.72, 13 + j * 0.72, 0, 0.73, 0.73, 0.18, c)
            for j in range(15):
                m.cone((j - 7) * 4, 0, 0, 4 + (j % 3), 1, 2 + (j * 7) % 5, 3, 6)
        else:
            for j in range(11):
                x = (j - 5) * 5
                m.box(x, 0.35, 0, 4.8, 0.7, 4, 21)
                m.box(x, 2, 0, 0.58, 4, 0.65, 9)
                m.cone(x, 2.8, 0, 2.5, 1.6, 2, 21, 8)
                m.cone(x, 4.8, 0, 1.65, 0.4, 1.5, 22, 8)
            sign(m, "BETTINGHAUSEN", 0, 7.4, 2, 12, 17, 1)
        save(m, ("tour-skyline", "tour-earthrise", "tour-borde")[city])
