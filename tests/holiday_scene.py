"""Play the shipping WebGL hall at fixed camera poses and check its light, shadows and winter windows."""

import argparse
import io
import shutil
from pathlib import Path
from PIL import Image, ImageChops, ImageStat
from playwright.sync_api import sync_playwright
from browser_smoke import open_game, website

# The poses feed the ordinary Lua scene and ECS. Hold the room clock still so snow and visitors
# cannot account for pixel differences between the two fire frames or between shadow passes.
SCENES = """
local hud=host_hud
local view=1
local poses={
    {13,16,37,6}, {-16.9,0,90,8}, {-16.9,0,90,8}, {-16.9,0,90,8}, {-16.9,0,90,8},
    {22.33,-18.2,0,7}, {22.78,-18.2,0,7}, {0,19.0,0,-13}, {5.8,-7.45,139,-11}
}
function host_weapon() view=view+1 end
function host_hud() return hud().."|"..view end
function update(dt)
    local g=game.state
    local c=poses[view]
    g.x,g.z,g.yaw,g.pitch=c[1],c[2],c[3],c[4]
    g.clock=(view==3 or view==5) and .77 or .17
    g.room.time=.17
    g.feedback.prefs[1]=(view==4 or view==5) and 0 or 100
    g.room.players[1].x,g.room.players[1].z=g.x,g.z
    if view==8 then
        g.room.mobs[1].x,g.room.mobs[1].z,g.room.mobs[1].wake=-1.4,14,0
        g.room.mobs[4].x,g.room.mobs[4].z,g.room.mobs[4].wake=1.1,14.6,0
    end
    if view==9 then for _,m in ipairs(g.room.mobs) do m.wake=999 end end
    World.update(g,0)
end
"""

NAMES = (
    "hall",
    "hearth",
    "flame-b",
    "steady-a",
    "steady-b",
    "winter-window",
    "window-shift",
    "visitors",
    "tree-shadow",
)


def frames(browser, site, url, views, *, reference=False):
    page = browser.new_page(viewport={"width": 1280, "height": 720}, device_scale_factor=1)
    errors = []
    page.on("pageerror", lambda e: errors.append(str(e)))
    game = site / "games/kalender2026"
    script = (game / "scripts/main.lua").read_text() + SCENES
    page.route(
        "**/games/kalender2026/scripts/main.lua",
        lambda r: r.fulfill(body=script, content_type="text/plain"),
    )
    if reference:
        # In the visitor pose keep the architectural masks and remove only the cast silhouettes.
        # In the second pose the hall is empty, so remove its baked masks to isolate the spruce's shadow.
        shader = (game / "shaders/forward.frag").read_text()
        factor = "atten *= 1.0 - 0.95 * occlusion;"
        assert shader.count(factor) == 1
        baseline = "occlusion = u_cam_pos.z > 15.0 ? (i == 0 ? blocked.x : blocked.y) : 0.0; " + factor
        page.route(
            "**/games/kalender2026/shaders/forward.frag",
            lambda r: r.fulfill(body=shader.replace(factor, baseline), content_type="text/plain"),
        )
    open_game(page, url)
    page.locator("#enter").click()
    # The HUD uses display pixels; the backbuffer has a smaller fixed upper bound.
    assert page.evaluate("[canvas.width,canvas.height,canvas.clientWidth,canvas.clientHeight]") == [
        960,
        540,
        1280,
        720,
    ]
    page.set_viewport_size({"width": 960, "height": 540})
    page.add_style_tag(content="main > :not(canvas) {visibility:hidden !important}")
    result = {}
    last = 1
    for index in views:
        page.evaluate("n=>{for(let i=0;i<n;i++)Module._hall_choose(1)}", index - last)
        page.wait_for_function("n=>hudText.split('|').at(-1)===String(n)", arg=index)
        page.evaluate("()=>new Promise(ok=>requestAnimationFrame(()=>requestAnimationFrame(ok)))")
        result[index] = Image.open(io.BytesIO(page.locator("canvas").screenshot())).convert("RGB")
        last = index
    assert not errors, errors
    page.close()
    return result


def pixels(im):
    buf = im.tobytes()
    return zip(buf[0::3], buf[1::3], buf[2::3])


def changed(a, b, region, threshold):
    diff = ImageChops.difference(a.crop(region), b.crop(region)).convert("L")
    return sum(diff.histogram()[threshold:])


def capture(site, out):
    out.mkdir(parents=True, exist_ok=True)
    with (
        website(site) as url,
        sync_playwright() as pw,
        pw.chromium.launch(
            executable_path=shutil.which("chromium"),
            args=["--no-sandbox", "--use-angle=swiftshader", "--enable-unsafe-swiftshader"],
        ) as browser,
    ):
        images = frames(browser, site, url, range(1, 10))
        reference = frames(browser, site, url, (8, 9), reference=True)
    for i, im in images.items():
        im.save(out / (NAMES[i - 1] + ".png"))
    # The room stays dark while a small part of the image contains genuinely bright fixtures.
    hall = images[1].convert("L")
    assert 12 < ImageStat.Stat(hall).mean[0] < 60 and sum(hall.histogram()[155:]) > 150
    fire = (342, 260, 594, 442)
    moving = changed(images[2], images[3], fire, 12)
    still = changed(images[4], images[5], fire, 4)
    assert moving > 380 and still < 12, (moving, still)
    # Infinity stars stay pinned in the overlapping apertures. The blue silhouette moves against them.
    sky = (240, 108, 720, 365)

    def star_locations(im):
        return {
            i
            for i, (r, g, b) in enumerate(pixels(im.crop(sky)))
            if b > 165 and g > 140 and r > 115 and b >= g and g >= r
        }

    stars = star_locations(images[6])
    held = stars & star_locations(images[7])
    left, right = (im.crop(sky) for im in (images[6], images[7]))
    shifted = sum(
        1
        for a, b in zip(pixels(left), pixels(right))
        if a[2] > a[0] + 12 and b[2] > b[0] + 12 and abs(a[2] - b[2]) > 18
    )
    assert len(held) > 12 and shifted > 75, (len(stars), len(held), shifted)
    floor = (30, 260, 930, 530)
    moving_shadows = changed(images[8], reference[8], floor, 7)
    tree_shadow = changed(images[9], reference[9], floor, 4)
    assert moving_shadows > 150 and tree_shadow > 150, (moving_shadows, tree_shadow)
    print(
        f"Fire changed {moving} pixels, reduced motion {still}. {len(held)} star pixels held as the landscape shifted {shifted} pixels. "
        f"Visitor and tree views gained {moving_shadows} and {tree_shadow} shadow pixels."
    )


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--site", type=Path, required=True)
    parser.add_argument("--out", type=Path, required=True)
    args = parser.parse_args()
    capture(args.site.resolve(), args.out.resolve())
