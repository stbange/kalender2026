# Shared rooms

## Purpose

Let a small group meet across desktop, phone and VR on their own Linux service, with a consistent view of friends, targets and mission activity.

## ADDED Requirements

### Requirement: Eight-player cross-platform rooms

The Linux service SHALL host up to eight simultaneous players per room. A shared invitation SHALL bring compatible Windows, Linux, Web, mobile Web and WebXR clients into the same room. A full room or incompatible game revision SHALL give the joining player an actionable message and preserve the existing session.

#### Scenario: The ninth player arrives

- **WHEN** eight clients occupy one room and a ninth tries to join
- **THEN** the ninth sees that the room is full, the original eight remain connected and the slot becomes available after a player leaves.

#### Scenario: Native and browser clients meet

- **WHEN** a native client and a browser client join with the same invitation and compatible content
- **THEN** each sees the other's avatar move and both see the same range target change after a throw over the live network.

### Requirement: Consistent shared interactions

The room service SHALL determine shared target state, hit counts, membership and mission progress for each active instance. Late joiners SHALL receive current state. Repeated delivery of one action SHALL change a shared score or objective at most once.

#### Scenario: Two throws land together

- **WHEN** two players hit the same target before it resets and one hit message is retried
- **THEN** one hit is credited for that target's active cycle, and a late arrival sees the same total and reset state as the original players.

### Requirement: Connection loss and rejoining

Clients SHALL indicate a lost connection, allow rejoining and reconcile against current room state. A disconnected player SHALL eventually release their slot. A service restart SHALL allow clients to join a fresh room while retaining locally saved mission completions.

#### Scenario: A phone resumes from sleep

- **WHEN** a phone returns after its connection expired while a friend continued playing
- **THEN** the player can rejoin an available slot, sees the current roster and targets, and appears once in the room.

### Requirement: User-operated Linux hosting

A release SHALL include a headless Linux room service, external endpoint configuration for clients and instructions to run it behind a TLS reverse proxy. A Pages client SHALL reach a public secure WebSocket endpoint on that host.

#### Scenario: Start the service on a Linux host

- **WHEN** an operator starts the supplied server package without a display and configures a reachable secure endpoint
- **THEN** two remote clients can join and exchange game events, and an endpoint outage produces a visible connection status with a retry action.
