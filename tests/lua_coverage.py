"""Count executable lines reported by the Lua 5.1 compiler, including untested scripts."""
import os,re,shutil,subprocess,sys,tempfile
from pathlib import Path
root=Path(__file__).resolve().parents[1]
os.chdir(root)
lua=shutil.which("lua5.1") or "lua"
compiler=shutil.which("luac5.1") or "luac"
with tempfile.TemporaryDirectory() as tmp:
    data=Path(tmp)/"lines"
    subprocess.run([lua,"tests/unit.lua",str(data)],check=True)
    hits={tuple(line.rsplit(" ",1)) for line in data.read_text().splitlines()}
covered=total=0
for path in sorted((root/"games/kalender2026").rglob("*.lua")):
    rel=path.relative_to(root).as_posix()
    if "/tests/" in rel: continue
    code=subprocess.check_output([compiler,"-l","-p",str(path)],text=True)
    active={m[1] for m in re.finditer(r"^\s*\d+\s+\[(\d+)\]\s+\w+",code,re.M)}
    seen={n for n in active if (rel,n) in hits}
    print(f"{rel}: {len(seen)}/{len(active)} executable lines", "missing", ",".join(sorted(active-seen,key=int)))
    total+=len(active);covered+=len(seen)
pct=100*covered/total
print(f"First-party Lua unit line coverage: {pct:.2f}%")
sys.exit(pct<95)
