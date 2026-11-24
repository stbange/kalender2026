# Implementation checklist

The first playable milestone is an eight-player hall, its 24 portals and the shared snowball range. The co-op fixture certifies future missions. After the hall ships, each real day gets a separate OpenSpec change.

## 1. Build the foundation on main

- [ ] 1.1 Pin a reviewed commit of `stbange/engine/main` as the `engine/` submodule. Build the upstream runner with CMake, run its existing CTest and coverage checks, and record the pin and commands in the game repository.
- [ ] 1.2 Link the game host to `engine::core` and scaffold the external game directory. Boot one scene through the normal native entry point and the Emscripten shell. Change a Lua greeting and a texture and confirm both change after relaunch with the same binary hashes.
- [ ] 1.3 Set up C and Lua unit coverage on the game's own sources. Include the client, server, adapters, rules and each mission. Inventory executable lines, including a never-loaded fixture, and verify CI fails below 95% independently for C and Lua. Keep the upstream gate and report third-party and generated code separately.
- [ ] 1.4 Record MIT for project code and CC BY 4.0 for original art and audio. Add creator, source, license and modification fields to asset credits. Trace one hall asset from the source file through to its displayed credit. [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/)

## 2. Prove live multiplayer before dressing the hall

- [ ] 2.1 Bring up a headless Linux room process and a real WebSocket transport. Exchange an acknowledged message over WSS between a native client and a browser client running in separate processes. Repeat with Windows and Linux native builds and record the chosen C library, version and notices.
- [ ] 2.2 Implement invites, content/protocol compatibility, eight room slots, reconnect and the initial snapshot. Exercise eight independent clients, reject the ninth, disconnect one, and join the freed slot. Test duplicate joins, bad revisions and restoration without duplicate avatars.
- [ ] 2.3 Replicate a player's position, facing and space, then interpolate remote movement. From two independently driven clients, record the same movement, leave, late join and updated roster. Add unit cases for stale updates and duplicate events.
- [ ] 2.4 Package a Linux binary with external rules and endpoint configuration. Supply a sample systemd unit and TLS reverse-proxy instructions. Start on a display-free Linux host and connect from a browser via the documented public WSS route.

## 3. Make the hall navigable on all targets

- [ ] 3.1 Block out the tree, four landmarks, central aisle, range and 24 numbered arches. Use the engine's FPS controller, collision and doorway cuts. Run the spatial doctor and an input-driven route that approaches every threshold and bumps a solid wall.
- [ ] 3.2 Author the timber meshes, voxel fir and gifts, animated flame and snow sprites, and original bell sounds. Check captures from spawn, from door 24 and from the range. Verify all numerals and state symbols can be read with sound off and color cues removed.
- [ ] 3.3 Bind desktop move/look/throw to keyboard and mouse. Enable touch on mobile Web with independent left movement, right drag and throw. Test simultaneous fingers, cancellation, portrait/landscape rotation and a desktop pointer-lock release and reacquire.
- [ ] 3.4 Enable first-person stereo, tracked controller aim, movement and snap turn on Quest 3. Test a doorway crossing, range throw and return to flat play in the same room. Record a physical headset run alongside automated input and session-lifecycle checks.

## 4. Give the room its playable snowball range

- [ ] 4.1 Add external Lua rules for throw, hit, target reset and shared tally. Unit-test timing, misses, simultaneous hits, duplicates and a throw near another player. Verify one active bell cycle awards exactly one hit.
- [ ] 4.2 Replicate target state and hit events. In an automated real-socket test let one client throw, another observe and a third arrive late. Assert that all see the same count and active targets, including on a pre-Advent clock.

## 5. Connect the calendar to co-op missions

- [ ] 5.1 Supply the host clock to a pure Lua unlock rule. Generate the 24 Warsaw midnight instants. Check one second before, at and after every boundary, plus 30 November, 25 December, January 2027, disagreeing client time zones and resuming across midnight.
- [ ] 5.2 Define the 24 stable day IDs and validate the external catalog. Test duplicates, absent or broken packs, future dates and compatible revisions. Verify a locked threshold stops the player and a due unfinished door displays its status.
- [ ] 5.3 Add a clearly named test pack with one co-op objective and a return entrance. Walk one player through a due portal, advance the objective, have a second follow and leave a third in the hall. Verify shared instance and objective, independent return positions, replay, and no repeated transition at the threshold.
- [ ] 5.4 Persist personal ornaments through a versioned save. Check duplicate completions, existing saves, interrupted writes, a native restart and a browser close/reopen using the same profile. On storage failure preserve the last valid save and give the player visible feedback.
- [ ] 5.5 Document a mission pack with its day ID, Lua hooks for entry/objective/exit, assets, credit data and co-op test. Swap a fixture's script and assets, refresh the catalog and replay with identical client, server and Wasm executable hashes.

## 6. Package, verify and publish

- [ ] 6.1 Produce Windows and Linux client archives and the Linux server package, including loose content and notices. Run each from outside its install directory. Confirm the release manifest omits the test mission and that all referenced files exist.
- [ ] 6.2 Build the game-specific Web shell with Emscripten/WebGL2. Fetch the hall first and each mission on demand. Smoke-test a project-path deployment in a clean browser with touch and desktop input, checked network requests, external Lua/assets, and persistent saves.
- [ ] 6.3 Run strict OpenSpec validation, native CTest, separate game C and Lua unit coverage reports, the engine spatial doctor and deterministic headless playtests. Run the live-network tests separately from loopback tests and retain the reports and failure captures.
- [ ] 6.4 Rehearse the day-24 hall with eight players and the range active. Capture frame timing on a reference desktop, an identified Android handset, an iPhone and Quest 3. Check the design's 60/30/72 targets, portal readability, touch response and VR comfort.
- [ ] 6.5 Configure Pages for GitHub Actions. From a successful build of `main`, upload the tested Pages artifact, deploy it with the matching Linux service/content revision and join from two devices outside the host network. Verify the project URL, one bell hit, reconnect and the documented rollback to a previous matched revision.

## Workflow follow-up

- The hall snowplay extension has three additional implementation checks below.

## 7. Playtest the shooter in the hall

- [ ] 7.1 Implement five selectable snowball tools and verify the single, spread, rapid, bounce and splash behaviors using the normal shooting controls.
- [ ] 7.2 Add five visibly distinct slow-moving visitors. Verify that their movement effect expires, never stacks into a freeze and never damages the player.
- [ ] 7.3 Share arrival, practice and return waves across the room. Test that late join and duplicate returns cannot spawn extra waves and that the practice bell works with an empty mission catalog.

## Workflow follow-up after release

- Archive the hall change when the acceptance scenarios pass and the public multiplayer smoke test succeeds. The intended Pages address is `https://stbange.github.io/kalender2026/`.
- Open the first real mission change from a chosen childhood-game pitch. Set its date, build one complete co-op objective, test late joins and returns, credit its assets and deliver its pack before its Warsaw opening time. Repeat for each subsequent day.
