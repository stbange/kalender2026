## ADDED Requirements

### Requirement: Run-and-gun encounters

Day 1 SHALL provide faster movement, visible ranged attacks, cover, quick kicks and floor-impact rocket splash in solo and live rooms.

#### Scenario: Strafe after the tell

- **WHEN** a player moves sideways after a patrol aims its weapon
- **THEN** its bolt continues toward the original aim point and can miss

#### Scenario: Pick a finisher

- **WHEN** a player kicks a frozen grunt at close range
- **THEN** it shatters and the room replicates the result

#### Scenario: Aim at the floor

- **WHEN** a rocket lands on the floor beside two grunts within splash range
- **THEN** an exposed grunt takes blast damage and a solid freight crate shields a grunt behind it

### Requirement: Supplies and access readers

Day 1 SHALL keep health and armor claims personal and share access cards across the room.

#### Scenario: Supplies for two friends

- **WHEN** two injured players walk over the same medkit
- **THEN** each can collect it once and a player at full health can leave it for later

#### Scenario: Run the reader

- **WHEN** one friend collects the access card and another uses its reader
- **THEN** the mission advances even while patrols remain
