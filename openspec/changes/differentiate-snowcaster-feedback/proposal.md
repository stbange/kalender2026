# Give each snowcaster its own feel

## Why

The five tools already change how a throw travels. From the player’s hand they all use the same throw recording and recoil. A quick mitten snap, a spinning ratchet and a heavy puff would let players recognize the tool while looking at the target.

## What Changes

- **FIRE-01 · Weight in the player’s hand.** Give each tool a distinct amount of model-only kick.
- **FIRE-02 · A mitten snap for the pistol.** Give the pistol a recognizable short release.
- **FIRE-03 · A three-way Flurry Fan puff.** Make a single fan trigger read as a three-way throw.
- **FIRE-04 · A Snow Spinner ratchet.** Make the Spinner’s sound follow its actual cadence.
- **FIRE-05 · Bankshot spring release.** Give the Bankshot a spring sound at launch.
- **FIRE-06 · A muffled Snow Rocket launch.** Give the rocket audible weight on a small speaker.
- **FIRE-07 · A readable rocket in flight.** Make a slow rocket easy to follow.
- **FIRE-08 · Visible handover between tools.** Make a tool swap visible while accepting input immediately.
- **FIRE-09 · A local controller pulse for a throw.** Let the firing hand feel an optional tool-specific pulse.
- **FIRE-10 · Play a named local or world sound.** Use named, bounded cues through the existing voice mixer.
- **FIRE-11 · See which friend just threw.** Show which nearby friend made a throw.

## Impact

Extends hall-snowplay’s presentation around the existing local fire and tool-selection paths. Reuses the five meshes, loose WAV loading, viewmodel transform and actual weapon IDs. Range, cooldown, aim, spread and input bindings stay under the current rules.

Each estimate covers one slice after its shared dependencies are available. Frequencies describe active play. The specification gives the trigger and tunable defaults for every row. [Audit, source map and scoring](../../reviews/hall-feedback.md) · [Requirements and scenarios](specs/hall-snowplay/spec.md)

| Item | Channels | Player controls | Likely systems | Effort / impact / frequency | Priority | Main risk and mitigation |
| --- | --- | --- | --- | --- | ---: | --- |
| FIRE-01 | motion | Motion | main, world | S / 5 / per second | 15 | Kick that changes aim penalizes the player. Animate only the flat gun presentation and use a muzzle cue on the tracked tool. |
| FIRE-02 | audio | Sounds | main, audio, assets | S / 4 / per second | 12 | A sharp transient tires the ear. Match perceived loudness to the existing throw recording. |
| FIRE-03 | visual, audio | Detail, Sounds | main, world, audio, assets | S / 4 / per second | 12 | Three sounds imply three trigger pulls. Tie the single voice to the trigger sequence. |
| FIRE-04 | audio | Sounds | main, audio, assets | S / 4 / per second | 12 | The Spinner repeats every 115 ms. Use short tails and cancel any queued release tick on a new burst. |
| FIRE-05 | audio | Sounds | main, audio, assets | S / 3 / per second | 9 | The release can resemble a bounce. Keep the spring at the thrower and the separate tok at each surface. |
| FIRE-06 | audio | Sounds | main, audio, assets | S / 4 / per minute | 8 | Phone speakers lose low frequencies. Compare the midrange transient at low volume and in mono. |
| FIRE-07 | visual | Detail | world, net | S / 3 / per minute | 6 | The shot array reuses indices. Track trail history by projectile ID to avoid connecting unrelated shots. |
| FIRE-08 | motion, UI | Motion | main, world, HUD | S / 3 / per minute | 6 | An animation could buy or lose firing time. Keep selection and rate limiting on the existing paths. |
| FIRE-09 | haptics | Haptics | main, XR | S / 3 / per second | 9 | Rumble can distract or be unavailable. Test actuator support, suppress remote throws and stop on session exit. |
| FIRE-10 | audio | Sounds | audio, main, assets | M / 4 / per second | 6 | The current three-token switch routes unknown tokens to poof. Reuse the existing mixer and preload only referenced samples. |
| FIRE-11 | visual, audio | Detail, Sounds | rules, net, world, audio | M / 4 / per minute | 4 | A snapshot can skip an entire short shot. Use one accepted launch record per trigger and the join baseline rules. |
