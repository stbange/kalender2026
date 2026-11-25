# Give each snowcaster its own feel

## ADDED Requirements

### Requirement: Weight in the player’s hand

The hall SHALL give each tool a distinct amount of model-only kick.

#### Scenario: The player alternates between pistol and rocket

- **WHEN** the local fire routine accepts input for the selected tool
- **THEN** the client SHALL start model-only kick in the same rendered frame. For pistol, fan, spinner, Bankshot and rocket use 5, 3, 1.5, 4 and 8 cm of travel, settling in 90, 120, 65, 130 and 180 ms respectively. Keep the XR grip and aim ray tracked.

### Requirement: A mitten snap for the pistol

The hall SHALL give the pistol a recognizable short release.

#### Scenario: Two quick pistol shots

- **WHEN** the player fires a Snowball Pistol shot
- **THEN** the client SHALL play one 65 ms dry snap in the firing frame. Choose among three equal-loudness takes, avoid immediate repeats and vary pitch by ±3%.

### Requirement: A three-way Flurry Fan puff

The hall SHALL make a single fan trigger read as a three-way throw.

#### Scenario: Three pellets leave one snowcaster

- **WHEN** the local Flurry Fan fires one trigger
- **THEN** the client SHALL draw three 85 ms flecks along the existing left, centre and right pellet directions and play one 120 ms brushed-snow sound for the trigger.

### Requirement: A Snow Spinner ratchet

The hall SHALL make the Spinner’s sound follow its actual cadence.

#### Scenario: A short burst ends

- **WHEN** a Snow Spinner fires consecutive accepted rounds
- **THEN** the client SHALL alternate two 45 ms ratchet strokes on the actual firing beats. After three or more rounds play a single 85 ms release tick when the burst ends.

### Requirement: Bankshot spring release

The hall SHALL give the Bankshot a spring sound at launch.

#### Scenario: The spring releases before the first bounce

- **WHEN** the player launches a Bankshot
- **THEN** the client SHALL sound one 90 ms plucked spring dropping from 420 to 260 Hz under the existing snow transient. Trigger it at release in the firing frame.

### Requirement: A muffled Snow Rocket launch

The hall SHALL give the rocket audible weight on a small speaker.

#### Scenario: A rocket leaves the mitten

- **WHEN** the local player fires a Snow Rocket
- **THEN** the client SHALL play a single 155 ms original clip with a low packed-snow thump and an audible 700 Hz mitten slap. Fire the first transient in the input frame.

### Requirement: A readable rocket in flight

The hall SHALL make a slow rocket easy to follow.

#### Scenario: Two rockets cross the same sightline

- **WHEN** a visible Snow Rocket travels through the hall
- **THEN** the client SHALL leave up to three shrinking snow motes behind its last 0.45 m of travel. Retire each within 100 ms and clear its trail at a hit, timeout or pocket change.

### Requirement: Visible handover between tools

The hall SHALL make a tool swap visible while accepting input immediately.

#### Scenario: The player fires during a switch

- **WHEN** the player selects a different snowcaster
- **THEN** the client SHALL swap the effective tool and its HUD selection immediately, with a 4 cm dip and 100 ms settle on flat screens. Cancel the dip on fire and leave the tracked grip fixed in XR.

### Requirement: A local controller pulse for a throw

The hall SHALL let the firing hand feel an optional tool-specific pulse.

#### Scenario: A supported controller fires locally

- **WHEN** the player fires with a supported tracked controller and enables haptics
- **THEN** the client SHALL pulse the firing hand once per trigger. Default durations for the five tools are 18, 22, 12, 22 and 45 ms, at fractions .18, .22, .12, .22 and .32 of the user’s intensity.

### Requirement: Play a named local or world sound

The hall SHALL use named, bounded cues through the existing voice mixer.

#### Scenario: A cue has a world position or missing clip

- **WHEN** the hall requests a current or newly authored audio cue
- **THEN** the client SHALL resolve its loose sample name and gain, pitch and optional world position through the existing engine voice descriptor. Drain up to eight cues per frame and give unknown names zero playback.

### Requirement: See which friend just threw

The hall SHALL show which nearby friend made a throw.

#### Scenario: A friend fires a fan in the same gallery

- **WHEN** a remote player in the same hall makes an accepted throw within 12 m
- **THEN** the client SHALL draw two snow flecks for 90 ms at that friend’s launch position and play a quiet spatial mitten pop. Coalesce fan pellets into one launch and omit the local echo.
