# Hall snowplay

## Purpose

Give friends a repeatable shooting playground in the hall before the first mission and after returning from a shared expedition.

## ADDED Requirements

### Requirement: Five selectable snowball launchers

Players SHALL be able to switch among a quick Snowball Pistol, a three-pellet Flurry Fan, a rapid Snow Spinner, a bouncing Bankshot and a splash Snow Rocket. The selected tool SHALL change the shot behavior and appear on the HUD.

#### Scenario: Try the rack before Advent

- **WHEN** a player switches through all five tools and fires at the range
- **THEN** single, spread, rapid, bouncing and splash shots are available using desktop, mobile or headset controls.

### Requirement: Harmless seasonal visitors

A hall encounter SHALL include five slow-moving kinds of visitor with distinct silhouettes and movement. Contact SHALL apply a bounded, temporary movement slow. All players SHALL retain the ability to move, fire, use a portal and recover.

#### Scenario: Contact and recovery

- **WHEN** a visitor brushes a player and the player moves away
- **THEN** the movement slow expires, and the player can continue without losing health or respawning.

### Requirement: One encounter per hall visit cycle

A room SHALL start one arrival encounter and one return encounter when the first participating player comes back from a mission instance. Friends joining late, repeated network events and other participants returning from that same run SHALL observe the existing encounter. A practice bell SHALL let the group deliberately repeat a finished encounter without any mission installed.

#### Scenario: Test before any mission has shipped

- **WHEN** friends enter a fresh room, clear the visitors and ring the practice bell
- **THEN** one new wave appears in the hall and all connected friends see the same visitors.

#### Scenario: Return from one shared run

- **WHEN** two players return separately from the same run and one reconnects
- **THEN** the hall starts exactly one return wave for that run.
