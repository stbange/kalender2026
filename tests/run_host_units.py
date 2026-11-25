"""Give the C units a private-CA TLS echo peer on loopback."""

import socketserver
import ssl
import subprocess
import sys
import tempfile
import threading
from network_test import test_certificate

with tempfile.TemporaryDirectory() as tmp:
    cert, key = test_certificate(tmp, "DNS:localhost,IP:127.0.0.1")
    ctx = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
    ctx.load_cert_chain(cert, key)

    class Echo(socketserver.BaseRequestHandler):
        def handle(self):
            try:
                with ctx.wrap_socket(self.request, server_side=True) as sock:
                    data = sock.recv(16)
                    if data:
                        sock.sendall(data)
            except OSError:
                pass  # Clients deliberately refuse the wrong identity or trust anchor.

    with socketserver.ThreadingTCPServer(("127.0.0.1", 0), Echo) as server:
        server.daemon_threads = True
        thread = threading.Thread(target=server.serve_forever, daemon=True)
        thread.start()
        try:
            subprocess.run([*sys.argv[1:], str(cert), str(server.server_address[1])], check=True)
        finally:
            server.shutdown()
            thread.join()
