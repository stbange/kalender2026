"""Copy the PE import closure supplied by MSYS2 next to the Windows game."""

from pathlib import Path
import re
import shutil
import subprocess
import sys

out, prefix = (Path(arg).resolve() for arg in sys.argv[1:])
available = {p.name.lower(): p for p in (prefix / "bin").glob("*.dll")}
pending = [out / "lantern.exe"]
copied = set()
while pending:
    path = pending.pop()
    table = subprocess.check_output(["objdump", "-p", str(path)], text=True, errors="replace")
    for name in re.findall(r"DLL Name:\s*(\S+)", table, re.I):
        key = name.lower()
        if key in copied or key not in available:
            continue
        source = available[key]
        shutil.copy2(source, out / source.name)
        copied.add(key)
        pending.append(source)
assert "sdl3.dll" in copied and any(n.startswith("libssl") for n in copied), copied
print("Packaged Windows libraries", ", ".join(sorted(copied)))
