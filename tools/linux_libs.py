"""Bundle SDL if the host used shared SDL, and let the dynamic loader find it beside the game."""

from pathlib import Path
import shutil
import subprocess
import sys

out = Path(sys.argv[1]).resolve()
exe = out / "lantern"
dependencies = subprocess.check_output(["ldd", str(exe)], text=True)
for line in dependencies.splitlines():
    fields = line.split()
    if fields and fields[0].startswith("libSDL3") and len(fields) >= 3:
        shutil.copy2(Path(fields[2]).resolve(), out / fields[0])
