## ADDED Requirements

### Requirement: Engine transport for room traffic

The client and room service SHALL exchange hall commands, replies and snapshots through the engine WebSocket API. Room state SHALL be sent only to members of its room. A player SHALL be able to leave, rejoin, or return to solo after a failed connection.

#### Scenario: Two rooms share a listener

- **WHEN** eight players occupy a room and another room has independent activity
- **THEN** each group SHALL see only its own state, and a ninth player requesting the full room SHALL receive the capacity message.

#### Scenario: Mixed-platform secure invite

- **WHEN** a browser and a native player enter the same secure invite
- **THEN** they SHALL see the same confirmed gameplay state. Native clients SHALL validate the service identity and certificate chain, including an explicitly supplied private CA.

#### Scenario: Protocol mismatch

- **WHEN** the peer rejects the handshake or never acknowledges it
- **THEN** the client SHALL return to solo with an actionable message and permit another connection.
