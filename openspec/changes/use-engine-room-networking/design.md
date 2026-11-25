## Transport and room authority

The native client and the Linux room host use `eng_net_create`, `eng_net_host`, `eng_net_poll_event` and targeted sends. The Web build links the engine's Emscripten WebSocket backend. An accepted engine connection sends one hall greeting. Commands, join results and disconnect notices use the reliable channel. Periodic snapshots use the snapshot channel. Both arrive over the same ordered WebSocket connection.

The public engine multiplayer helper broadcasts a single set of avatar transforms to all connected peers. This service hosts multiple independent rooms. The Lua service retains room admission, catalog compatibility, authoritative movement, scores, visitor events and mission pockets. It addresses each snapshot by engine peer ID. Reusing a hall seat starts a new occupancy generation.

## Native secure invitations

Engine revision `b0c1f7e` provides the native SDL3_net stream, BearSSL TLS 1.2 client, certificate and hostname verification, and WebSocket framing. It reads the native operating system's roots. The hall passes the optional `--ca` PEM to each engine peer through `eng_net_set_ca_pem`. The browser uses its own trust store and the engine's Emscripten WebSocket backend.

Both builds compile the published engine source directly. The native build sets its peer capacity to 48 so one service can host six independent eight-seat rooms.

## Migration and validation

Version 0.3.0 is a coordinated client and server upgrade. A client that cannot complete its greeting returns to solo, and the player can edit the address and retry. The existing connection, ornament and feedback saves remain readable. Validate via engine loopback, real room sockets, certificate acceptance and rejection, and a browser and native client sharing the same WSS endpoint.
