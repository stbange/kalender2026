# Give each snowcaster its own feel

## 1. Weight in the player’s hand (FIRE-01)

- [ ] 1.1 Give each tool a distinct amount of model-only kick using the defaults in the matching requirement. Measure the five travel curves and shot directions against the current fixed recoil.

## 2. A mitten snap for the pistol (FIRE-02)

- [ ] 2.1 Give the pistol a recognizable short release using the defaults in the matching requirement. Alternate single and held throws and check the onset against the input frame.

## 3. A three-way Flurry Fan puff (FIRE-03)

- [ ] 3.1 Make a single fan trigger read as a three-way throw using the defaults in the matching requirement. Check the fleck directions against the weapon spread and count one launch voice.

## 4. A Snow Spinner ratchet (FIRE-04)

- [ ] 4.1 Make the Spinner’s sound follow its actual cadence using the defaults in the matching requirement. Release, switch, pause and resume during a burst. Count one tail per completed continuous burst.

## 5. Bankshot spring release (FIRE-05)

- [ ] 5.1 Give the Bankshot a spring sound at launch using the defaults in the matching requirement. Listen to one launch and its first reflection from opposite sides of the range.

## 6. A muffled Snow Rocket launch (FIRE-06)

- [ ] 6.1 Give the rocket audible weight on a small speaker using the defaults in the matching requirement. Compare the pistol and rocket at matched loudness on desktop and a small speaker.

## 7. A readable rocket in flight (FIRE-07)

- [ ] 7.1 Make a slow rocket easy to follow using the defaults in the matching requirement. Fire two rockets a moment apart, expire one, and check the next projectile inherits no trail.

## 8. Visible handover between tools (FIRE-08)

- [ ] 8.1 Make a tool swap visible while accepting input immediately using the defaults in the matching requirement. Cycle twice, tap the currently selected tool and fire during the transition.

## 9. A local controller pulse for a throw (FIRE-09)

- [ ] 9.1 Let the firing hand feel an optional tool-specific pulse using the defaults in the matching requirement. Inject a local shot, remote shot and XR exit using a fake actuator, then check fit on a Quest 3.

## 10. Play a named local or world sound (FIRE-10)

- [ ] 10.1 Use named, bounded cues through the existing voice mixer using the defaults in the matching requirement. Compare the three existing WAVs with one new and one missing sample, then rotate past a positioned sound.

## 11. See which friend just threw (FIRE-11)

- [ ] 11.1 Show which nearby friend made a throw using the defaults in the matching requirement. Fire beside a friend, through a doorway fixture and immediately before a late join. Count cues only for live same-space observers.

## 12. Tune in play and verify controls

- [ ] 12.1 At the range fire at the same bell with each tool twice, then switch while holding fire. Compare a listener’s tool identification with the HUD covered and log accepted trigger intervals.
- [ ] 12.2 Repeat with Sounds off, Motion at zero and Detail at zero. Verify sky, camera, collision and controller aim against a run with every cosmetic disabled.
- [ ] 12.3 Run the affected C and Lua unit suites with their separate 95% gates and the relevant automated playthroughs. Record measured cues, negative cases and platform or device gaps with the change.
