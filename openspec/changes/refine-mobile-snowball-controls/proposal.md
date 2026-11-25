## Why

A mobile player can fire merely by dragging the camera. Turning and throwing share the same screen area and SDL also interprets raw touches as virtual buttons.

## What Changes

- Let players look immediately with one finger and throw with a nearby double-tap.
- Let a player hold the second contact to fire at the equipped snowcaster’s cadence while turning and walking.
- Preserve the dedicated Fire button and teach the gesture in the controls panel.

## Capabilities

### New Capabilities

- `mobile-snowball-controls` covers aiming and intentional firing on the Web look surface.

## Impact

The Web shell owns touchscreen gameplay input. The native controls, controller bindings and shared room protocol stay compatible with the existing hall.
