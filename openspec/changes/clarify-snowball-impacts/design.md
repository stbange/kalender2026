# Deliver a contact to the right player

## What the hall sends today

A shot already has a serial number in the room. Its rendered snapshot row contains the serial, kind and position. The row omits the owner and original trigger sequence. The room also publishes cumulative bell hits, cumulative visitor clears, visitor HP and bell reset times. Comparing two totals cannot distinguish two shooters, two targets or an action that happened before joining. The host sends snapshots about every 65 ms. The existing hall design already calls for ordered events. This change specifies the additional facts needed to present a contact. [Room snapshots](../../../games/kalender2026/scripts/network.lua) · [Room loop](../../../server/room.c) · [Hall design](../add-advent-hall/design.md)

## Local action and confirmed outcome

Start a local throw’s sound and gun motion in the input frame. Do not wait for travel, physics or the room before acknowledging the hand movement. At 30 m/s the pistol takes about a second to reach a bell across the hall. A mark on trigger-down would claim a hit too early. In solo, consume the outcome immediately after the rules resolve it. Online, display a personal success on the first rendered frame with its confirmed result. The in-flight snow and the launch cue already give the player something to see while it travels.

Append small typed records to the current snapshot format for accepted launches and resolved contacts. One record carries the room event serial, room time, space, shot owner, input sequence, projectile serial, result kind and world contact position. Carry bell or visitor ID for a target, bounce ordinal for a reflection and terminal/surviving state for a visitor. A blast has one origin and may have several confirmed target outcomes. Origin, target and actor are distinct facts. Aim-independent practice accents need only a wave ID and accepted reason. Use the existing room revision handshake for the changed format and release the matching client and host together. [Shot resolution](../../../games/kalender2026/scripts/rules.lua) · [Transport bridge](../../../src/client.c)

Set the solo player’s identity explicitly when producing records. In the release, the service assigns the player slot after joining, while solo initialization only assigns the client ID. Associate each projectile with its owner’s occupancy of a slot at launch, so a rocket still in flight when its owner disconnects cannot credit the next player in that slot. Use the shot sequence to group one fan trigger and a single burst. Positions and results come from the rule step. The current projectile integrator tests bounds after moving, so clamp a miss stamp to the actual contacted plane. Counting and cooldowns use the existing authoritative state.

## First snapshot, overflow and duplicates

Keep a rolling 32-record history with a monotonic high-water mark per room lifetime. When joining or reconnecting, initialize the cursor from the first valid snapshot, even if that snapshot has a nonzero tally and an empty event list. For later snapshots process unseen events in order once and advance past events from another pocket or older than 250 ms. If an intervening burst overflows the history, consume retained fresh events and take scores, current poses and HP from the latest state. Never manufacture a sound or personal hit from a score delta. On returning from a mission, skip historical hall effects from the time spent elsewhere.

Preserve bounds on the existing snapshot buffers and validate new field counts and lengths. Test the worst permitted projectile count plus the bounded history. Reserve compact representations or split optional presentation delivery if it cannot fit an existing buffer. Do not truncate authoritative state. Date, award and score simulation must stay identical with the optional rendering layer disabled.

## Acceptance at the range

A fires a fan past B into two visitors while B rings a bell. Both see the relevant world impacts and shared tally. A gets one grouped visitor confirmation. B hears the bell at that target and gets no visitor mark. C joins immediately afterwards and sees the correct tally in silence. Repeat with a delayed snapshot, a duplicate, an expired-in-air rocket, a reused player slot and a reconnect. Assert the baseline and outcomes in the existing Lua and real-WebSocket test suites. [Lua units](../../../tests/unit.lua) · [Room tests](../../../tests/network_test.py)
