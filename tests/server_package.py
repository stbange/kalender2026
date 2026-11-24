"""Check the standalone Linux service from a directory outside its installation."""

import os
import sys
import tempfile
from pathlib import Path
from network_test import hello, service

root = Path(sys.argv[1]).resolve()
with tempfile.TemporaryDirectory() as tmp:
    os.chdir(tmp)
    with service(root / "lantern", root) as port:
        ws, reply = hello(f"ws://127.0.0.1:{port}")
        try:
            assert reply == "WELCOME 1"
        finally:
            ws.close()
print("Dedicated room archive accepted a client from a clean working directory.")
