# Advent missions

## Purpose

Make the December 2026 calendar predictable for everyone in a room and give independent mission packs a consistent entrance, co-op session, return path and completion record.

## ADDED Requirements

### Requirement: Cumulative Warsaw calendar

A room SHALL use a common calendar derived from its host device clock and Europe/Warsaw midnight. Zero days are due before 1 December 2026. Exactly one additional day becomes due on each date through 24 December 2026. All 24 stay due thereafter. The room SHALL refresh the calendar across midnight and after sleep or reconnect.

#### Scenario: A door opens while friends are in the hall

- **WHEN** host time passes from 30 November 2026 at 22:59:59 UTC to 23:00:00 UTC
- **THEN** the due count changes from zero to one for connected players without a restart, including a player whose browser is in a different time zone.

#### Scenario: Catch up after Christmas

- **WHEN** a player first connects on 24 December, on 25 December or in January 2027
- **THEN** all 24 days are due regardless of attendance or previous completions.

### Requirement: Walk into a delivered mission

A numbered portal SHALL admit a player when its date is due and the matching mission pack is ready. Crossing its threshold SHALL enter the day's mission. During open playtesting, a valid installed pack SHALL also admit players before its date. Clients and the room service SHALL apply the same rule to every installed day. With playtesting disabled, a future door SHALL block entry. A due door with a missing or unreadable pack SHALL show a content status and keep the player safely in the hall.

#### Scenario: Play an installed mission early

- **WHEN** open playtesting is enabled before December and only days 01 and 19 have valid installed packs
- **THEN** the hall shows two playable doors, players can walk into either one in solo or a shared room, and the other 22 doors stay closed.

#### Scenario: The first mission arrives independently

- **WHEN** day 01 is due and its pack changes from pending to a valid published revision
- **THEN** a client and host using that revision admit walking players to mission 01, while the other 23 bindings keep their original day IDs.

#### Scenario: A mission download fails during entry

- **WHEN** an eligible player reaches a doorway and the required pack fails to load
- **THEN** they see a retry message in the hall, retain previous progress, and can enter normally after a successful retry.

### Requirement: Follow a friend or stay in the hall

Players entering the same active day in the same room SHALL share one co-op mission and its current objective state. Other players SHALL remain free to stay in the hall or choose another available day. Leaving a mission SHALL return that player to the originating doorway on the hall side.

#### Scenario: Three friends choose different paths

- **WHEN** one friend enters day 01, a second follows after the first has advanced its objective and a third stays by the tree
- **THEN** the first two share the current mission state, the third keeps exploring the hall, and either participant can return independently without resetting the other's run.

### Requirement: Durable personal completion

Finishing a real mission SHALL award one ornament to each participating player. The native and browser clients SHALL retain earned ornaments for that device across restarts. A replay, duplicate completion message or interrupted save SHALL preserve previously earned progress.

#### Scenario: Replay and restart

- **WHEN** two players finish day 01, receive its completion twice, leave, restart their clients and revisit the hall
- **THEN** each sees exactly one day 01 ornament, the hall-only spectator's collection is unchanged and everyone can replay the available mission.
