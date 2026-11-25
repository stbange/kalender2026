# Make each snowball impact legible

## Why

A visitor can take a pistol hit and simply carry on walking. A friend’s bell also rings for the whole room. Players need to see where snow landed, whether a visitor felt it, and which throw earned the response.

## What Changes

- **HIT-01 · Personal hit mark.** Acknowledge a surviving visitor hit privately for its thrower.
- **HIT-02 · Visitor flinch.** Make a surviving hit visible on the visitor’s body.
- **HIT-03 · Powder at the point of contact.** Locate a hit on the struck surface.
- **HIT-04 · Soft hit sound for the thrower.** Give a surviving hit its own short sound.
- **HIT-05 · A distinct finishing mark.** Distinguish a finishing shot from an ordinary hit by shape.
- **HIT-06 · Visible Snow Rocket burst.** Show the area reached by an actual rocket detonation.
- **HIT-07 · Bankshot bounce ticks.** Mark the point where a Bankshot changes direction.
- **HIT-08 · A snow mark for a missed shot.** Show where a missed shot really ended.
- **HIT-09 · Who hit what and where.** Deliver enough confirmed contact information to identify its cause.
- **HIT-10 · Quiet joins and one cue per impact.** Silence historical room effects and suppress repeated ones.

## Impact

Extends hall-snowplay with contact cues. The two event tasks use the existing shared-rooms snapshot and its revision check. The Linux room and its clients must agree on the wire revision. The render and audio tasks stay client-side.

Each estimate covers one slice after its shared dependencies are available. Frequencies describe active play. The specification gives the trigger and tunable defaults for every row. [Audit, source map and scoring](../../reviews/hall-feedback.md) · [Requirements and scenarios](specs/hall-snowplay/spec.md)

| Item | Channels | Player controls | Likely systems | Effort / impact / frequency | Priority | Main risk and mitigation |
| --- | --- | --- | --- | --- | ---: | --- |
| HIT-01 | visual, UI | Marks | rules, net, HUD, world | S / 5 / per second | 15 | False credit in co-op. Match the thrower and merge pellets from the same shot. |
| HIT-02 | motion | Motion | world, rules, net | S / 5 / per second | 15 | Rapid hits can make a visitor jitter. Refresh one bounded offset per visitor. |
| HIT-03 | visual | Detail | world, net | S / 4 / per second | 12 | A cloud can cover the target. Cap the radius at 0.18 m and use the shared sprite budget. |
| HIT-04 | audio | Sounds | main, audio, assets, net | S / 4 / per second | 12 | A loud hit can mask the next throw. Keep the thup 4 dB below the player’s launch cue. |
| HIT-05 | visual, UI | Marks | main, HUD, world, net | S / 4 / per minute | 8 | Multiple personal badges obscure aim. Use a single stronger shape with a clear centre. |
| HIT-06 | visual, motion | Detail, Motion | world, rules, net | M / 5 / per minute | 5 | Through-wall or lifetime-only bursts would mislead. Use the actual burst result and depth-test the ring. |
| HIT-07 | visual, audio | Detail, Sounds | rules, net, world, audio | M / 5 / per minute | 5 | Corners could sound twice. Emit one cue per physics reflection step, including a two-axis reflection. |
| HIT-08 | visual | Detail | rules, net, world | S / 4 / per second | 12 | Decoration can suggest a hitbox. Use only a terminating boundary contact and discard expired-in-air shots. |
| HIT-09 | visual, audio, UI (source) | consumer settings | rules, net, host | M / 5 / per second | 7.5 | The current shot rows omit the owner. Keep the old state fields authoritative and pair the new wire format with a matching room revision. |
| HIT-10 | audio, visual, UI | consumer settings | main, net | S / 5 / per minute | 10 | A slot or room may be reused. Clear pending cues at each connection boundary and seed from the new room. |

[Impact ownership and delivery](design.md)
