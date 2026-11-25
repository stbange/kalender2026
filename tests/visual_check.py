"""Capture WebGL landmarks and compare feedback on and off along the same eight-player route."""

import argparse
import json
from pathlib import Path
import shutil
import statistics
from playwright.sync_api import sync_playwright
from browser_smoke import open_game, website


def stage(x, z, yaw, effects):
    return f"""
local ordinary_init,ordinary_update,ordinary_hud=init,update,host_hud
function init()
    HostUTC=1798066800
    ordinary_init()
    local g=game.state
    g.x,g.z,g.yaw={x},{z},{yaw}
    g.room.players[1].x,g.room.players[1].z=g.x,g.z
    for i=2,8 do
        local p=Hall.join(g.room,i)
        p.x,p.z=(i-5)*1.5,-9-i*.2
    end
    if {str(not effects).lower()} then
        for _,prefix in ipairs({{"FIRE","HIT","VIS","HALL","OPT"}}) do
            for i=1,11 do Feedback.disabled[string.format("%s-%02d",prefix,i)]=true end
        end
        for i=1,7 do g.feedback.prefs[i]=0 end
    end
end
function update(dt)
    HostUTC=1798066800
    local g=game.state
    if not g.menu then
        local r=g.room
        for i,p in pairs(r.players) do
            if r.time>=p.cool then
                local t=Hall.targets[(i-1)%5+1]
                local dx,dy,dz=t[1]-p.x,t[2]-1.55,t[3]-p.z
                local d=math.sqrt(dx*dx+dy*dy+dz*dz)
                Hall.fire(r,p,p.seq+1,i%2==0 and 3 or 5,dx/d,dy/d,dz/d)
            end
        end
        ordinary_update(1/30)
    else ordinary_update(dt) end
end
function host_hud() return ordinary_hud().."|"..(game.state.feedback.drawn or 0) end
"""


def capture(site, out):
    out.mkdir(parents=True, exist_ok=True)
    original = (site / "games/kalender2026/scripts/main.lua").read_text()
    scenes = {
        "arrival": (0, 17, 0),
        "door-24": (-17.5, 19.6, 180),
        "range-off": (0, -8, 0),
        "range": (0, -8, 0),
    }
    runs = {}
    with (
        website(site) as url,
        sync_playwright() as pw,
        pw.chromium.launch(
            executable_path=shutil.which("chromium"),
            args=["--no-sandbox", "--use-angle=swiftshader", "--enable-unsafe-swiftshader"],
        ) as browser,
    ):
        for name, (x, z, yaw) in scenes.items():
            page = browser.new_page(viewport={"width": 960, "height": 540})
            script = original + stage(x, z, yaw, name != "range-off")
            page.route(
                "**/games/kalender2026/scripts/main.lua",
                lambda route: route.fulfill(body=script, content_type="text/plain"),
            )
            open_game(page, url)
            page.locator("#enter").click()
            page.wait_for_function("document.getElementById('days').textContent==='24'")
            if name == "door-24":
                page.wait_for_function("document.getElementById('hint').textContent.includes('Door 24')")
            page.screenshot(path=str(out / (name + ".png")))
            if name.startswith("range"):
                data = page.evaluate("""() => new Promise(resolve=>{
                    const timing=[],sprites=[];let last,warm=12;
                    function sample(now) {
                        if(warm>0)warm--;
                        else if(last!==undefined){timing.push(now-last);sprites.push(Number(hudText.split('|').at(-1)));}
                        last=now;
                        if(timing.length<48)requestAnimationFrame(sample);
                        else resolve({timing,sprites,voices:Module._hall_mix_stat(0),
                            played:Module._hall_mix_stat(1),dropped:Module._hall_mix_stat(2)});
                    }
                    requestAnimationFrame(sample);
                })""")
                renderer = page.evaluate("""() => {const g=Module.canvas.getContext('webgl2');
                    const e=g.getExtension('WEBGL_debug_renderer_info');
                    return e?g.getParameter(e.UNMASKED_RENDERER_WEBGL):g.getParameter(g.RENDERER);}""")
                frames = data["timing"]
                runs[name] = dict(
                    median_ms=round(statistics.median(frames), 2),
                    p95_ms=round(sorted(frames)[45], 2),
                    sample_frames=len(frames),
                    peak_sprites=max(data["sprites"]),
                    peak_voices=data["voices"],
                    played=data["played"],
                    dropped=data["dropped"],
                )
                assert runs[name]["peak_sprites"] <= 48 and data["voices"] <= 8
            page.close()
    assert runs["range"]["peak_sprites"] > 0 and runs["range"]["peak_voices"] > 0
    assert runs["range-off"]["peak_sprites"] == 0 and runs["range-off"]["peak_voices"] == 0
    report = dict(
        renderer=renderer,
        resolution=[960, 540],
        players=8,
        calendar_day=24,
        tools=["Spinner", "Snow Rocket"],
        runs=runs,
    )
    (out / "frame-times.json").write_text(json.dumps(report, indent=2) + "\n")
    print(json.dumps(report))


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--site", required=True, type=Path)
    parser.add_argument("--out", required=True, type=Path)
    args = parser.parse_args()
    capture(args.site.resolve(), args.out.resolve())
