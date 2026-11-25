## ADDED Requirements

### Requirement: Read the outcome of a shot

Day 1 SHALL resolve direct fire against the nearest enemy in the aiming ray. The shooter and nearby friends SHALL see the confirmed reaction. Only the shooter SHALL receive the personal hit marker. The mission SHALL honor the existing feedback settings.

#### Scenario: Shoot a rooftop usher

- **WHEN** one friend shoots through an usher before another friend at the back of the group has fired
- **THEN** the crew sees the usher recoil, only the shooter receives the hit confirmation, and a clear produces a separate defeat cue.

#### Scenario: Read enemy movement and armor

- **WHEN** an enemy walks, skates, hovers, freezes or takes a shot against armor
- **THEN** its pose or silhouette reflects that state. A deflection has a metallic cue and preserves the armored target's health.

#### Scenario: Aim on a phone or headset

- **WHEN** a player drags once on the look area or holds a controller trigger
- **THEN** the drag only aims, the held trigger repeats direct fire, and feedback leaves the camera under player control.
