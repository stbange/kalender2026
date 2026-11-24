"""Prove that a previously untested content pack can fail the Lua release gate."""

from pathlib import Path
import shutil
import subprocess
import sys
import tempfile

root = Path(__file__).resolve().parents[1]
with tempfile.TemporaryDirectory() as directory:
    temp = Path(directory)
    shutil.copytree(root / "tests", temp / "tests")
    shutil.copytree(root / "games/kalender2026/scripts", temp / "games/kalender2026/scripts")
    pack = temp / "games/kalender2026/missions"
    pack.mkdir()
    (pack / "unloaded.lua").write_text("local n=0\n" + "n=n+1\n" * 100 + "return n\n")
    result = subprocess.run(
        [sys.executable, str(temp / "tests/lua_coverage.py")], capture_output=True, text=True
    )
    assert result.returncode == 1 and "unloaded.lua: 0/" in result.stdout, result.stdout + result.stderr
print("An untested mission counts in the denominator and fails the 95% Lua gate.")
