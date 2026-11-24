# Kalender 2026 · The Lantern Hall

## Why

Give a group of old gaming friends a place to meet in December and a reason to come back tomorrow. A shared first-person Christmas hall can open one adventure at a time while each mission is written, tested and released independently.

## What Changes

- Build a timber great hall around a voxel fir. A hearth, toy workshop, frozen conservatory and clock gallery each frame six numbered arches. Pixel-art candle flames, falling snow and the sound of bells bring the room to life. A new door casts a ribbon of light toward the tree.
- Let up to eight friends enter the same live room, see each other move, and throw snowballs at brass bells and wooden targets. The range works before 1 December and gives the group something to do between missions.
- Open one more numbered portal at midnight in Europe/Warsaw each day from 1 through 24 December 2026. Friends can catch up, follow one another into a released mission, or stay in the hall. A returning player sees their own earned ornaments on the tree.
- Deliver the hall and its range first. Prove the co-op doorway with a small test-only room. Each real mission then gets its own design, original assets, playable objective and release. An unfinished door identifies the missing mission without awarding completion.
- Ship native clients, a mobile-aware Web and WebXR client on GitHub Pages, and a self-hostable Linux room service. Lua, scene files, art and audio remain external to the executables and WebAssembly.

## Capabilities

### New Capabilities

- `festive-hall` covers first-person navigation, readable portals, the snowball range and the player controls.
- `advent-missions` covers Warsaw unlocks, walkthrough entrances, co-op destinations, returns and personal progress.
- `shared-rooms` covers the eight-player Linux-hosted room, shared state, late arrivals and reconnects.
- `game-distribution` covers editable packages, supported targets, licensing, quality gates and main-only publication.

### Modified Capabilities

## Impact

The game will consume a pinned revision of the engine's `main` in `engine/`. First-party client and server code belongs in the game repository. The first implementation checkpoint is a native client and a browser exchanging real packets through the Linux service. The five childhood games and the proposed order of work are described in the [design](design.md) and the [implementation checklist](tasks.md).
