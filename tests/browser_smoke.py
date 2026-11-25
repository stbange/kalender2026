"""Play the staged WASM edition under a Pages-style subpath with a real TLS room."""

import argparse
import contextlib
import functools
import http.server
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import threading
from urllib.parse import urlencode

from playwright.sync_api import sync_playwright
from network_test import hello, service, snapshot, tls_proxy

ROOT = Path(__file__).resolve().parents[1]


@contextlib.contextmanager
def website(site):
    class Handler(http.server.SimpleHTTPRequestHandler):
        def translate_path(self, path):
            if path.startswith("/kalender2026/"):
                path = path[len("/kalender2026") :]
            return super().translate_path(path)

        def log_message(self, *args):
            pass

    handler = functools.partial(Handler, directory=str(site))
    with http.server.ThreadingHTTPServer(("127.0.0.1", 0), handler) as server:
        thread = threading.Thread(target=server.serve_forever, daemon=True)
        thread.start()
        try:
            yield f"http://127.0.0.1:{server.server_port}/kalender2026/"
        finally:
            server.shutdown()
            thread.join()


def open_game(page, url):
    page.goto(url, wait_until="domcontentloaded", timeout=60000)
    page.wait_for_function("document.getElementById('enter').disabled === false", timeout=60000)


def expect_text(page, selector, part):
    try:
        page.wait_for_function(
            "([s,p]) => document.querySelector(s).textContent.includes(p)",
            arg=[selector, part],
            timeout=20000,
        )
    except Exception:
        print(
            "Expected",
            selector,
            part,
            "but saw",
            page.locator(selector).text_content(),
            page.evaluate("({hud:hudText,mode:document.body.dataset.mode})"),
            flush=True,
        )
        raise


def run(site, binary):
    with (
        tempfile.TemporaryDirectory() as tmp,
        website(site) as base,
        service(binary, ROOT) as port,
        tls_proxy(port, tmp) as (secure, cert, names),
        sync_playwright() as pw,
    ):
        args = [
            "--no-sandbox",
            "--use-angle=swiftshader",
            "--enable-unsafe-swiftshader",
            "--ignore-certificate-errors",
            "--disable-background-timer-throttling",
            "--disable-renderer-backgrounding",
            "--disable-backgrounding-occluded-windows",
        ]
        exe = os.environ.get("CHROMIUM") or shutil.which("chromium")
        # Both flat and stereo paths draw using the actual WASM engine and WebGL context.
        browser = pw.chromium.launch(executable_path=exe, args=args)
        desktop = browser.new_context(
            ignore_https_errors=True, reduced_motion="reduce", viewport={"width": 800, "height": 500}
        )
        desktop.add_init_script(path=str(ROOT / "tests/xr_device.js"))
        page = desktop.new_page()
        errors = []
        failed = []
        sent = []
        page.on("pageerror", lambda err: errors.append(str(err)))
        page.on("response", lambda r: failed.append((r.status, r.url)) if r.status >= 400 else None)
        page.on("websocket", lambda ws: ws.on("framesent", lambda data: sent.append(data)))
        observer, answer = hello(f"ws://127.0.0.1:{port}", "browsers")
        assert answer == "WELCOME 1"
        with contextlib.closing(observer):
            # Fire while the path to the bell is clear. Visitors keep walking during browser startup.
            observer.send("F 1 1 -.1592 .00796 -.98722")
            snapshot(observer, lambda s: s["hits"] >= 1)
            open_game(page, base)
            assert page.locator("h1").inner_text().replace("\n", " ") == "The Lantern Hall"
            page.locator("#feedback").click()
            pref = lambda n: page.locator(f'[data-pref="{n}"]')
            assert pref(8).is_checked() and pref(1).input_value() == "0" and pref(2).input_value() == "25"
            pref(8).focus()
            page.keyboard.press("Space")
            for n, key, value in [
                (1, "Home", "0"),
                (1, "ArrowRight", "10"),
                (2, "End", "100"),
                (3, "Home", "0"),
                (4, "End", "100"),
            ]:
                pref(n).focus()
                page.keyboard.press(key)
                assert pref(n).input_value() == value, (n, key, value, pref(n).input_value())
            for n in (5, 6, 7):
                pref(n).focus()
                page.keyboard.press("Space")
            assert pref(7).is_checked() and pref(6).is_checked() and not pref(5).is_checked()
            page.locator("#close").click()
            page.locator("#join").click()
            page.locator("[name=server]").fill(secure)
            page.locator("[name=room]").fill("browsers")
            page.locator("#roomForm .primary").click()
            expect_text(page, "#connection", "Live room · 2/8")
            snapshot(observer, lambda s: len(s["players"]) == 2)
            for key, name in [
                ("2", "Flurry Fan"),
                ("3", "Snow Spinner"),
                ("4", "Bankshot"),
                ("5", "Snow Rocket"),
                ("1", "Snowball Pistol"),
            ]:
                page.keyboard.down(key)
                page.wait_for_timeout(180)
                page.keyboard.up(key)
                expect_text(page, "#weaponName", name)
            page.mouse.move(400, 250)
            page.mouse.down()
            try:
                for _ in range(40):
                    page.wait_for_timeout(100)
                    if any(isinstance(msg, bytes) and msg.startswith(b"\x01F ") for msg in sent):
                        break
                assert any(isinstance(msg, bytes) and msg.startswith(b"\x01F ") for msg in sent), (
                    sent[-10:],
                    page.evaluate("hudText"),
                )
            finally:
                page.mouse.up()
            page.wait_for_function("Number(document.getElementById('bells').textContent)>0", timeout=20000)
            # Native and browser clients transport game state through the same WSS reverse proxy.
            native = subprocess.Popen(
                [
                    str(binary),
                    "--root",
                    str(ROOT),
                    "--headless",
                    "--save",
                    tmp,
                    "--endpoint",
                    secure,
                    "--room",
                    "browsers",
                    "--ca",
                    str(cert),
                    "--frames",
                    "440",
                ]
            )
            try:
                expect_text(page, "#connection", "3/8")
                assert native.wait(timeout=20) == 0
            finally:
                if native.poll() is None:
                    native.terminate()
                    native.wait()
            page.evaluate("document.exitPointerLock?.()")
            page.evaluate("menu(true)")
            page.evaluate("""() => {
                const render=Module._hall_xr_frame;
                window.eyeSamples=[];
                Module._hall_xr_frame=(fb,m,v,i)=>{
                    eyeSamples.push(Array.from(Module.HEAPF32.slice(m/4,m/4+64)));
                    return render(fb,m,v,i);
                };
            }""")
            page.locator("#vr").click()
            page.wait_for_function("window.stereoFrames >= 3", timeout=20000)
            page.wait_for_function("testPulses.some(([gain,ms]) => gain>0 && ms===18)", timeout=20000)
            page.evaluate("Module._hall_choose(5)")
            page.wait_for_function("testPulses.some(([gain,ms]) => gain>0 && ms===45)", timeout=20000)
            eyes = page.evaluate("eyeSamples")
            assert eyes[0][12] > 0 and eyes[0][44] < 0
            assert all(sample == eyes[0] for sample in eyes)
            page.locator("#vr").click()
            expect_text(page, "#vr", "Enter VR")
            assert not page.evaluate("window.testSession.active")
            assert page.evaluate("testPulses.at(-1)[0] === 0")
            page.evaluate("window.withActuator=false")
            frames = page.evaluate("stereoFrames")
            page.locator("#vr").click()
            page.wait_for_function("n => stereoFrames > n+2", arg=frames)
            page.locator("#vr").click()
            expect_text(page, "#vr", "Enter VR")
            assert "localhost" in names
            mobile = browser.new_context(
                ignore_https_errors=True,
                has_touch=True,
                is_mobile=True,
                viewport={"width": 390, "height": 700},
                device_scale_factor=1,
            )
            touch = mobile.new_page()
            touch.on("pageerror", lambda err: errors.append(str(err)))
            open_game(touch, base + "?" + urlencode({"server": secure, "room": "browsers"}))
            touch.locator("#feedback").tap()
            assert touch.locator('[data-pref="1"]').input_value() == "100"
            touch.locator('[data-pref="6"]').tap()
            assert touch.locator('[data-pref="6"]').is_checked()
            assert touch.locator("#feedbackForm").bounding_box()["width"] <= 390
            touch.locator("#close").tap()
            touch.locator("#enter").tap()
            expect_text(touch, "#connection", "Live room")
            snapshot(observer, lambda s: len(s["players"]) >= 2)
            assert touch.locator("#stick").is_visible() and touch.locator("#fire").is_visible()
            touch.locator('[data-weapon="4"]').tap()
            expect_text(touch, "#weaponName", "Bankshot")
            cdp = mobile.new_cdp_session(touch)

            def point(locator, id):
                b = touch.locator(locator).bounding_box()
                return dict(x=b["x"] + 0.5 * b["width"], y=b["y"] + 0.3 * b["height"], id=id)

            pts = [point("#stick", 1), dict(x=262, y=320, id=2), point("#fire", 3)]
            cdp.send("Input.dispatchTouchEvent", {"type": "touchStart", "touchPoints": pts})
            pts[1]["x"] += 20
            cdp.send("Input.dispatchTouchEvent", {"type": "touchMove", "touchPoints": pts})
            touch.wait_for_timeout(400)
            cdp.send("Input.dispatchTouchEvent", {"type": "touchCancel", "touchPoints": []})
            assert touch.evaluate("moving===null && looking===null")
            touch.set_viewport_size({"width": 700, "height": 390})
            assert touch.locator("#fire").is_visible()
            mobile.close()
            page.reload()
            page.wait_for_function("!document.getElementById('enter').disabled")
            page.locator("#feedback").click()
            assert [pref(n).input_value() for n in range(1, 5)] == ["10", "100", "0", "100"]
            assert pref(7).is_checked() and pref(6).is_checked() and not pref(5).is_checked()
            page.locator("#close").click()
            page.locator("#join").click()
            assert page.locator("[name=server]").input_value() == secure
            assert page.locator("[name=room]").input_value() == "browsers"
            page.locator("#roomForm .primary").click()
            expect_text(page, "#connection", "2/8")
        desktop.close()
        # Arrange a real snowman in the pistol's path. Its health, movement, hits and clears use shipping Lua.
        practice = browser.new_context(viewport={"width": 960, "height": 540}, reduced_motion="reduce")
        solo = practice.new_page()
        solo.on("pageerror", lambda err: errors.append(str(err)))
        script = (
            (site / "games/kalender2026/scripts/main.lua").read_text()
            + """
local ordinary_init=init
function init()
    ordinary_init()
    local g=game.state
    g.room.mobs[1].x,g.room.mobs[1].z=g.x,g.z-2.8
end
local hud=host_hud
function host_hud() return hud().."|"..string.format("%.2f",game.state.yaw) end
"""
        )
        solo.route(
            "**/games/kalender2026/scripts/main.lua",
            lambda route: route.fulfill(body=script, content_type="text/plain"),
        )
        open_game(solo, base)
        solo.locator("#feedback").click()
        solo.locator('[data-pref="7"]').check()
        solo.locator("#close").click()
        solo.locator("#enter").click()
        solo.evaluate("""() => {
            window.seenMarks=new Set();
            const m=document.querySelector('#hitMark');
            new MutationObserver(()=>{if(!m.hidden) seenMarks.add(m.src.split('/').at(-1));})
              .observe(m,{attributes:true});
        }""")
        solo.mouse.down()
        try:
            solo.wait_for_function(
                "seenMarks.has('ticks-contrast.png') && seenMarks.has('finish-contrast.png')", timeout=20000
            )
        finally:
            solo.mouse.up()
        assert solo.locator("#visitors").inner_text() == "4"
        # Menu pointer coordinates must leave the first shot on target. Locked relative motion still turns.
        assert float(solo.evaluate("hudText.split('|').at(-1)")) == 0
        solo.evaluate("canvas.dispatchEvent(new MouseEvent('mousemove',{bubbles:true,movementX:18}))")
        solo.wait_for_function("Math.abs(Number(hudText.split('|').at(-1))) > 1")
        practice.close()
        assert not errors, errors
        assert not failed, failed
        browser.close()
    print(
        "Pages subpath, WASM, external content, desktop, mobile multitouch, WSS cross-play, reconnect and stereo lifecycle passed."
    )


if __name__ == "__main__":
    p = argparse.ArgumentParser()
    p.add_argument("--site", required=True, type=Path)
    p.add_argument("--binary", required=True, type=Path)
    args = p.parse_args()
    run(args.site.resolve(), args.binary.resolve())
