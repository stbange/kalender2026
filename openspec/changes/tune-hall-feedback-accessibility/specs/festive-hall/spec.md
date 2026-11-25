# Make hall feedback adjustable and comfortable

## ADDED Requirements

### Requirement: Personal preferences and loose defaults

The hall SHALL remember feedback preferences per device using editable defaults.

#### Scenario: An existing player installs the update

- **WHEN** a player first launches, changes a feedback setting, or restarts the game
- **THEN** the client SHALL read tunable effect defaults from the external game Lua and remember personal overrides in a separate version-1 feedback save. Start Motion, Detail and Sounds at 100%, Marks on, Contrast at Standard, Captions off and Haptics at 0%.

### Requirement: Touch and keyboard feedback controls

The hall SHALL let players change feedback using touch or keyboard on the Web.

#### Scenario: A player reopens the Web menu

- **WHEN** a Web player opens feedback preferences from the hall menu
- **THEN** the client SHALL offer labelled 0–100% Motion, Detail, Sounds and Haptics controls in 10% increments, Marks and Captions switches, the contrast choice and Reduced motion. Apply changes on input and preserve them after closing.

### Requirement: Native feedback controls

The hall SHALL expose the same feedback choices in native play.

#### Scenario: A native player adjusts a single level

- **WHEN** a Windows or Linux player opens the native feedback panel
- **THEN** the client SHALL expose the same named settings and 10% steps as the Web panel. Give every row a visible focus indicator and apply adjustments immediately. Escape closes the panel.

### Requirement: Reduced motion that keeps the result legible

The hall SHALL provide a reduced-motion preset that keeps gameplay cues readable.

#### Scenario: A player enters with reduced motion enabled

- **WHEN** a player selects Reduced motion or opens the Web edition for the first time with the system reduced-motion preference
- **THEN** the client SHALL set Motion to 0% and Detail to 25%. Present still hit marks, still status symbols and discrete bell poses. Explicit subsequent choices take precedence over the initial system preference.

### Requirement: Hit marks readable in grayscale

The hall SHALL offer a shape-based high-contrast treatment for personal marks.

#### Scenario: A clear happens in front of bright snow

- **WHEN** a player enables high-contrast Marks
- **THEN** the client SHALL draw the four-tick and diamond markers with a two-pixel contrasting outline at the reference 960 × 540 view, scaled for viewport density. Preserve the clear centre of both shapes on bright snow and dark timber.

### Requirement: An equivalent for important sounds

The hall SHALL offer visual equivalents for important sound cues.

#### Scenario: A muted player stands beside a door

- **WHEN** the player enables Captions and an important bell, nearby rear visitor or wave cue occurs
- **THEN** the client SHALL display a short text or shaped cue for at least 700 ms with a maximum of two concurrent cues. Use direction words where known and coalesce repeated bells. In stereo place the cue at its source or on the tool.

### Requirement: A bounded snow-effects budget

The hall SHALL bound whole-room decorative drawing on each target.

#### Scenario: Eight friends fire in a crowded room

- **WHEN** several clients are throwing in the same hall view
- **THEN** the client SHALL allow at most 48 additional transient sprites on desktop and 24 on touch or XR, across all new cues. Drop distant flourishes beyond 12 m first. retain the essential hit and status shapes separately.

### Requirement: Bell and hit sounds survive a busy room

The hall SHALL protect useful sounds when many events coincide.

#### Scenario: A shared bell rings during rapid fire

- **WHEN** many optional sounds overlap in one listener’s hall
- **THEN** the client SHALL admit at most eight new effect voices at once, with two slots reserved for personal feedback and bell confirmations. Drop distant decorative sounds first and keep the local throw onset immediate.

### Requirement: Comfort and visible cues in stereo

The hall SHALL preserve tracked stereo motion and provide in-world status.

#### Scenario: A player fires in VR and returns to flat play

- **WHEN** a player enters an immersive session or switches back to flat mode
- **THEN** the client SHALL keep additional camera shake, bob, roll, FOV offsets and forced head displacement at zero. Show a confirmed contact mark at the impact and a slow status near the tracked tool in both eyes. Stop pending haptics on exit.
