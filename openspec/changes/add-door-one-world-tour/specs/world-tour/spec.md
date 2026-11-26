## ADDED Requirements

### Requirement: Two routes inside Door 1

Players SHALL be able to select the original vent route or a generated tour on the starting rooftop.

#### Scenario: Three destinations in order

- **WHEN** the crew selects World Tour and clears successive sectors
- **THEN** they visit Los Angeles, Luna and Bettinghausen in that order and can earn the Door 1 ornament

### Requirement: Shared generated geography

A fresh tour SHALL generate traversable courts, passages, cover and patrols from an authoritative seed. Themed landmarks SHALL remain recognizable across seeds.

#### Scenario: Late arrival

- **WHEN** a friend enters during the tour
- **THEN** the friend receives the same seed, current encounter and sector checkpoint as the crew

#### Scenario: Fresh departure

- **WHEN** everyone leaves and a new tour starts
- **THEN** a new seed varies the layouts while preserving the route order and landmarks

### Requirement: Readable enemy fire and damage

Patrols SHALL telegraph distinct ranged attacks, react to hits and animate defeats. Enemy bolts SHALL damage exposed players and transmit damage feedback to the hit player.

#### Scenario: Remaining exposed

- **WHEN** an unprotected player stays in a firing lane
- **THEN** bolts can deplete armor and hearts and the last hit returns the player to the checkpoint

#### Scenario: Different attackers

- **WHEN** a tour encounter contains a ground patrol, a courier and a heavy
- **THEN** the player can see and evade paired aimed shots, a spreading volley and a charged heavy salvo
