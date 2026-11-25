# Make hall feedback adjustable and comfortable

## Why

The game already has a steady first-person view and a tracked VR rig. Players should be able to feel the snowplay on a phone, with muted audio or wearing a headset, and decide how busy that feels on their own device.

## What Changes

- **OPT-01 · Personal preferences and loose defaults.** Remember feedback preferences per device using editable defaults.
- **OPT-02 · Touch and keyboard feedback controls.** Let players change feedback using touch or keyboard on the Web.
- **OPT-03 · Native feedback controls.** Expose the same feedback choices in native play.
- **OPT-04 · Reduced motion that keeps the result legible.** Provide a reduced-motion preset that keeps gameplay cues readable.
- **OPT-05 · Hit marks readable in grayscale.** Offer a shape-based high-contrast treatment for personal marks.
- **OPT-06 · An equivalent for important sounds.** Offer visual equivalents for important sound cues.
- **OPT-07 · A bounded snow-effects budget.** Bound whole-room decorative drawing on each target.
- **OPT-08 · Bell and hit sounds survive a busy room.** Protect useful sounds when many events coincide.
- **OPT-09 · Comfort and visible cues in stereo.** Preserve tracked stereo motion and provide in-world status.

## Impact

Extends festive-hall’s local presentation preferences. Uses the engine save path and browser IDBFS, native settings UI, touch-aware Web shell, WebXR input and the existing renderer and audio mixer. Tuning and media remain external to the binary.

Each estimate covers one slice after its shared dependencies are available. Frequencies describe active play. The specification gives the trigger and tunable defaults for every row. [Audit, source map and scoring](../../reviews/hall-feedback.md) · [Requirements and scenarios](specs/festive-hall/spec.md)

| Item | Channels | Player controls | Likely systems | Effort / impact / frequency | Priority | Main risk and mitigation |
| --- | --- | --- | --- | --- | ---: | --- |
| OPT-01 | UI, motion, visual, audio, haptics | all settings | main, settings, content | M / 4 / rare | 2 | A new save could overwrite ornaments or room settings. Use a separate key and fall back per field for missing, invalid or old values. |
| OPT-02 | UI | all settings | Web, settings | M / 4 / rare | 2 | A slider can consume the look gesture. Restrict pointer handling to the open dialog and return focus to its opener. |
| OPT-03 | UI | all settings | settings, native HUD | M / 4 / rare | 2 | The existing F2 room form must stay usable. Use a separately labelled feedback action and preserve the room editor’s bindings. |
| OPT-04 | motion, visual, UI | Reduced motion, Motion, Detail | main, world, Web, settings | S / 5 / rare | 5 | Turning feedback down could obscure state. Keep essential shapes and text and never add camera translation, roll or FOV kicks in immersive mode. |
| OPT-05 | visual, UI | Marks, Contrast | HUD, world, assets | S / 4 / per minute | 8 | A white shape disappears on snow. Pair a light fill and a dark contour and use geometry to encode the meaning. |
| OPT-06 | UI, visual | Captions | main, HUD, world | M / 4 / per minute | 4 | Captions can cover the date or crosshair. Reserve separate space and keep slow-state text visible. |
| OPT-07 | visual | Detail | world, assets | M / 4 / per second | 6 | Stereo or phones can exhaust their frame budget. Pool by effect lifetime and count per logical frame, once across both eyes. |
| OPT-08 | audio | Sounds | audio, main | M / 4 / per second | 6 | Eight Spinners can starve useful sounds. Apply priority before submitting to the existing mixer and track voice expiry. |
| OPT-09 | camera, UI, visual, haptics | Motion, Marks, Haptics | XR, world, HUD | M / 5 / rare | 2.5 | DOM cues are unavailable in ordinary immersive rendering. Draw with the existing stereo scene and keep tracking transforms intact. |

[Preferences, stereo and budgets](design.md)
