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
                path = path[len("/kalender2026"):]
            return super().translate_path(path)
        def log_message(self, *args):
            pass
    handler = functools.partial(Handler, directory=str(site))
    with http.server.ThreadingHTTPServer(("127.0.0.1",0),handler) as server:
        thread=threading.Thread(target=server.serve_forever,daemon=True);thread.start()
        try:
            yield f"http://127.0.0.1:{server.server_port}/kalender2026/"
        finally:
            server.shutdown();thread.join()


def open_game(page,url):
    page.goto(url,wait_until="domcontentloaded",timeout=60000)
    page.wait_for_function("document.getElementById('enter').disabled === false",timeout=60000)


def expect_text(page,selector,part):
    try:
        page.wait_for_function("([s,p]) => document.querySelector(s).textContent.includes(p)",
                               arg=[selector,part],timeout=20000)
    except Exception:
        print("Expected",selector,part,"but saw",page.locator(selector).text_content(),
              page.evaluate("({hud:hudText,mode:document.body.dataset.mode})"),flush=True)
        raise


def run(site,binary):
    with tempfile.TemporaryDirectory() as tmp, website(site) as base, service(binary,ROOT) as port, \
            tls_proxy(port,tmp) as (secure,cert,names), sync_playwright() as pw:
        args=["--no-sandbox","--use-angle=swiftshader","--enable-unsafe-swiftshader","--ignore-certificate-errors",
              "--disable-background-timer-throttling","--disable-renderer-backgrounding","--disable-backgrounding-occluded-windows"]
        exe=os.environ.get("CHROMIUM") or shutil.which("chromium")
        # Both flat and stereo paths draw using the actual WASM engine and WebGL context.
        browser=pw.chromium.launch(executable_path=exe,args=args)
        desktop=browser.new_context(ignore_https_errors=True,viewport={"width":800,"height":500})
        desktop.add_init_script(path=str(ROOT/"tests/xr_device.js"))
        page=desktop.new_page()
        errors=[];failed=[];sent=[]
        page.on("pageerror",lambda err: errors.append(str(err)))
        page.on("response",lambda r:failed.append((r.status,r.url)) if r.status>=400 else None)
        page.on("websocket",lambda ws:ws.on("framesent",lambda data:sent.append(data)))
        observer,answer=hello(f"ws://127.0.0.1:{port}","browsers")
        assert answer=="WELCOME 1"
        with contextlib.closing(observer):
            open_game(page,base)
            assert page.locator("h1").inner_text().replace("\n"," ")=="The Lantern Hall"
            page.locator("#join").click()
            page.locator("[name=server]").fill(secure);page.locator("[name=room]").fill("browsers")
            page.locator("#roomForm .primary").click()
            expect_text(page,"#connection","Live room · 2/8")
            snapshot(observer,lambda s:len(s["players"])==2)
            for key,name in [("2","Flurry Fan"),("3","Snow Spinner"),("4","Bankshot"),("5","Snow Rocket"),("1","Snowball Pistol")]:
                page.keyboard.down(key);page.wait_for_timeout(180);page.keyboard.up(key)
                expect_text(page,"#weaponName",name)
            page.mouse.move(400,250)
            page.mouse.down()
            try:
                for _ in range(40):
                    page.wait_for_timeout(100)
                    if any(str(msg).startswith("F ") for msg in sent):break
                assert any(str(msg).startswith("F ") for msg in sent),(sent[-10:],page.evaluate("hudText"))
            finally:page.mouse.up()
            observer.send("F 1 1 -.1592 .00796 -.98722")
            snapshot(observer,lambda s:s["hits"]>=1)
            page.wait_for_function("Number(document.getElementById('bells').textContent)>0",timeout=20000)
            # Native and browser clients transport game state through the same WSS reverse proxy.
            native=subprocess.Popen([str(binary),"--root",str(ROOT),"--headless","--save",tmp,
                                     "--endpoint",secure,"--room","browsers","--ca",str(cert),"--frames","440"])
            try:
                expect_text(page,"#connection","3/8")
                assert native.wait(timeout=20)==0
            finally:
                if native.poll() is None:native.terminate();native.wait()
            page.evaluate("document.exitPointerLock?.()")
            page.evaluate("menu(true)")
            page.locator("#vr").click()
            page.wait_for_function("window.stereoFrames >= 3",timeout=20000)
            page.locator("#vr").click()
            expect_text(page,"#vr","Enter VR")
            assert not page.evaluate("window.testSession.active")
            assert "localhost" in names
            mobile=browser.new_context(ignore_https_errors=True,has_touch=True,is_mobile=True,
                                       viewport={"width":390,"height":700},device_scale_factor=1)
            touch=mobile.new_page();touch.on("pageerror",lambda err:errors.append(str(err)))
            open_game(touch,base+"?"+urlencode({"server":secure,"room":"browsers"}))
            touch.locator("#enter").tap()
            expect_text(touch,"#connection","Live room")
            snapshot(observer,lambda s:len(s["players"])>=2)
            assert touch.locator("#stick").is_visible() and touch.locator("#fire").is_visible()
            touch.locator('[data-weapon="4"]').tap();expect_text(touch,"#weaponName","Bankshot")
            cdp=mobile.new_cdp_session(touch)
            def point(locator,id):
                b=touch.locator(locator).bounding_box()
                return dict(x=b["x"]+.5*b["width"],y=b["y"]+.3*b["height"],id=id)
            pts=[point("#stick",1),dict(x=262,y=320,id=2),point("#fire",3)]
            cdp.send("Input.dispatchTouchEvent",{"type":"touchStart","touchPoints":pts})
            pts[1]["x"]+=20
            cdp.send("Input.dispatchTouchEvent",{"type":"touchMove","touchPoints":pts})
            touch.wait_for_timeout(400)
            cdp.send("Input.dispatchTouchEvent",{"type":"touchCancel","touchPoints":[]})
            assert touch.evaluate("moving===null && looking===null")
            touch.set_viewport_size({"width":700,"height":390})
            assert touch.locator("#fire").is_visible()
            mobile.close()
            page.reload();page.wait_for_function("!document.getElementById('enter').disabled")
            page.locator("#join").click()
            assert page.locator("[name=server]").input_value()==secure
            assert page.locator("[name=room]").input_value()=="browsers"
            page.locator("#roomForm .primary").click()
            expect_text(page,"#connection","2/8")
        assert not errors,errors
        assert not failed,failed
        browser.close()
    print("Pages subpath, WASM, external content, desktop, mobile multitouch, WSS cross-play, reconnect and stereo lifecycle passed.")


if __name__=="__main__":
    p=argparse.ArgumentParser()
    p.add_argument("--site",required=True,type=Path);p.add_argument("--binary",required=True,type=Path)
    args=p.parse_args();run(args.site.resolve(),args.binary.resolve())
