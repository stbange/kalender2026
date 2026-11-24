"""Install, break and replace a test day without rebuilding the server, client or WASM."""
import argparse
import hashlib
import json
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

from playwright.sync_api import sync_playwright
from browser_smoke import ROOT, expect_text, open_game, website

GAME=Path("games/kalender2026")
sys.path.insert(0,str(ROOT/"tools"))
from package import package


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def verify(binary,web_build):
    with tempfile.TemporaryDirectory() as tmp:
        base=Path(tmp); fixture=base/"fixture";stage=base/"native";site=base/"web";save=base/"profile"
        save.mkdir();shutil.copytree(ROOT/"tests/fixture",fixture)
        extra=fixture/"missions/test-target.glb"
        catalog=json.loads((fixture/"missions/catalog.json").read_text())
        catalog["missions"][0]["files"]=["missions/test-target.glb"]
        (fixture/"missions/catalog.json").write_text(json.dumps(catalog))
        scripts=fixture/"scripts";scripts.mkdir()
        original=(ROOT/GAME/"scripts/main.lua").read_text()
        # Place the test participant at the entrance. Portal, interaction, save and HUD paths are the release paths.
        (scripts/"main.lua").write_text(original+"""
local original_init,original_update=init,update
function init()
    HostUTC=1796079600
    original_init()
    local g=game.state
    g.x,g.z=Hall.door(1)
    g.room.players[1].x,g.room.players[1].z=g.x,g.z
    if g.awards>0 then Hall.weapons[1].name="Saved ornament" end
end
function update(dt) HostUTC=1796079600;original_update(dt) end
""")
        code=(fixture/"missions/day_01.lua").read_text()
        newcode=code+"""
MissionPacks[1].build=function(pocket,pedestal)
    local asset=eng.asset.load_mesh("missions/test-target.glb")
    assert(asset~=0,"test target unavailable")
    eng.scene.set_mesh(pedestal,asset,{color={1,1,1,1}})
end
"""
        for cycle in (1,2):
            source="bell" if cycle==1 else "wisp"
            shutil.copy2(ROOT/GAME/f"assets/{source}.glb",extra)
            (fixture/"missions/day_01.lua").write_text(newcode.replace("run.progress>=2",f"run.progress>={cycle}"))
            package(binary.parent,stage,False,fixture)
            package(web_build,site,True,fixture)
            if cycle==1:
                native_hash=digest(stage/binary.name);wasm_hash=digest(site/"lantern.wasm");first_art=digest(extra)
            else:
                assert digest(stage/binary.name)==native_hash and digest(site/"lantern.wasm")==wasm_hash
                assert digest(extra)!=first_art
            test=stage/GAME/"probe.lua"
            test.write_text("""
function playtest_frame(f)
    local g=game.state
    if g.space==1 then
        g.z=0;g.room.players[1].z=0
        if not g.room.instances[1].done then Hall.objective(g.room,g.room.players[1],MissionPacks) end
    end
    if f==15 then g.playtest_done=true end
end
function playtest_verify()
    eng.test.assert_true(eng,World.prepared[1] and game.state.awards==1,"Installed pack ran")
    eng.test.assert_eq(eng,game.state.room.instances[1].progress,"""+str(cycle)+""","Changed objective ran")
end
""")
            subprocess.run([str(stage/binary.name),"--save",str(save),"--headless","--test","probe.lua"],
                           cwd=base,check=True)
        manifest=json.loads((site/"manifest.json").read_text())
        late=(GAME/"missions/test-target.glb").as_posix()
        assert late in manifest["missions"]["1"] and late not in manifest["files"]
        with website(site) as url, sync_playwright() as pw:
            with pw.chromium.launch_persistent_context(str(base/"browser"),executable_path=shutil.which("chromium"),
                    args=["--no-sandbox","--use-angle=swiftshader","--enable-unsafe-swiftshader"],
                    viewport={"width":640,"height":420}) as browser:
                page=browser.new_page()
                requests=[]
                def asset(route):
                    requests.append(route.request.url)
                    if len(requests)==1:route.fulfill(status=503,body="")
                    else:route.continue_()
                page.route("**/missions/test-target.glb",asset)
                open_game(page,url);assert not requests
                page.locator("#enter").click()
                expect_text(page,"#hint","retry")
                expect_text(page,"#hint","objective")
                assert len(requests)==2
                page.keyboard.down("w");page.wait_for_timeout(2200);page.keyboard.up("w")
                for _ in range(2):
                    page.keyboard.down("e");page.wait_for_timeout(220);page.keyboard.up("e");page.wait_for_timeout(220)
                expect_text(page,"#hint","Ornament earned")
                page.wait_for_function("Module.FS.analyzePath('/profile/saves/lantern_a.engb').exists")
                page.evaluate("() => new Promise((yes,no)=>Module.FS.syncfs(false,e=>e?no(e):yes()))")
            with pw.chromium.launch_persistent_context(str(base/"browser"),executable_path=shutil.which("chromium"),
                    args=["--no-sandbox","--use-angle=swiftshader","--enable-unsafe-swiftshader"],
                    viewport={"width":640,"height":420}) as reopened:
                page=reopened.new_page();open_game(page,url)
                expect_text(page,"#weaponName","Saved ornament")
        print("External script and art changed; native and WASM hashes stayed identical. On-demand retry and persistent ornament passed.")


if __name__=="__main__":
    parser=argparse.ArgumentParser()
    parser.add_argument("--binary",type=Path,required=True);parser.add_argument("--web-build",type=Path,required=True)
    args=parser.parse_args();verify(args.binary.resolve(),args.web_build.resolve())
