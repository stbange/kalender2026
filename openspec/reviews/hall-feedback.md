# How the snowplay feels in The Lantern Hall

**Start with one snowball hitting one visitor.** The player should feel the mitten move as soon as they throw, see where the snow lands, and know whose shot counted. In the current hall the bell is better at answering all three questions than the gingerbread or the snowman. Its body tips, a note plays and the score changes. This makes it a good reference for the rest of the shooter.

Reviewed the public Web build on November 25, 2026, the released C and Lua paths, and the active hall specification on repository revision `05b081b`. The release code corresponds to `v0.1.0-hall`. The ranked entries below describe that baseline. The five proposals have since been implemented in the 0.2.0 hall. [Implementation and verification](hall-feedback-verification.md) [Play the hall](https://stbange.github.io/kalender2026/) · [Reviewed source](https://github.com/stbange/kalender2026/tree/05b081bdc40758eb9df7ebe2bed7b92978d4102a) · [Hall release](https://github.com/stbange/kalender2026/releases/tag/v0.1.0-hall)

## What happened in play

- **The centre bell can ring through the Christmas tree.** In a fresh desktop WebKit session on Pages, I entered solo practice, kept the initial view and fired the pistol. The counter went from 0 to 1 while the reticle remained a plain plus. The tree fills that sightline in the arrival capture. Walking respects a 2.25 m tree exclusion radius, but projectile contacts test visitors, bells and room bounds. A plastered-on snow decal at the tree would teach the wrong rule. Use the contact reported by physics for all cosmetic marks. Whether the tree should stop snowballs is a separate level-design decision worth playtesting. [Arrival view](../../docs/hall.png) · [Movement and contact rules](../../games/kalender2026/scripts/rules.lua)
- **A non-finishing hit gives almost nothing back.** In a deterministic probe using the actual game Lua and a stubbed rendering/input boundary, one pistol snowball took a three-HP Scarf Snowman to one HP. Clears stayed at zero and the post-impact sound queue was empty. The renderer still applies its usual small walking bob. There is no survival-hit pose or marker. This is the best first A/B test. [Visitor damage](../../games/kalender2026/scripts/rules.lua) · [Sound cues](../../games/kalender2026/scripts/main.lua) · [Visitor poses](../../games/kalender2026/scripts/world.lua)
- **The rack is mechanically varied and perceptually similar.** I selected all five snowcasters in the published Web build and tried their firing controls. The models and HUD names change. In the code the flat view always sets recoil to 0.095 and decays it at 0.64 per second. All five launches enqueue the same `throw.wav`. A visible ricochet and a localized rocket burst would explain two of the most interesting toy mechanics. [Weapon tuning](../../games/kalender2026/scripts/rules.lua) · [Five tool meshes and recoil](../../games/kalender2026/scripts/world.lua) · [Three audio clips](../../src/client.c)
- **The hall can congratulate a newcomer for old activity.** In a separate Lua replay a fresh client joined a room with 12 previous bell hits and three previous visitor clears. Nobody fired. The first update queued both `bell` and `poof`. Snapshots carry cumulative totals. Multiple new hits within one snapshot can likewise become a single chime, and projectile rows lack the owner needed for private credit. Establish a silent starting point and attribute future contacts. [Client comparison](../../games/kalender2026/scripts/main.lua) · [Snapshot format](../../games/kalender2026/scripts/network.lua)
- **Contact is playful but its cause can get lost.** Walking drops to 56% of normal while snow-dusted and recovers 1.3 seconds after the last brush. A nearby door’s hint takes precedence over the slowdown message. A little snow on the player’s boots and one brush-off on recovery would explain both states while leaving the doorway text readable. [Contact and recovery](../../games/kalender2026/scripts/rules.lua) · [Hint priority](../../games/kalender2026/scripts/main.lua)

## First playtest

Build a vertical slice with the pistol, one snowman and one bell. Seed the room baseline, carry the cause and position of a contact, and wire the personal mark, small flinch and local kick. Use the current sound if needed during the first visual pass. Have one friend shoot, another deliberately miss and a third join after a bell rings. Ask each person which throw connected, where it landed and whose it was. Repeat muted and with reduced motion. Count incorrect answers and private marks on the wrong device. A friend should never receive someone else’s personal mark.

Follow with a Bankshot off a bare wall and a Snow Rocket into the floor between two visitors. Ask the observer to point to the bounce and the outer edge of the burst. These two trials exercise the shooter in the public hall with an empty mission catalog. The practice-wave action already supplies repeat encounters. The headset, phone speaker balance and physical haptic feel still need testing on the actual devices.

## Ranked improvements

Scores prioritize repeated actions. The first playtest also needs the event identity and quiet-join work even though players encounter joining less often. Each linked requirement includes an exact trigger, candidate defaults and an observable scenario.

| Rank | Improvement | Item | Score | What to try |
| ---: | --- | --- | ---: | --- |
| 1 | [Personal hit mark](../changes/clarify-snowball-impacts/specs/hall-snowplay/spec.md#requirement-personal-hit-mark) | HIT-01 | 15 | Four ticks for 90 ms, visible only to the thrower after a confirmed hit. |
| 2 | [Visitor flinch](../changes/clarify-snowball-impacts/specs/hall-snowplay/spec.md#requirement-visitor-flinch) | HIT-02 | 15 | A six-degree lean for 110 ms lets a snowman show that the first shot counted. |
| 3 | [Weight in the player’s hand](../changes/differentiate-snowcaster-feedback/specs/hall-snowplay/spec.md#requirement-weight-in-the-players-hand) | FIRE-01 | 15 | Give the Spinner 1.5 cm of kick and the rocket 8 cm. Keep the view steady. |
| 4 | [Powder at the point of contact](../changes/clarify-snowball-impacts/specs/hall-snowplay/spec.md#requirement-powder-at-the-point-of-contact) | HIT-03 | 12 | Five flakes mark the actual contact for 140 ms, including in an observer’s view. |
| 5 | [Soft hit sound for the thrower](../changes/clarify-snowball-impacts/specs/hall-snowplay/spec.md#requirement-soft-hit-sound-for-the-thrower) | HIT-04 | 12 | One quiet packed-snow thup for a surviving hit, even when several fan pellets connect. |
| 6 | [A snow mark for a missed shot](../changes/clarify-snowball-impacts/specs/hall-snowplay/spec.md#requirement-a-snow-mark-for-a-missed-shot) | HIT-08 | 12 | Leave a short-lived stamp on a real wall or floor contact so the player can correct a miss. |
| 7 | [A mitten snap for the pistol](../changes/differentiate-snowcaster-feedback/specs/hall-snowplay/spec.md#requirement-a-mitten-snap-for-the-pistol) | FIRE-02 | 12 | A 65 ms mitten snap from three takes makes a single pistol throw recognizable. |
| 8 | [A three-way Flurry Fan puff](../changes/differentiate-snowcaster-feedback/specs/hall-snowplay/spec.md#requirement-a-three-way-flurry-fan-puff) | FIRE-03 | 12 | Three narrow flecks and one brushed sound explain the fan’s spread. |
| 9 | [A Snow Spinner ratchet](../changes/differentiate-snowcaster-feedback/specs/hall-snowplay/spec.md#requirement-a-snow-spinner-ratchet) | FIRE-04 | 12 | Two short ratchet strokes alternate with actual rounds. One release tick ends a burst. |
| 10 | [Carpet and stone underfoot](../changes/enliven-hall-interactions/specs/festive-hall/spec.md#requirement-carpet-and-stone-underfoot) | HALL-04 | 12 | A 1.8 m stride changes from muffled cloth to stone at the edge of either woven aisle. |
| 11 | [Quiet joins and one cue per impact](../changes/clarify-snowball-impacts/specs/hall-snowplay/spec.md#requirement-quiet-joins-and-one-cue-per-impact) | HIT-10 | 10 | A joining player hears silence for actions that predate arrival. A new impact plays once. |
| 12 | [Snow on your boots](../changes/animate-seasonal-visitors/specs/hall-snowplay/spec.md#requirement-snow-on-your-boots) | VIS-02 | 10 | A snow-covered boot explains the slowdown while the nearby door’s date stays visible. |

## Proposed OpenSpec changes

| Change | Items | Scope |
| --- | ---: | --- |
| [clarify-snowball-impacts](../changes/clarify-snowball-impacts/proposal.md) | 10 | Owner-only hits, near misses, bounces, bursts, silent joins and per-outcome records. |
| [differentiate-snowcaster-feedback](../changes/differentiate-snowcaster-feedback/proposal.md) | 11 | Model kick, five launch signatures, handover, rocket trail, optional haptics and a friend’s throw. |
| [animate-seasonal-visitors](../changes/animate-seasonal-visitors/proposal.md) | 10 | Wake, warning, contact, recovery, five character details and departure. |
| [enliven-hall-interactions](../changes/enliven-hall-interactions/proposal.md) | 9 | Bell swing, spatial notes, score, walking, sealed doors, practice and midnight. |
| [tune-hall-feedback-accessibility](../changes/tune-hall-feedback-accessibility/proposal.md) | 9 | Device-local controls, reduced motion, contrast, captions, stereo, voice and sprite caps. |

The five changes contain **49 independently estimated items**. Start the first slice with HIT-09 and HIT-10 for identity and the join baseline, then bring in HIT-01, HIT-02 and FIRE-01. Use the external defaults and controls in OPT-01, and the stereo presentation from OPT-09 before testing on Quest. FIRE-10 supplies the shared voice adapter for the audio items. HIT-06 and HIT-07 can then use the same contact records for the rocket and Bankshot. On a crowded range, OPT-07 and OPT-08 bound optional sprites and voices.

## Player-facing event inventory

**Good** means the current cue readily communicates this event, **weak** means present but ambiguous or incidental, and **–** means none identified for that channel. Visual means an in-world appearance, motion covers animation and movement, and UI covers text, reticle and controls. These are design judgments from the source, the playthrough and visual captures. A quiet camera is a deliberate strength for first-person and headset play.

| Existing action or event | Visual | Audio | Camera | Motion | UI | Haptics | What the player gets today |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Enter solo and look around | good | – | good | good | good | – | The central fir, marked galleries and local tool establish the view. |
| Walk, strafe, stop or meet a wall or tree | weak | – | good | weak | – | – | The view moves and clips at bounds. Floor materials and stopping have no step feedback. |
| Touch move/look, pointer-lock release and return | weak | – | good | good | good | – | Thumbstick and buttons on touch, a menu on pointer-lock loss. |
| Enter or exit VR, snap-turn and aim | good | – | good | good | weak | – | Tracked hand and level horizon. Ordinary flat HTML is outside the stereo view. |
| Select or cycle a snowcaster | good | – | – | weak | good | – | Immediate mesh, name and slot change in place. |
| Throw a pistol snowball | weak | weak | – | weak | – | – | A visible ball, common launch sound and flat gun kick. |
| Fire a Flurry Fan spread | good | weak | – | weak | – | – | Three actual pellets. Same release note and kick as the pistol. |
| Hold and release the Snow Spinner | weak | weak | – | good | – | – | Frequent balls and repeated sound make the cadence apparent. Release is quiet. |
| Launch a Bankshot / reflect from a boundary | weak | weak / – | – | good | – | – | Gravity and the direction change exist. The bounce itself is silent. |
| Launch / detonate a Snow Rocket | weak | weak / – | – | weak | – | – | Larger ball, then it vanishes. The affected radius has no visible edge. |
| Miss a target, expire in flight, or pass a friend | weak | – | – | – | – | – | The shot expires or hits a boundary. Passing friends is harmless. |
| Damage a visitor that survives | – | – | – | – | – | – | HP changes in the rules with no contact-specific cue. |
| Clear one visitor | weak | weak | – | weak | weak | – | The mesh disappears, the room’s clear delta can play a poof, and the Web visitor total drops. |
| Wake an arrival, practice or return visitor | weak | – | – | weak | weak | – | Five scheduled wakes 1.7 s apart. The Web count includes living visitors that are still asleep. |
| Be chased by the five kinds | good | – | – | good | – | – | Different silhouettes, speeds and paths, including the wisp’s vertical float. |
| Brush a visitor, remain slowed, recover | weak | – | – | weak | weak | – | Real travel speed changes. The conditional hint disappears at recovery. |
| Hit a ready brass bell | good | good | – | weak | good | – | A bell note, 55° tilt and immediate shared tally. The note has no location. |
| Hit during reset / see the bell become ready | weak | – | – | weak | weak | – | It holds one tilted pose until 1.2 s then jumps upright. Extra hits earn no score. |
| Clear a wave and request another | weak | weak | – | weak | good | – | The final ordinary clear and the practice invitation. Accepted practice increments the wave. |
| See a friend arrive, walk, throw or leave | weak | – | – | weak | good | – | Avatar, interpolated walk and room count. A shot has no dedicated thrower gesture. |
| Join, encounter a full room, disconnect or reconnect | weak | weak | – | weak | good | – | Status text, roster and solo fallback. A first populated snapshot can play old sounds. |
| Inspect a dated, pending, ready or completed arch | good | – | – | weak | good | – | Number, wreath, due marker and status. The newest due day has a floor guide. |
| Use a future door or wait for a pack to load/retry | weak | – | – | – | good | – | Date, preparation or load/retry text. The player stays safely in the hall. |
| Observe a new calendar day while present | good | – | – | weak | weak | – | The marker, door appearance and due count refresh. |
| Cross a delivered doorway, follow a friend or return | good | – | weak | weak | good | – | Pocket and player position change. The return can trigger one shared wave. Fixture path. |
| Use a fixture objective and earn or replay an ornament | good | – | – | weak | good | – | Objective status and a persistent tree/door ornament. Replay preserves the award. |
| Open menus, edit a room, copy an invitation or resume play | weak | – | weak | weak | good | – | Focus/hover, form status and the Web menu camera. Desktop has its own room editor. |
| Watch the idle hall | good | – | – | good | – | – | Falling snow, animated hearth, lantern light and the voxel tree already give the room life. |

The released hall has unlimited snowballs, grounded walking and a temporary slow. Ammo, reloading, headshots, health, player death, jumping and sprinting have no corresponding rule to communicate here. Those catalog examples would change the game. Mission observations above cover the existing test fixture only. [Original hall proposal](../changes/add-advent-hall/proposal.md) · [Snowplay requirements](../changes/add-advent-hall/specs/hall-snowplay/spec.md) · [Festive hall requirements](../changes/add-advent-hall/specs/festive-hall/spec.md)

## Scoring and estimates

Priority is impact × frequency weight ÷ effort weight. Impact runs from 1 (decoration) to 5 (can the player understand the action?). Per second = 3, per minute = 2 and rare = 1, estimated during the relevant activity. S = 1, under two hours. M = 2, under half a day. Estimates assume the named shared dependency is present. Ties use higher impact, then proposal order as listed above and item number. The scores are editorial estimates.

Each proposal’s delivery table records channels, controls, likely systems, implementation effort, impact, frequency, score and risk for each item. Each matching specification states the exact trigger and suggested defaults. Optional authoring switches and personal controls let effects be tuned independently. Implementation checklists end with a playtest and a settings check.

## Source map and reuse

| Proposal shorthand | Already in the game | Reuse for the proposed work |
| --- | --- | --- |
| rules, main, world | Weapon and visitor tables, `Hall.step`, local `fire`, gun poses, reusable snowball meshes, sprite drawing and bell reset times | Base effects on real actions and existing poses. Put per-tool tuning, timings, gains and authoring switches in loose client Lua. [Rules](../../games/kalender2026/scripts/rules.lua) · [Client logic](../../games/kalender2026/scripts/main.lua) · [World](../../games/kalender2026/scripts/world.lua) |
| net, host | Text snapshots, shot serials, 65 ms room broadcasts, versioned room handshake | Extend the current protocol with bounded presentation facts and suppress stale or duplicated cues. No second simulation. [Snapshot format](../../games/kalender2026/scripts/network.lua) · [Linux host](../../server/room.c) |
| audio, assets | `audio_frame`, VFS WAV loader, engine voices, buses, pitch and spatial listener, artwork generator and existing flake sprites | Add named loose WAVs and small original sprite variants. Record original audio/art under CC BY 4.0 and its source in the asset credits. [Audio bridge](../../src/client.c) · [Engine voice API](https://github.com/stbange/engine/blob/bdf4265ebae2ca6b5f80e62d2796604ed1035847/include/engine/eng_audio.h) · [Original assets](../../tools/make_art.py) · [Credits](../../CREDITS.md) |
| HUD, native HUD, Web, XR | Lua HUD state, flat native engine UI, Web HUD and touch input, per-eye WebXR draws and tracked input | Use one cue meaning with suitable native, HTML and stereo presentations. Put important VR indicators in the scene. [Native/HTML bridge](../../src/client.c) · [Web shell](../../web/hall.js) · [Stereo input](../../web/xr.js) |
| settings, content | Engine versioned saves, SDL preferences, browser IDBFS, room form, client-only Lua loading, loose Web manifest | Store overrides on the device, independent of connection details and awards. Keep the existing client, renderer and packaging model. [Settings](../../src/settings.c) · [Runtime content](../../src/content.c) · [Package builder](../../tools/package.py) |
| Tests and budgets | Lua units, real room-process tests, Web smoke, simulated XR lifecycle and the eight-player day-24 view | Record one positive and one negative case per cue. Preserve the separate 95% first-party C and Lua gates. Use the existing 60 fps desktop, 30 fps mobile and 72 Hz Quest targets. [Lua units](../../tests/unit.lua) · [Network tests](../../tests/network_test.py) · [Browser game test](../../tests/browser_smoke.py) · [Rendering check](../../tests/visual_check.py) |

The starting OpenSpec tree has one active hall change and empty canonical-spec and archive directories. The proposals add uniquely named requirements under its existing capability names, `hall-snowplay` and `festive-hall`. Baseline features already covered there include the five weapon behaviors, slow-only contact, shared bell score, wave lifecycle, readable door states, ornaments and the newest-door guide.

## Risks to test before shipping

- **Timing and ownership.** Give local input a same-frame response. Confirm an actual hit on the first frame that knows its result. Fan pellets, splash targets, spectators, room resets, reused player slots and stale snapshots need distinct tests. A first snapshot or an increase in a room total cannot serve as evidence that the local player hit something. [Impact design](../changes/clarify-snowball-impacts/design.md)
- **Readability and comfort.** Keep the sightline clear and retain a static, shape-coded cue with sound off or motion reduced. Hold the Quest horizon, head tracking and controller ray steady. The flat DOM HUD is unavailable in an ordinary immersive view. Physical headset comfort, vibration and phone audio were not evaluated in this audit. [Comfort design](../changes/tune-hall-feedback-accessibility/design.md)
- **Rendering and mix.** An existing 32-frame 960 × 540 software-renderer rehearsal with eight simulated players reported a 133.4 ms median. It establishes no headset or handset rate. Compare the same hardware scene with effects off/on and record p95, voice limits and sprite counts. Start with 24 extra sprites on touch/XR, 48 on desktop and eight new effect voices per client, reserving two for throws/hits and bells. [Recorded rehearsal](../changes/add-advent-hall/tasks.md)
- **Information overload.** The loudest confirmation belongs to the player who made the shot. Localize shared bell sounds, group one fan trigger, keep passing friends harmless, and let the next still moment in the hall be quiet. Verify the identity of tools with the HUD covered and the identity of outcomes with audio muted.
