"""Capture the actual renderer at three hall landmarks and time a populated day-24 view."""

import argparse
import json
from pathlib import Path
import shutil
import statistics
from playwright.sync_api import sync_playwright
from browser_smoke import open_game, website


def capture(site, out):
    out.mkdir(parents=True, exist_ok=True)
    original = (site / "games/kalender2026/scripts/main.lua").read_text()
    # Only the test response changes starting positions. Models, UI, renderer and physics are the release files.
    scenes = {"arrival": (0, 17, 0), "door-24": (-17.5, 19.6, 180), "range": (0, -8, 0)}
    with website(site) as url, sync_playwright() as pw:
        with pw.chromium.launch(
            executable_path=shutil.which("chromium"),
            args=["--no-sandbox", "--use-angle=swiftshader", "--enable-unsafe-swiftshader"],
        ) as browser:
            for name, (x, z, yaw) in scenes.items():
                page = browser.new_page(viewport={"width": 960, "height": 540})
                script = (
                    original
                    + f"""
local ordinary_init,ordinary_update=init,update
function init()
    HostUTC=1798066800
    ordinary_init()
    local g=game.state
    g.x,g.z,g.yaw={x},{z},{yaw}
    g.room.players[1].x,g.room.players[1].z=g.x,g.z
    for i=2,8 do
        local p=Hall.join(g.room,i)
        p.x,p.z=(i%2==0 and 9 or -9),-5-i*.7
        if i==5 then p.x,p.z=-5,-11 end
    end
end
function update(dt)
    HostUTC=1798066800
    local r=game.state.room
    if r.time>=r.players[5].cool then
        Hall.fire(r,r.players[5],r.players[5].seq+1,3,0,.06,-1)
    end
    ordinary_update(dt)
end
"""
                )
                page.route(
                    "**/games/kalender2026/scripts/main.lua",
                    lambda route: route.fulfill(body=script, content_type="text/plain"),
                )
                open_game(page, url)
                page.locator("#enter").click()
                page.wait_for_function("document.getElementById('days').textContent==='24'")
                if name == "door-24":
                    page.wait_for_function(
                        "document.getElementById('hint').textContent.includes('Door 24')"
                    )
                page.screenshot(path=str(out / (name + ".png")))
                if name == "range":
                    timings = page.evaluate("""() => new Promise(resolve=>{
                      const deltas=[];let last;
                      function sample(now){if(last!==undefined)deltas.push(now-last);last=now;
                        if(deltas.length<32)requestAnimationFrame(sample);else resolve(deltas);}
                      requestAnimationFrame(sample);
                    })""")
                    renderer = page.evaluate("""() => {const g=Module.canvas.getContext('webgl2');
                      const e=g.getExtension('WEBGL_debug_renderer_info');
                      return e?g.getParameter(e.UNMASKED_RENDERER_WEBGL):g.getParameter(g.RENDERER);}""")
                    report = {
                        "renderer": renderer,
                        "resolution": [960, 540],
                        "visible_players": 8,
                        "calendar_day": 24,
                        "target_range": "active",
                        "sample_frames": len(timings),
                        "median_ms": round(statistics.median(timings), 2),
                        "p95_ms": round(sorted(timings)[int(0.95 * len(timings))], 2),
                    }
                    (out / "frame-times.json").write_text(json.dumps(report, indent=2) + "\n")
                    print(json.dumps(report))
                page.close()


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--site", required=True, type=Path)
    parser.add_argument("--out", required=True, type=Path)
    args = parser.parse_args()
    capture(args.site.resolve(), args.out.resolve())
