"""Stage an editable client or server distribution. Use the same content paths on Web and native."""

import argparse
import hashlib
import json
import shutil
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
GAME = Path("games/kalender2026")


def copy(src, dst):
    dst.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(src, dst)


def web_recovery(out, paths):
    """An independently addressable copy of the startup files, in manifest order."""
    data = bytearray()
    offsets = [0]
    for path in paths:
        data.extend((out / path).read_bytes())
        offsets.append(len(data))
    digest = hashlib.sha256(data).hexdigest()
    name = f"hall-startup-{digest[:20]}.bin"
    (out / name).write_bytes(data)
    return {"file": name, "offsets": offsets}


def package(build, out, web, fixture=None, server=False):
    if server and web:
        raise ValueError("The dedicated service is a native executable")
    out.mkdir(parents=True, exist_ok=True)
    bootstrap = []

    def stage(src, rel):
        copy(src, out / rel)
        bootstrap.append(rel.as_posix())

    for folder in ("lua/eng",) if server else ("shaders", "lua/eng", "assets/shared/fonts"):
        for f in sorted((ROOT / "engine" / folder).rglob("*")):
            if f.is_file():
                stage(f, f.relative_to(ROOT))
    src = ROOT / GAME
    catalog_path = Path("missions/catalog.json")
    catalog = json.loads(
        ((fixture if fixture and (fixture / catalog_path).is_file() else src) / catalog_path).read_text()
    )
    client_assets = {Path(item) for mission in catalog["missions"] for item in mission.get("files", [])}
    for f in sorted(src.rglob("*")):
        rel = f.relative_to(src)
        if server and (
            rel in client_assets
            or rel.parts[0] in ("assets", "shaders")
            or rel.as_posix()
            in (
                "scripts/world.lua",
                "scripts/main.lua",
                "scripts/feedback.lua",
                "scripts/visitors.lua",
                "scripts/lamps.lua",
            )
        ):
            continue
        if f.is_file() and rel.parts[0] not in ("tests", "saves") and f.suffix != ".engb":
            stage(f, GAME / rel)
    if fixture:
        for f in sorted(fixture.rglob("*")):
            if f.is_file() and not (server and f.relative_to(fixture) in client_assets):
                stage(f, GAME / f.relative_to(fixture))
    groups = {}
    for mission in catalog["missions"]:
        paths = []
        for item in mission.get("files", []):
            if server:
                continue
            rel = Path(item)
            if rel.is_absolute() or ".." in rel.parts or "\\" in item or not (out / GAME / rel).is_file():
                raise ValueError(f"Invalid mission file {item!r}")
            paths.append((GAME / rel).as_posix())
        groups[str(mission["day"])] = paths
    deferred = {path for paths in groups.values() for path in paths}
    required = {
        (GAME / "missions/catalog.json").as_posix(),
        *((GAME / m["script"]).as_posix() for m in catalog["missions"]),
    }
    if deferred & required:
        raise ValueError("Catalog and entry scripts must be available at startup")
    stage(ROOT / "server.json", Path("server.json"))
    for name in ("LICENSE", "CREDITS.md", "README.md"):
        if (ROOT / name).is_file():
            copy(ROOT / name, out / name)
    for folder in ("licenses", "hosting", "docs"):
        if (ROOT / folder).is_dir():
            shutil.copytree(ROOT / folder, out / folder, dirs_exist_ok=True)
    copy(ROOT / "engine/THIRD_PARTY_NOTICES.md", out / "licenses/ENGINE-NOTICES.md")
    copy(ROOT / "engine/LICENSE", out / "licenses/engine-MIT.txt")
    if web:
        shutil.copytree(ROOT / "web", out, dirs_exist_ok=True)
        for file in ("lantern.js", "lantern.wasm"):
            copy(build / file, out / file)
        entries = [(GAME / m["script"]).as_posix() for m in catalog["missions"]]
        files = sorted(set(bootstrap) - deferred - set(entries))
        index = out / "index.html"
        loader_version = hashlib.sha256((out / "hall.js").read_bytes()).hexdigest()[:16]
        index.write_text(index.read_text().replace('src="hall.js"', f'src="hall.js?v={loader_version}"'))
        (out / "manifest.json").write_text(
            json.dumps(
                {
                    "files": files,
                    "recovery": web_recovery(out, files),
                    "entries": entries,
                    "missions": groups,
                },
                separators=(",", ":"),
            )
        )
        (out / ".nojekyll").touch()
    else:
        exe = next(
            (
                p
                for p in (
                    build / "lantern",
                    build / "lantern.exe",
                    build / "Release/lantern.exe",
                )
                if p.is_file()
            ),
            None,
        )
        if exe is None:
            raise FileNotFoundError("lantern binary")
        copy(exe, out / exe.name)
        for dll in sorted(exe.parent.glob("*.dll")):
            copy(dll, out / dll.name)
    for file in out.rglob("*"):
        if file.is_dir():
            file.chmod(0o755)
        elif file.name in ("lantern", "lantern.exe"):
            file.chmod(0o755)
        else:
            file.chmod(0o644)


if __name__ == "__main__":
    p = argparse.ArgumentParser()
    p.add_argument("--build", type=Path, required=True)
    p.add_argument("--out", type=Path, required=True)
    p.add_argument("--web", action="store_true")
    p.add_argument("--fixture", type=Path)
    p.add_argument("--server", action="store_true")
    a = p.parse_args()
    package(a.build, a.out, a.web, a.fixture, a.server)
