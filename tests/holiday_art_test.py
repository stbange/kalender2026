"""Check the packaged light masks and their projection against a simple occluder of known height."""

import sys
from pathlib import Path
from types import SimpleNamespace
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools"))
from make_hall_shadows import EXTENT, SIZE, below_light, occlusion

assets = ROOT / "games/kalender2026/assets"


def floor_point(x, z):
    return tuple(int((c + EXTENT) * SIZE / (2 * EXTENT)) for c in (x, z))


# The triangle sits halfway from the floor to the light. Its shadow doubles in size and distance.
tri = [(1, 2, 0), (2, 2, 0), (1, 2, 1)]
test = occlusion([SimpleNamespace(verts=tri)], ("test", (0, 4, 0), (1, 1, 1), 10))
assert test.getpixel(floor_point(2.5, 0.5)) > 245
assert test.getpixel(floor_point(1.25, 0.25)) == 0
assert test.getpixel(floor_point(-2.5, -0.5)) == 0
clip = below_light([(0, 5, 1), (2, 1, 1), (1, 0, -1)], 3)
assert len(clip) == 4 and max(p[1] for p in clip) == 3

with Image.open(assets / "hall-floor.png") as floor:
    assert floor.mode == "RGBA" and floor.size == (SIZE, SIZE)
    masks = floor.getchannel("A")

    def channels(x, z):
        value = masks.getpixel(floor_point(x, z))
        return value % 16, value // 16

    assert channels(0, -4) == (0, 15)  # The spruce interrupts the entrance candlelight.
    assert channels(0, 14) == (0, 0)  # Moving visitors can cast clean silhouettes here.
    assert channels(-22, 0)[0] == 15  # The projecting hearth interrupts the fire.
    values = set(masks.tobytes())
    assert any(a % 16 > 10 and a // 16 == 0 for a in values)
    assert any(a % 16 > 10 and a // 16 > 10 for a in values)

frames = sorted(assets.glob("hearth-fire-*.png"))
assert len(frames) == 16
shapes = set()
for frame in frames:
    with Image.open(frame) as flame:
        alpha = flame.getchannel("A")
        assert alpha.getpixel((0, 0)) == 0 and alpha.getextrema() == (0, 255)
        shapes.add(alpha.tobytes())
assert len(shapes) == len(frames)
print("Both practical-light masks project correctly and the loose fire contains 16 distinct silhouettes.")
