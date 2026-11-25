# Let the visitors show what they are doing

## Why

A snowman can slow someone while the nearest door’s message occupies the same hint line. The visitors also pop into view and disappear when cleared. A slip, a footprint or a clock tick can explain the contact and give each visitor a little character.

## What Changes

- **VIS-01 · A footprint at wake-up.** Mark each visitor’s first appearance on its actual wake beat.
- **VIS-02 · Snow on your boots.** Keep the cause of slowed movement readable beside another message.
- **VIS-03 · A clear end to the slowdown.** Signal the instant a player regains normal walking speed.
- **VIS-04 · A visitor approaching from behind.** Give an approaching visitor a directional cue.
- **VIS-05 · Snowman scarf follow-through.** Let the snowman’s scarf follow its turn.
- **VIS-06 · Gingerbread crumbs on a skip.** Match gingerbread crumbs to the skipper’s gait.
- **VIS-07 · A penguin skate scratch.** Give the skater a trace at changes of direction.
- **VIS-08 · Clockwork quarter beats.** Let the clockwork guard’s actual turns make a sound.
- **VIS-09 · Frost Wisp drift.** Make the wisp’s floating motion readable against the hall.
- **VIS-10 · A visitor bows out.** Give cleared visitors a brief material-specific farewell.

- Give all five visitor meshes articulated parts and a distinct gait. Use travel distance to drive the legs and skates, and the wisp’s float cycle to drive its wings.

## Impact

Adds presentation to the hall-snowplay wake, movement, slowdown and clear states. Uses the existing five visitor meshes, positions, headings and wake times. Distinguishes a short speed penalty from harm through the art, copy and timing.

Each estimate covers one slice after its shared dependencies are available. Frequencies describe active play. The specification gives the trigger and tunable defaults for every row. [Audit, source map and scoring](../../reviews/hall-feedback.md) · [Requirements and scenarios](specs/hall-snowplay/spec.md)

| Item | Channels | Player controls | Likely systems | Effort / impact / frequency | Priority | Main risk and mitigation |
| --- | --- | --- | --- | --- | ---: | --- |
| VIS-01 | visual | Detail | world, main | S / 3 / per minute | 6 | An early silhouette can look hittable. Start the cue on the same wake boundary that enables contact. |
| VIS-02 | visual, UI | Marks style and persistent state text | main, HUD, world | S / 5 / per minute | 10 | A door or co-op cue can mask the cause of slow movement. Give this status its own slot and an in-world mark near the tracked tool in stereo. |
| VIS-03 | audio, motion, UI | Sounds, Motion | main, HUD, world, audio | S / 4 / per minute | 8 | An exaggerated recovery could imply a speed boost. Lock the cue to the falling edge of the real slow. |
| VIS-04 | audio, UI | Sounds, Captions | world, main, audio, HUD | M / 4 / per minute | 4 | Crowding becomes a constant alarm. Choose the nearest qualifying visitor and use positional audio. |
| VIS-05 | visual, motion | Motion, Detail | world, assets | S / 2 / per minute | 4 | A loose attachment can look like a second target. Keep the tip inside the existing scarf’s reach. |
| VIS-06 | visual, motion | Detail, Motion | world, rules | S / 3 / per minute | 6 | Crumbs can look collectible. Use small dull flecks at ground level and skip them in another pocket. |
| VIS-07 | visual | Detail | world, rules | S / 3 / per minute | 6 | Long trails can look like a route. Bound the length and expiry of each scratch. |
| VIS-08 | audio | Sounds | world, audio, assets | S / 3 / per minute | 6 | Repeated direction changes can chatter. Compare wrapped angular distance and rate-limit by visitor. |
| VIS-09 | visual | Detail | world, assets | S / 2 / per minute | 4 | Ambient snowfall can hide a white trail. Give the two motes an outline and keep them close to the wisp. |
| VIS-10 | visual, motion | Detail, Motion | world, net, assets | S / 4 / per minute | 8 | A lingering full mesh invites another shot. Use fragments only, with no collider or pickup. |
