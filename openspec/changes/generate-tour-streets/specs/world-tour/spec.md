## ADDED Requirements

### Requirement: Generated passages

Fresh tours SHALL vary the walkable connections between streets. All three sector exits and every defender spawn SHALL remain reachable.

#### Scenario: Compare fresh departures

- **WHEN** the last player leaves and the crew starts a fresh tour
- **THEN** the new seed can produce a different network of actual passages

#### Scenario: Replay a seed

- **WHEN** a client receives the same seed and destination as the room
- **THEN** its floors, walls, passages and sector exits match the authoritative layout
