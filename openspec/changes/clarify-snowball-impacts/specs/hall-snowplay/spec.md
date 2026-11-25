# Make each snowball impact legible

## ADDED Requirements

### Requirement: Personal hit mark

The hall SHALL acknowledge a surviving visitor hit privately for its thrower.

#### Scenario: Two friends fire at different targets

- **WHEN** the local player’s snowball takes HP off a visitor who remains in play
- **THEN** the client SHALL show four outlined inward ticks around a clear centre for 90 ms on the first frame with a confirmed result. In stereo, place the mark at the contact point. Only the thrower gets this mark.

### Requirement: Visitor flinch

The hall SHALL make a surviving hit visible on the visitor’s body.

#### Scenario: A snowman takes its first pistol hit

- **WHEN** a visible visitor takes a confirmed hit and survives
- **THEN** the client SHALL lean its existing model up to 6° away from the impact and return to its walking pose over 110 ms. Keep its feet and collision centre on their original path.

### Requirement: Powder at the point of contact

The hall SHALL locate a hit on the struck surface.

#### Scenario: A visitor crosses the line of fire

- **WHEN** a confirmed snowball strikes a visitor or bell
- **THEN** the client SHALL emit five pale snow flecks from the reported contact point for 140 ms. An impact seen edge-on must still have a visible origin.

### Requirement: Soft hit sound for the thrower

The hall SHALL give a surviving hit its own short sound.

#### Scenario: A fan connects with two visitors

- **WHEN** an owned shot hits a visitor who stays on their feet
- **THEN** the client SHALL play one quiet packed-snow thup from three loose samples, with ±4% pitch variation. Merge hits from the same fan trigger within 70 ms.

### Requirement: A distinct finishing mark

The hall SHALL distinguish a finishing shot from an ordinary hit by shape.

#### Scenario: A rocket clears two visitors

- **WHEN** a confirmed owned shot reduces a visitor to zero HP
- **THEN** the client SHALL replace the ordinary ticks with one open diamond for 150 ms. A single splash that clears several visitors produces one finish mark for that trigger.

### Requirement: Visible Snow Rocket burst

The hall SHALL show the area reached by an actual rocket detonation.

#### Scenario: A rocket splashes near the range

- **WHEN** a Snow Rocket detonates on a confirmed contact
- **THEN** the client SHALL expand a broken ring of eight powder puffs from the impact to the active splash radius over 180 ms. The released tuning gives a 3.4 m radius.

### Requirement: Bankshot bounce ticks

The hall SHALL mark the point where a Bankshot changes direction.

#### Scenario: The third bounce meets a corner

- **WHEN** a Bankshot reflects off a simulated boundary with bounces remaining
- **THEN** the client SHALL leave a 0.12 m snow dash for 100 ms and play one short pitched tok at the contact. Use three descending pitches for the first, second and third bounces.

### Requirement: A snow mark for a missed shot

The hall SHALL show where a missed shot really ended.

#### Scenario: A shot reaches the bare floor

- **WHEN** an ordinary snowball ends on the simulated wall, floor or ceiling
- **THEN** the client SHALL place a flat 0.14 m snow stamp on that plane for 600 ms. Use at most eight stamps per client and keep projected marks off arches and noncolliding props.

### Requirement: Who hit what and where

The hall SHALL deliver enough confirmed contact information to identify its cause.

#### Scenario: A fan and a bell hit overlap

- **WHEN** the rules resolve a bounce, boundary impact, bell hit, visitor hit or rocket burst
- **THEN** the hall SHALL publish an ordered presentation record with the accepted shot’s owner, trigger sequence, projectile, contact position and result. Bound the recent history to 32 records. Solo supplies the same facts directly.

### Requirement: Quiet joins and one cue per impact

The hall SHALL silence historical room effects and suppress repeated ones.

#### Scenario: A newcomer arrives after the bells have rung

- **WHEN** a client accepts its first room snapshot, reconnects, or sees a repeated result
- **THEN** the client SHALL baseline the event cursor on the first snapshot and play zero historical cues. Play each later unseen result at most once if it is at most 250 ms old.
