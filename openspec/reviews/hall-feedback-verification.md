# Lantern Hall 0.2.0 feedback verification

The 49 changes in the [original review](hall-feedback.md) are implemented. All five visitors also have articulated rigs. The snowman’s scarf trails a turn, the skipper alternates its icing-trimmed feet, the penguin pushes off each skate, the guard marches with opposing arms and legs, and the wisp folds and opens crystal wings. The capture advances the ordinary game simulation and renders each pose through the Web client. [Animated capture](../../docs/visitors.webp) · [Editable visitor movement](../../games/kalender2026/scripts/visitors.lua)

## Automated evidence

| What was exercised | Result |
| --- | --- |
| Native C host, mixer, settings, HUD and room service | 677 of 696 executable lines covered by the C unit suite (97.3%). |
| Shipped gameplay and presentation Lua | 1,840 of 1,879 executable lines covered by the Lua unit suite (97.92%). The coverage guard also checks that an untested mission counts toward the denominator. |
| Eight-player room, native client and browser over WSS | The shooter and observer received the same confirmed contact. Repeating a trigger produced one launch and score. A reconnecting slot acquired a new occupancy ID. A separate room had an independent score. |
| Real WebGL play | Holding the pistol on a snowman produced outlined ticks on a surviving hit and a diamond on its clear. The muted, reduced-motion client retained these shapes. A fixture mission could be joined, completed, left and replaced without rebuilding the game. |
| Feedback controls | A 390 CSS-pixel touch viewport supported three simultaneous fingers. Keyboard and touch operated the settings. A second client kept independent preferences, and Web settings survived reload. Native F3 and F2 settings were exercised through the C entry points. |
| Stereo and haptics | The browser rendered both eyes through the same WebAssembly client. A mock firing-hand actuator received pistol and rocket pulses. The session stopped the actuator on exit and worked with a controller lacking vibration. |
| Loose art and audio | The outlined marks retain a transparent centre on grayscale snow, timber and brass. The samples pass onset and duration checks. The three pistol takes differ by less than 1.5 dB RMS. The rocket retains a measurable 700 Hz slap. |

## Eight-player range measurement

Chromium used ANGLE with the SwiftShader software renderer at 960 × 540. Eight simulated players fired Spinners and Snow Rockets at the five bells on day 24. The camera, route and fixed simulation step were identical, with 12 warm-up frames and 48 sampled frames per run. The two reserved voices give local throws and scored bells priority in a busy room. [Reproducible route](../../tests/visual_check.py)

| Feedback | Median frame | 95th percentile | Peak additional sprites | Peak effect voices | Voices played / dropped by mixer |
| --- | ---: | ---: | ---: | ---: | ---: |
| Off | 183.3 ms | 200.0 ms | 0 | 0 | 0 / 0 |
| On | 183.3 ms | 333.3 ms | 48 | 8 | 26 / 60 |

The software renderer missed the real-time target in both runs. With feedback on, the slower frames took longer. Each build uploads fresh measurements and landmark captures to the workflow report. Smoke tests also enforce the 24-sprite touch and XR limit. [Build and test reports](https://github.com/stbange/kalender2026/actions/workflows/hall.yml)

## Checks requiring players or hardware

Physical iPhone, Android and Quest 3 frame pacing, headset comfort, controller feel and phone-speaker balance still require hands-on testing. Blind recognition of the five sounds and gaits also needs listeners and players. The public client connects to a user-supplied room address. Hosts can use the matching 0.2.0 Linux service. [Downloads](https://github.com/stbange/kalender2026/releases/tag/v0.2.0-hall)
