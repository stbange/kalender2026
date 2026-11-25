# Make the range and galleries respond

## ADDED Requirements

### Requirement: A brass bell that swings and settles

The hall SHALL show the bell’s physical response and reset state throughout a scored cycle.

#### Scenario: A second throw arrives during the reset

- **WHEN** a confirmed hit begins a bell’s existing 1.2 s reset interval
- **THEN** the client SHALL animate its tilt from 55° through a damped overshoot to an 18° resting tilt over 320 ms. Hold the resting tilt until the reset time, then restore upright. In Reduced motion use two still poses.

### Requirement: Hear which bell rang

The hall SHALL let listeners locate a scored bell in the gallery.

#### Scenario: Two outer bells ring in the same snapshot

- **WHEN** one or more bells accept hits in the hall
- **THEN** the client SHALL play one world-positioned voice per struck bell at its existing centre with a 1.5 m near and 18 m far distance. Assign C5, D5, E5, G5 and A5 left to right. Keep a visual swing at each source.

### Requirement: A readable shared bell tally

The hall SHALL draw attention to the shared count at the moment it changes.

#### Scenario: A teammate rings two bells

- **WHEN** the shared range score increases after the room baseline
- **THEN** the client SHALL set the true number immediately and emphasize it once with a 105% outline for 120 ms. Merge changes arriving in the same frame into one emphasis regardless of scorer.

### Requirement: Carpet and stone underfoot

The hall SHALL let the player hear the surface actually underfoot.

#### Scenario: The player walks off the carpet

- **WHEN** the local player completes 1.8 m of actual walking displacement in the hall
- **THEN** the client SHALL play a muffled cloth step on either woven aisle or a short tap on the stone. Cycle three quiet variants per surface, alternate feet and reset distance on teleports.

### Requirement: Movement in the mitten

The hall SHALL tie optional mitten movement to actual walking distance.

#### Scenario: The player stops after a short strafe

- **WHEN** the flat-screen player walks far enough to enter a new stride
- **THEN** the client SHALL shift the idle snowcaster by at most 0.8 cm on the stride and settle within 120 ms of stopping. Blend down while firing. Keep the horizon and the tracked hand fixed.

### Requirement: A quiet knock for a sealed door

The hall SHALL acknowledge a deliberate try at a future door.

#### Scenario: A player tries tomorrow’s door

- **WHEN** the player intentionally uses a future door at its interaction threshold
- **THEN** the client SHALL give one soft 75 ms wood knock and tilt only its small wreath by 4° for 120 ms. Keep the existing date in view. Debounce each door for 900 ms.

### Requirement: An invitation after the last visitor

The hall SHALL draw attention to the practice bell after the last clear.

#### Scenario: The final visitor leaves and a friend joins

- **WHEN** the last active visitor of the wave is confirmed cleared while the player is in the hall
- **THEN** the client SHALL lift an outlined bell symbol above the practice spot for 900 ms and play a quiet two-note cadence lasting 240 ms. Keep the existing persistent invitation after the accent ends.

### Requirement: A practice bell answers the group

The hall SHALL acknowledge one accepted practice restart for the group.

#### Scenario: Two friends ring for a new wave

- **WHEN** the room accepts a practice restart after all visitors have cleared
- **THEN** the client SHALL swing a small bell symbol at the practice spot for 220 ms and play one low answering note to nearby players. Use one accepted practice event per wave.

### Requirement: Midnight in the hall

The hall SHALL mark a newly due date accurately for friends already present.

#### Scenario: Midnight arrives with a pack still pending

- **WHEN** the common due count advances by one at Warsaw midnight during an uninterrupted visit
- **THEN** the client SHALL play one 300 ms celesta phrase and show “Door DD due” for 1.5 s, appending its actual availability. Seed silently on entry or resume and show only the current door if the clock skips days.
