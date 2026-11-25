## Why

The updated engine supplies multi-client WebSockets on desktop and Web. The hall can share this transport and retire its separate WebSocket library.

## What Changes

- Use engine peers, connection events and channel-framed binary packets in the hall client and Linux service.
- Keep invitation codes, room authority, late joins, score feedback and cooperative missions in the hall's external scripts.
- Keep verified TLS for native and Web clients and support the existing private-CA option.
- Publish matching game and server archives for the wire-format change.

## Capabilities

### New Capabilities

- `engine-room-networking`: engine transport for calendar rooms.

## Impact

Changes the engine pin, client and server network lifecycle, build and package dependencies, protocol fixtures, hosting instructions and release tests.
