## ADDED Requirements

### Requirement: Intentional mobile firing

The mobile Web client SHALL turn the camera on a first drag and SHALL reserve firing on the look surface for a nearby double-tap.

#### Scenario: Look around

- **WHEN** a player touches, holds or swipes the open screen once
- **THEN** movement of that finger adjusts the camera and the game submits zero throws.

#### Scenario: Shoot while moving and aiming

- **WHEN** the player quickly taps the same area twice while the movement stick is held
- **THEN** the second press starts firing the equipped snowcaster.
- **AND** holding and dragging that second contact continues firing at the weapon’s cadence while turning the camera.
- **AND** lifting it stops that source of fire.

#### Scenario: Use the Fire button

- **WHEN** a player presses the dedicated Fire button
- **THEN** it responds on its first press and continues to operate independently of the look finger.

#### Scenario: Interrupt a gesture

- **WHEN** a gesture is canceled or the player leaves the game view
- **THEN** returning to play requires a fresh double-tap to fire from the look area.
