# Make the range and galleries respond

## Why

The brass bells already give the game its most legible hit, but they snap from upright to tilted and all sound from the same place. Walking from the carpet onto the stone is silent. Small changes to those familiar objects give the hall a sense of place between encounters.

## What Changes

- **HALL-01 · A brass bell that swings and settles.** Show the bell’s physical response and reset state throughout a scored cycle.
- **HALL-02 · Hear which bell rang.** Let listeners locate a scored bell in the gallery.
- **HALL-03 · A readable shared bell tally.** Draw attention to the shared count at the moment it changes.
- **HALL-04 · Carpet and stone underfoot.** Let the player hear the surface actually underfoot.
- **HALL-05 · Movement in the mitten.** Tie optional mitten movement to actual walking distance.
- **HALL-06 · A quiet knock for a sealed door.** Acknowledge a deliberate try at a future door.
- **HALL-07 · An invitation after the last visitor.** Draw attention to the practice bell after the last clear.
- **HALL-08 · A practice bell answers the group.** Acknowledge one accepted practice restart for the group.
- **HALL-09 · Midnight in the hall.** Mark a newly due date accurately for friends already present.

## Impact

Extends festive-hall’s range, movement and interaction cues. Uses the existing bells, two carpet aisles, HUD, practice action and door eligibility. The calendar dates, target availability, mission catalog and number of waves keep their existing authority.

Each estimate covers one slice after its shared dependencies are available. Frequencies describe active play. The specification gives the trigger and tunable defaults for every row. [Audit, source map and scoring](../../reviews/hall-feedback.md) · [Requirements and scenarios](specs/festive-hall/spec.md)

| Item | Channels | Player controls | Likely systems | Effort / impact / frequency | Priority | Main risk and mitigation |
| --- | --- | --- | --- | --- | ---: | --- |
| HALL-01 | visual, motion | Motion | world, rules | S / 4 / per minute | 8 | An upright bell implies it can score again. Keep the inactive pose distinct through the entire reset. |
| HALL-02 | audio | Sounds | audio, main, rules, net | M / 5 / per minute | 5 | Playing an aggregate chime hides simultaneous hits. Trigger from each confirmed bell ID and update the engine listener from the active camera. |
| HALL-03 | visual, UI | Motion, Marks | main, HUD | S / 3 / per minute | 6 | Counting animation could lag or imply personal credit. Display the final shared integer on the first frame. |
| HALL-04 | audio | Sounds | main, world, audio, assets | S / 4 / per second | 12 | Using key presses would sound footsteps against a wall. Integrate resolved movement and exclude pose corrections. |
| HALL-05 | motion | Motion | main, world | S / 2 / per second | 6 | Even small weapon sway can bother players. Follow actual distance, support zero and suppress in stereo. |
| HALL-06 | audio, motion | Sounds, Motion | main, world, audio, assets | S / 3 / rare | 3 | Walking along six doors should stay quiet. Require explicit use and exclude pending, ready and completed doors. |
| HALL-07 | visual, audio | Detail, Sounds | main, world, audio | S / 4 / rare | 4 | Joining an empty room should not celebrate an old wave. Trigger only on the observed last clear. |
| HALL-08 | motion, audio | Motion, Sounds | world, main, net, audio | S / 3 / rare | 3 | Two players can press practice together. Accept the wave reason from the room and suppress rejected or duplicate requests. |
| HALL-09 | audio, UI | Sounds, Captions | main, HUD, world, audio | S / 3 / rare | 3 | A due door may still lack a pack. Give the existing availability text priority over celebration. |
