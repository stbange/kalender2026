"""Render a cycle of the five live visitor rigs through the shipping WASM renderer."""

import argparse
from pathlib import Path
import shutil
from PIL import Image
from playwright.sync_api import sync_playwright
from browser_smoke import open_game, website

# Step ordinary gameplay at a fixed rate between captures. No poses are supplied by the fixture.
ARRANGE = """
local ordinary_init, ordinary_update = init,update
local pending=0
function init()
    ordinary_init()
    local g=game.state
    g.x,g.z,g.yaw=0,12,0
    local r=g.room
    r.players[1].x,r.players[1].z=g.x,g.z
    for i,m in ipairs(r.mobs) do m.x,m.z,m.wake=(i-3)*1.53,5.75,0 end
end
local choose=host_weapon
function host_weapon(tool)
    if tool==5 then pending=pending+1 else choose(tool) end
end
local hud=host_hud
local frame=0
function host_hud() return hud().."|"..frame end
function update(dt)
    if pending>0 then
        for i=1,4 do ordinary_update(1/48) end
        frame=frame+1
        pending=pending-1
    else
        ordinary_update(0)
    end
    eng.scene.set_pos(World.gun,0,-40,0)
end
"""


def capture(site, output):
    original = (site / "games/kalender2026/scripts/main.lua").read_text()
    with (
        website(site) as url,
        sync_playwright() as pw,
        pw.chromium.launch(
            executable_path=shutil.which("chromium"),
            args=["--no-sandbox", "--use-angle=swiftshader", "--enable-unsafe-swiftshader"],
        ) as browser,
    ):
        page = browser.new_page(viewport={"width": 960, "height": 540}, device_scale_factor=1)
        page.route(
            "**/games/kalender2026/scripts/main.lua",
            lambda route: route.fulfill(body=original + ARRANGE, content_type="text/plain"),
        )
        open_game(page, url)
        page.locator("#enter").click()
        page.add_style_tag(content="#hud { visibility: hidden }")
        frames = []
        import io

        for step in range(1, 17):
            page.evaluate("Module._hall_choose(5)")
            page.wait_for_function("n => Number(hudText.split('|').at(-1))===n", arg=step)
            data = page.locator("canvas").screenshot()
            frame = Image.open(io.BytesIO(data)).convert("RGB").crop((80, 141, 880, 440))
            frames.append(frame)
        assert len({f.tobytes() for f in frames}) == len(frames)
        output.parent.mkdir(parents=True, exist_ok=True)
        frames[0].save(
            output, save_all=True, append_images=frames[1:], duration=83, loop=0, quality=82, method=5
        )
        print(f"{len(frames)} gameplay frames, {frames[0].size}, {output.stat().st_size} bytes")


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--site", required=True, type=Path)
    parser.add_argument("--out", required=True, type=Path)
    args = parser.parse_args()
    capture(args.site.resolve(), args.out.resolve())
