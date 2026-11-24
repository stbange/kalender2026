# Game distribution

## Purpose

Deliver the same extensible calendar game on native and Web targets, with editable content, visible credits and repeatable evidence that a release is playable.

## ADDED Requirements

### Requirement: Editable runtime content

The C11 game host SHALL use the cloned engine, SDL3 and OpenGL or WebGL2. Lua 5.1 gameplay scripts, scenes, models, voxel art, sprites, textures, audio and mission definitions SHALL ship as individually replaceable external files. Installing a compatible content-only mission SHALL leave the client executable, WebAssembly module and server executable usable without recompilation.

#### Scenario: Change a mission through content alone

- **WHEN** a maintainer adds a compatible pack to a day in the catalog, changes its Lua objective and replaces its target art
- **THEN** existing binaries run the revised mission after content refresh, and Web clients fetch the released files from the deployment path.

### Requirement: Native packages and the Pages client

Each release SHALL provide Windows and Linux clients and a self-hostable Linux service. GitHub Actions SHALL publish the Emscripten Web and WebXR client as a Pages artifact built from the game repository's main branch. The site SHALL launch the calendar directly under the project URL.

#### Scenario: Launch a clean release

- **WHEN** a player opens the deployed project URL or runs an unpacked native client from a different working directory
- **THEN** the hall, Lua scripts, sounds and shaders load, and the client can join the configured live room.

### Requirement: Code and art licensing

Original project code, including Lua scripts, SHALL carry the MIT license. Original game art and audio SHALL carry CC BY 4.0. Distributions SHALL identify asset creators, sources, licenses and changes, and include applicable third-party notices.

#### Scenario: Credit a reused asset

- **WHEN** a player or mod author inspects the credits in a native package or on the Web
- **THEN** they can identify the creator and license for each original or third-party asset and find its required attribution.

### Requirement: Release evidence

The release checks SHALL require at least 95% executable-line coverage from unit tests independently for first-party C and first-party Lua. The build SHALL also pass strict OpenSpec validation, an automated headless hall playthrough, a real-network multiplayer game test and a browser smoke test before deploying.

#### Scenario: Catch an untested new mission

- **WHEN** a mission adds executable Lua that unit tests never load
- **THEN** its uncovered lines appear in the Lua denominator and a total below 95% fails the release check even if all engine tests pass.

#### Scenario: Catch a cross-client regression

- **WHEN** transport unit tests pass but two independent clients disagree after a range hit or portal crossing in the automated game test
- **THEN** the candidate fails before Pages publication.
