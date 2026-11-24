# Festive hall

## Purpose

Give friends a first-person meeting place where they can find a numbered door, recognize each other and play at the snowball range on any supported device.

## ADDED Requirements

### Requirement: A walkable hall with twenty-four identifiable doors

The hall SHALL contain exactly 24 numbered portal entrances, one for each day. A player SHALL be able to walk from spawn to every threshold. The hall SHALL visibly combine low-poly 3D objects, billboard sprites and voxel objects in a Christmas setting.

#### Scenario: Find the last door before Advent begins

- **WHEN** a player enters on 30 November 2026 and follows the numbered galleries
- **THEN** they can reach and read every number from 01 through 24, including 24, while walls and closed doors stop their movement.

### Requirement: Door states readable in the world

Each entrance SHALL show its number and a distinct shape, inscription or icon for its state. A player SHALL be able to distinguish a future date, an available mission, a due mission awaiting delivery and their own completed mission. The newest due door SHALL be identifiable from the central aisle.

#### Scenario: Inspect neighboring portals

- **WHEN** days 06 and 07 are due, the player has cleared 06, the mission for 07 is installed and 08 opens tomorrow
- **THEN** door 06 bears a completion ornament, door 07 invites entry and door 08 displays its opening date, even with audio muted and color cues ignored.

### Requirement: Shared snowball range

The range SHALL be playable throughout the calendar, including before 1 December. A thrown snowball hitting an active range target SHALL produce a visible target reaction, an audible bell and one shared hit. Friends SHALL be able to play alongside one another without player damage.

#### Scenario: Both players see the bell ring

- **WHEN** a player hits an active bell while a second player watches and a third stands nearby
- **THEN** both observers see the same bell react, the shared hit total rises once and the nearby player can keep moving.

### Requirement: First-person input on each target

The client SHALL support keyboard and mouse on desktop, automatically selected touch controls on mobile Web, and immersive first-person stereo with tracked head and controller input on Meta Quest 3. Each input mode SHALL support moving, aiming, throwing a snowball and crossing a doorway.

#### Scenario: Reach the range on a phone

- **WHEN** a player opens the Web client on iPhone Safari or Android Chrome and walks and looks at the same time
- **THEN** the left movement control, right-side look gesture and throw button work without scrolling the page, including after a change of orientation.

#### Scenario: Use the hall in a headset

- **WHEN** a player starts an immersive session on Quest 3, turns, aims with a controller, and subsequently exits immersive mode
- **THEN** the hall renders from both tracked eyes at human scale, the target responds to the throw, and the flat browser view resumes in the same live room.
