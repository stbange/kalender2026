"""Play through a shared fixture over real WebSocket connections to the shipping service."""

import argparse
import contextlib
import os
from pathlib import Path
import signal
import socket
import socketserver
import ssl
import subprocess
import tempfile
import threading
import time

from websockets.sync.client import ClientConnection, connect


def free_port():
    with socket.socket() as sock:
        sock.bind(("127.0.0.1", 0))
        return sock.getsockname()[1]


@contextlib.contextmanager
def service(binary, root, fixture=False, clock=1798066800):
    port = free_port()
    args = [str(binary), "--root", str(root), "--serve", "--port", str(port)]
    if fixture:
        args.extend(
            [
                "--fixture",
                str(root / "tests/fixture" if fixture is True else fixture),
                "--test-clock",
                str(clock),
            ]
        )
    with subprocess.Popen(args, stdout=subprocess.PIPE, text=True) as proc:
        try:
            assert "listening" in proc.stdout.readline(), "room process failed to start"
            yield port
        finally:
            status = proc.poll()
            if status is not None:
                raise AssertionError(f"Room process exited during play with status {status}")
            if os.name == "nt":
                proc.terminate()
            else:
                proc.send_signal(signal.SIGTERM)
            proc.wait(timeout=8)


def test_identity(directory):
    """Issue a short-lived localhost certificate from an independent private root."""
    root = Path(directory)
    ca, ca_key = root / "ca.pem", root / "ca.key"
    cert, key = root / "room.pem", root / "room.key"
    request, extensions = root / "room.csr", root / "room.ext"

    def openssl(*args):
        subprocess.run(["openssl", *args], check=True, capture_output=True)

    openssl(
        "req",
        "-x509",
        "-newkey",
        "rsa:2048",
        "-nodes",
        "-days",
        "1",
        "-subj",
        "/CN=Hall test root",
        "-addext",
        "basicConstraints=critical,CA:TRUE",
        "-keyout",
        ca_key,
        "-out",
        ca,
    )
    openssl(
        "req",
        "-new",
        "-newkey",
        "rsa:2048",
        "-nodes",
        "-subj",
        "/CN=localhost",
        "-keyout",
        key,
        "-out",
        request,
    )
    extensions.write_text(
        "basicConstraints=critical,CA:FALSE\nkeyUsage=digitalSignature,keyEncipherment\n"
        "extendedKeyUsage=serverAuth\nsubjectAltName=DNS:localhost\n"
    )
    openssl(
        "x509",
        "-req",
        "-in",
        request,
        "-CA",
        ca,
        "-CAkey",
        ca_key,
        "-CAcreateserial",
        "-days",
        "1",
        "-extfile",
        extensions,
        "-out",
        cert,
    )
    # Exercise the same Windows-exported trust file on every native platform.
    ca.write_bytes(b"\r\n".join(ca.read_bytes().splitlines()) + b"\r\n")
    return cert, key, ca


@contextlib.contextmanager
def tls_proxy(port, directory):
    """Terminate TLS at the room boundary as the sample Caddy service does."""
    cert, key, ca = test_identity(directory)
    ctx = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
    ctx.load_cert_chain(cert, key)
    seen_hosts = []
    ctx.set_servername_callback(lambda sock, name, context: seen_hosts.append(name))

    class Relay(socketserver.BaseRequestHandler):
        def handle(self):
            def pipe(source, dest):
                try:
                    while data := source.recv(65536):
                        dest.sendall(data)
                except OSError:
                    pass
                with contextlib.suppress(OSError):
                    dest.shutdown(socket.SHUT_RDWR)

            try:
                with ctx.wrap_socket(self.request, server_side=True) as client:
                    with socket.create_connection(("127.0.0.1", port)) as upstream:
                        writer = threading.Thread(target=pipe, args=(client, upstream), daemon=True)
                        writer.start()
                        pipe(upstream, client)
                        writer.join(2)
            except OSError:
                pass

    # SDL_net and browser DNS can choose different loopback families for localhost.
    class IPv6Proxy(socketserver.ThreadingTCPServer):
        address_family = socket.AF_INET6

    with contextlib.ExitStack() as stack:
        proxy = stack.enter_context(socketserver.ThreadingTCPServer(("127.0.0.1", 0), Relay))
        proxies = [proxy]
        if socket.has_ipv6:
            with contextlib.suppress(OSError):
                proxies.append(stack.enter_context(IPv6Proxy(("::1", proxy.server_address[1]), Relay)))
        for listener in proxies:
            listener.daemon_threads = True
            thread = threading.Thread(target=listener.serve_forever, daemon=True)
            thread.start()
            stack.callback(thread.join)
            stack.callback(listener.shutdown)
        yield f"wss://localhost:{proxy.server_address[1]}", ca, seen_hosts


class HallConnection(ClientConnection):
    """Use the same engine channel prefix that the shipping peers use."""

    def send(self, message):
        super().send(b"\x01" + message.encode("utf-8"))

    def recv(self, timeout=None):
        data = super().recv(timeout=timeout)
        assert isinstance(data, bytes) and len(data) >= 2, "expected an engine binary frame"
        channel, message = data[0], data[1:].decode("utf-8")
        assert channel == (0 if message.startswith("S ") else 1)
        return message


def hello(url, room="friends", revision="last-launch-open-1", **kwargs):
    ws = connect(
        url,
        proxy=None,
        open_timeout=6,
        close_timeout=0.3,
        max_queue=None,
        create_connection=HallConnection,
        **kwargs,
    )
    ws.send(f"HELLO3 {revision} {room}")
    answer = ws.recv(timeout=5)
    return ws, answer


def snapshot(ws, predicate, timeout=8):
    end = time.monotonic() + timeout
    last = None
    while time.monotonic() < end:
        data = ws.recv(timeout=max(0.1, end - time.monotonic()))
        if not data.startswith("S "):
            continue
        lines = [line.split() for line in data.splitlines()]
        _, days, clock, hits, clears, wave = lines[0]
        state = dict(
            days=int(days),
            time=float(clock),
            hits=int(hits),
            clears=int(clears),
            wave=int(wave),
            players={},
            mobs={},
            targets={},
            seats={},
            events=[],
            latest=0,
            loads=[],
            mission_players={},
        )
        for row in lines[1:]:
            if row[0] == "I":
                state["latest"] = int(row[1])
            elif row[0] == "O":
                state["seats"][int(row[1])] = int(row[2])
            elif row[0] == "E":
                idx, t, code, owner, seat, seq, ball, tool, target, x, y, z, value = row[1:]
                state["events"].append(
                    dict(
                        id=int(idx),
                        time=float(t),
                        code=int(code),
                        owner=int(owner),
                        seat=int(seat),
                        seq=int(seq),
                        ball=int(ball),
                        weapon=int(tool),
                        target=int(target),
                        pos=(float(x), float(y), float(z)),
                        value=float(value),
                    )
                )
            elif row[0] == "P":
                _, idx, x, z, yaw, space, slow, weapon, award, progress, done = row
                state["players"][int(idx)] = dict(
                    x=float(x),
                    z=float(z),
                    yaw=float(yaw),
                    space=int(space),
                    award=int(award),
                    progress=int(progress),
                    done=int(done),
                )
            elif row[:3] == ["D", "1", "3"]:
                state["loads"].append(row[3:])
            elif row[:3] == ["D", "1", "2"]:
                state["mission_players"][int(row[3])] = int(row[6])
            elif row[0] == "T":
                state["targets"][int(row[1])] = float(row[2])
            elif row[0] == "M":
                state["mobs"][int(row[1])] = tuple(map(float, row[2:]))
        last = state
        if predicate(state):
            return state
    raise AssertionError(f"Snapshot condition timed out: {last}")


def walk(clients, start, end):
    distance = ((end[0] - start[0]) ** 2 + (end[1] - start[1]) ** 2) ** 0.5
    steps = max(1, int(distance / 0.17) + 1)
    for i in range(1, steps + 1):
        x, z = [a + (b - a) * i / steps for a, b in zip(start, end)]
        for ws in clients:
            ws.send(f"P {x:.3f} {z:.3f} 90")
        time.sleep(0.036)


def public_room(binary, root):
    with service(binary, root) as port, contextlib.ExitStack() as stack:
        url = f"ws://127.0.0.1:{port}"
        clients = []

        def join(room="friends", revision="last-launch-open-1"):
            ws, answer = hello(url, room, revision)
            stack.callback(ws.close)
            return ws, answer

        for seat in range(1, 9):
            ws, answer = join()
            assert answer == f"WELCOME {seat}"
            clients.append(ws)
        observer = clients[1]
        clients[0].send("F 1 1 0 .0094 -.99996")
        clients[0].send("F 1 1 0 .0094 -.99996")
        for ws in clients[:2]:
            s = snapshot(ws, lambda s: s["hits"] == 1)
            assert s["targets"][3] > s["time"] and s["wave"] == 1 and len(s["mobs"]) == 5
            assert len(s["players"]) == 8
            assert [e["code"] for e in s["events"]] == [1, 4]
            launch, bell = s["events"]
            assert launch["owner"] == bell["owner"] == 1
            assert launch["seq"] == bell["seq"] == 1 and bell["seat"] == s["seats"][1]
            assert bell["target"] == 3 and bell["id"] == s["latest"] and launch["ball"] == bell["ball"]
        assert join()[1] == "ERROR Room full"
        assert join(revision="earlier")[1].startswith("ERROR")
        isolated, answer = join("separate")
        assert answer == "WELCOME 1" and snapshot(isolated, lambda s: True)["hits"] == 0
        clients[7].close()
        snapshot(observer, lambda s: len(s["players"]) == 7)
        new, answer = join()
        assert answer == "WELCOME 8"
        joined = snapshot(new, lambda s: s["hits"] == 1)
        assert joined["wave"] == 1 and joined["latest"] == bell["id"]
        assert joined["seats"][8] != s["seats"][8]
        new.send("HELLO3 last-launch-open-1 friends")
        assert len(snapshot(new, lambda s: True)["players"]) == 8
        with tempfile.TemporaryDirectory() as tmp, tls_proxy(port, tmp) as (secure, cert, names):
            witness, answer = join("native")
            assert answer == "WELCOME 1"
            proc = subprocess.Popen(
                [
                    str(binary),
                    "--root",
                    str(root),
                    "--save",
                    tmp,
                    "--headless",
                    "--endpoint",
                    secure,
                    "--room",
                    "native",
                    "--ca",
                    str(cert),
                    "--frames",
                    "150",
                ]
            )
            try:
                snapshot(witness, lambda s: len(s["players"]) == 2, timeout=5)
                assert "localhost" in names, "TLS server name missing"
                assert proc.wait(timeout=15) == 0
                witness.send("P 0 17 122")
                snapshot(witness, lambda s: len(s["players"]) == 1 and s["players"][1]["yaw"] == 122)
                # A private CA is required, and trusting it does not allow the wrong host name.
                for url, trust in [
                    (secure, []),
                    (secure.replace("localhost", "127.0.0.1"), ["--ca", str(cert)]),
                ]:
                    args = [
                        str(binary),
                        "--root",
                        str(root),
                        "--save",
                        tmp,
                        "--headless",
                        "--connect",
                        url,
                        "--room",
                        "native",
                        "--frames",
                        "40",
                        *trust,
                    ]
                    with subprocess.Popen(args) as rejected:
                        while rejected.poll() is None:
                            assert len(snapshot(witness, lambda s: True)["players"]) == 1
                        assert rejected.returncode == 0
            finally:
                if proc.poll() is None:
                    proc.terminate()
                    proc.wait()
    print("Eight seats, ninth rejection, isolation, reconnect, shared bell and native TLS passed.")


def capacity(binary, root):
    with service(binary, root) as port, contextlib.ExitStack() as cleanup:
        url = f"ws://127.0.0.1:{port}"
        rooms = []
        for number in range(6):
            group = []
            for seat in range(1, 9):
                peer, welcome = hello(url, f"room-{number}")
                cleanup.callback(peer.close)
                assert welcome == f"WELCOME {seat}"
                group.append(peer)
            rooms.append(group)
        rooms[-1][0].send("F 1 1 0 .0094 -.99996")
        state = snapshot(rooms[-1][1], lambda s: s["hits"] == 1)
        assert len(state["players"]) == 8
        assert snapshot(rooms[0][0], lambda s: len(s["players"]) == 8)["hits"] == 0
    print("Six independent eight-player rooms fit on one engine listener.")


def coop(binary, root):
    with service(binary, root, True) as port, contextlib.ExitStack() as stack:
        clients = []
        for i in range(8):
            ws, answer = hello(f"ws://127.0.0.1:{port}", revision="lantern-2-fixture")
            stack.callback(ws.close)
            clients.append(ws)
            assert answer == f"WELCOME {i + 1}"
        a, b, watch = clients[:3]
        assert snapshot(watch, lambda s: len(s["players"]) == 8)["days"] == 24
        a.send("F 1 1 -.1592 .00796 -.98722")
        assert snapshot(watch, lambda s: s["hits"] == 1)["wave"] == 1
        walk([a, b], (0, 17), (-23, 17.5))
        a.send("ENTER 1")
        snapshot(watch, lambda s: s["players"][1]["space"] == 1)
        walk([a], (0, 5), (0, 2.5))
        a.send("USE")
        snapshot(watch, lambda s: s["players"][1]["progress"] == 1)
        b.send("ENTER 1")
        snapshot(b, lambda s: s["players"][2]["progress"] == 1)
        walk([b], (0, 5), (0, 2.5))
        b.send("USE")
        s = snapshot(watch, lambda s: s["players"][1]["done"] == 1)
        assert [s["players"][i]["award"] for i in (1, 2, 3)] == [1, 1, 0]
        walk([a, b], (0, 2.5), (0, 6.7))
        a.send("BACK")
        b.send("BACK")
        b.send("BACK")
        s = snapshot(watch, lambda s: all(p["space"] == 0 for p in s["players"].values()))
        assert s["wave"] == 2 and s["players"][1]["x"] == -20.5
        assert s["players"][3]["z"] == 17
    print("Day-24 hall, shared objective, late follower, spectator, ornaments and one return wave passed.")


def last_launch(binary, root):
    # A plain directory keeps the production catalog mounted. Only the local test clock is overridden.
    with (
        tempfile.TemporaryDirectory() as fixture,
        service(binary, root, Path(fixture), clock=1796079599) as port,
        contextlib.ExitStack() as stack,
    ):
        clients = []
        for seat in range(8):
            ws, answer = hello(f"ws://127.0.0.1:{port}", "last_launch")
            stack.callback(ws.close)
            assert answer == f"WELCOME {seat + 1}"
            clients.append(ws)
        walk(clients[:7], (0, 17), (-23, 17.5))
        for ws in clients[:7]:
            ws.send("ENTER 1")
        snapshot(clients[7], lambda s: sum(p["space"] == 1 for p in s["players"].values()) == 7)
        walk(clients[:2], (0, 5), (-8, -9))
        for ws in clients[:2]:
            ws.send("USE")
        for ws in clients[:2]:
            s = snapshot(ws, lambda s: s["players"][1]["progress"] == 2 and bool(s["loads"]))
            assert len(s["mission_players"]) == 7 and s["players"][8]["space"] == 0
        for ws in clients[:2]:
            ws.send("F 1 1 0 0 -1")
        snapshot(clients[7], lambda s: sum(s["mission_players"].values()) == 2)
        time.sleep(0.3)
        clients[0].send("F 2 1 0 0 -1")
        state = snapshot(clients[1], lambda s: s["mission_players"].get(1) == 0)
        assert state["mission_players"][2] == 1
        spectator = clients[7]
        spectator.send("F 1 1 -.1592 .00796 -.98722")
        shot = snapshot(spectator, lambda s: any(e["owner"] == 8 and e["code"] == 1 for e in s["events"]))
        assert shot["players"][8]["space"] == 0
        watch = shot["players"][8]
        walk([spectator], (watch["x"], watch["z"]), (-23, 17.5))
        spectator.send("ENTER 1")
        all_in = snapshot(spectator, lambda s: len(s["mission_players"]) == 8)
        assert all_in["days"] == 0 and all_in["players"][8]["progress"] == 2
    print("Eight real engine WebSocket clients shared the production mission and independent remotes.")


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("binary", type=Path)
    parser.add_argument("root", type=Path)
    args = parser.parse_args()
    public_room(args.binary.resolve(), args.root.resolve())
    coop(args.binary.resolve(), args.root.resolve())
    capacity(args.binary.resolve(), args.root.resolve())
    last_launch(args.binary.resolve(), args.root.resolve())
