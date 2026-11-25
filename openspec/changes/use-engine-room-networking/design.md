## Transport and room authority

The native client and the Linux room host use `eng_net_create`, `eng_net_host`, `eng_net_poll_event` and targeted sends. The Web build links the engine's Emscripten WebSocket backend. An accepted engine connection sends one hall greeting. Commands, join results and disconnect notices use the reliable channel. Periodic snapshots use the snapshot channel. Both arrive over the same ordered WebSocket connection.

The public engine multiplayer helper broadcasts a single set of avatar transforms to all connected peers. This service hosts multiple independent rooms. The Lua service retains room admission, catalog compatibility, authoritative movement, scores, visitor events and mission pockets. It addresses each snapshot by engine peer ID. Reusing a hall seat starts a new occupancy generation.

## Native secure invitations

At engine revision `5efdb46`, browser clients support WSS and the native client accepts plain WS. The native build adds an OpenSSL filter to the engine’s existing SDL3_net byte stream. The engine still opens the socket, frames WebSocket messages and dispatches events. The filter verifies certificates, uses the DNS identity or IP address, and supplies SNI for DNS hosts. The release includes the Windows CA bundle and accepts a private CA through `--ca`.

CMake applies the native extension in the build directory. A clean submodule remains pinned to the published engine commit. The Web build uses the published source directly. The native service retains its 48-connection capacity and eight-seat room limit.

## Migration and validation

Version 0.3.0 is a coordinated client and server upgrade. A client that cannot complete its greeting returns to solo, and the player can edit the address and retry. The existing connection, ornament and feedback saves remain readable. Validate via engine loopback, real room sockets, certificate acceptance and rejection, and a browser and native client sharing the same WSS endpoint.
