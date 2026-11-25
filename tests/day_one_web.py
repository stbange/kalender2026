"""Play Door 1 in the packaged WebGL game with native touch events and deferred art."""

import argparse
import shutil
import time
from pathlib import Path
from PIL import Image
from playwright.sync_api import sync_playwright
from browser_smoke import website, open_game

# Stage a player at Door 1 before December. Input, loading, firing, snapshots and rendering are production paths.
PROBE = """
local boot,step,hud=init,update,host_hud
function init()
    HostUTC=1796079599
    boot()
    local g=game.state
    g.x,g.z=Hall.door(1)
    g.room.players[1].x,g.room.players[1].z=g.x,g.z
end

function update(dt)
    HostUTC=1796079599
    step(dt)
    local g=game.state
    if g.space==1 and not g.range then
        local p=g.room.players[g.id]
        local r=g.room.instances[1]
        p.x,p.z=-8,-9
        MissionPacks[1].act(r,p)
        g.x,g.z,g.yaw,g.pitch=0,-15,0,0
        p.x,p.z,p.yaw=g.x,g.z,0
        local a=r.actors[1]
        a.kind,a.x,a.z=1,0,-20
        g.range=a
    end
end

function host_hud()
    local g=game.state
    local p=g.room.players[g.id]
    return hud().."|"..g.seq..","..tostring(g.range and g.range.hp or -1)..","..g.space..","..g.yaw
end
"""


def stage(page):
    def observe(route):
        source = route.fetch()
        route.fulfill(response=source, body=source.text() + PROBE)

    page.route("**/scripts/main.lua", observe)


def stereo(browser, url):
    context = browser.new_context(reduced_motion="reduce", viewport={"width": 800, "height": 500})
    context.add_init_script(path=str(Path(__file__).with_name("xr_device.js")))
    page = context.new_page()
    stage(page)
    open_game(page, url)
    page.locator("#enter").click()
    state = "hudText.split('|').at(-1).split(',')"
    page.wait_for_function(state + "[2]==='1'")
    page.evaluate("document.exitPointerLock?.()")
    page.evaluate("menu(true)")
    page.locator("#vr").click()
    page.wait_for_function("stereoFrames > 3 && testSession.active")
    page.wait_for_function("Number("+state+"[0])>=2")
    page.locator("#vr").click()
    context.close()


def check(browser, url, options, capture):
    context = browser.new_context(**options)
    page = context.new_page()
    errors = []
    page.on("pageerror", lambda error: errors.append(str(error)))
    art = []
    page.on(
        "response",
        lambda response: art.append(response.status) if "/missions/day_01/" in response.url else None,
    )

    stage(page)
    open_game(page, url)
    page.locator("#enter").tap()
    state = "hudText.split('|').at(-1).split(',')"
    page.wait_for_function(state + "[2]==='1'", timeout=60000)
    assert page.locator("#days").text_content() == "1"
    assert page.locator("#hint").text_content().startswith("Midnight cinema")
    icons = page.locator(".rack [data-weapon] img")
    page.wait_for_function("""() => [...document.querySelectorAll('.rack [data-weapon] img')].every(
        image => image.currentSrc.includes('/day_01/rack-') && image.naturalWidth === 64)""")
    names = [src.rsplit("/", 1)[-1] for src in icons.evaluate_all("images => images.map(i => i.currentSrc)")]
    assert names == [f"rack-{gun}.png" for gun in ("sidearm", "freezer", "rpg", "shrinker", "twins")]
    assert page.locator(".rack button:disabled").count() == 4
    assert len(art) >= 20 and all(s == 200 for s in art)
    x, y = page.viewport_size["width"] * 0.82, page.viewport_size["height"] * 0.53
    page.touchscreen.tap(x, y)
    page.wait_for_timeout(650)
    assert page.evaluate(state)[0:2] == ["0", "2"]
    assert page.evaluate("([x,y])=>document.elementFromPoint(x,y)===canvas", [x, y])
    if browser.browser_type.name == "chromium":
        cdp = context.new_cdp_session(page)
        # Native finger timing remains consistent while software WebGL draws the scene.
        stamp = time.time()
        for dx in (0, 1):
            for kind, delay in (("touchStart", 0.12), ("touchEnd", 0.05)):
                stamp += delay
                cdp.send(
                    "Input.dispatchTouchEvent",
                    dict(type=kind, timestamp=stamp, touchPoints=[dict(id=1, x=x + dx, y=y + dx)]),
                )
    else:
        page.touchscreen.tap(x, y)
        page.touchscreen.tap(x + 1, y + 1)
    page.wait_for_function(state + "[1]==='1'")
    page.wait_for_timeout(600)
    assert page.evaluate(state)[0] == "1"
    page.locator("#fire").tap()
    page.wait_for_function(state + "[1]==='0'")
    assert page.evaluate(state)[0] == "2"
    if capture:
        page.screenshot(path=str(capture))
    assert not errors, errors
    context.close()


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--site", type=Path, required=True)
    parser.add_argument("--capture", type=Path)
    args = parser.parse_args()
    poses = set()
    for frame in range(4):
        path = args.site / f"games/kalender2026/missions/day_01/egg-{frame}.png"
        with Image.open(path) as image:
            assert image.mode == "RGBA" and image.getchannel("A").getextrema() == (0, 255), path
            poses.add(image.tobytes())
    assert len(poses) == 4, "The hatchling needs four distinct crawl poses"
    with website(args.site.resolve()) as url, sync_playwright() as pw:
        with pw.chromium.launch(
            executable_path=shutil.which("chromium"),
            args=[
                "--no-sandbox",
                "--use-angle=swiftshader",
                "--enable-unsafe-swiftshader",
            ],
        ) as browser:
            check(
                browser,
                url,
                dict(
                    has_touch=True,
                    is_mobile=True,
                    viewport={"width": 810, "height": 520},
                ),
                args.capture,
            )
            stereo(browser, url)
        with pw.webkit.launch() as browser:
            check(browser, url, pw.devices["iPhone 13"], None)
    print(
        "Day 1 pack, real WebGL entry, touch aiming and immediate pistol hits and held-trigger fire passed in Chromium, iPhone WebKit and emulated WebXR."
    )
