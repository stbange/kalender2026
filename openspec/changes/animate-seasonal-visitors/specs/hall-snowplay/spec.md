# Let the visitors show what they are doing

## ADDED Requirements

### Requirement: A footprint at wake-up

The hall SHALL mark each visitor’s first appearance on its actual wake beat.

#### Scenario: The next visitor wakes beside the aisle

- **WHEN** a visitor reaches its scheduled wake time in the player’s current hall
- **THEN** the client SHALL show a 0.35 m footprint wreath at its feet for 190 ms as its mesh appears at the original position. A join baseline produces zero arrival flourishes.

### Requirement: Snow on your boots

The hall SHALL keep the cause of slowed movement readable beside another message.

#### Scenario: A visitor brushes the player beside a door

- **WHEN** the local player’s movement first becomes snow-dusted
- **THEN** the client SHALL show an outlined boot with two snow stitches and the word “Slowed” on the first frame with the status, independently of the door hint. Keep it through every contact refresh until the real slow expires.

### Requirement: A clear end to the slowdown

The hall SHALL signal the instant a player regains normal walking speed.

#### Scenario: Several brushes refresh one slow

- **WHEN** the local slow status changes from active to expired
- **THEN** the client SHALL remove the status immediately and play one soft 85 ms brush-off sound with a 100 ms shedding motion on the boot icon. Continued contact produces no extra brush-offs.

### Requirement: A visitor approaching from behind

The hall SHALL give an approaching visitor a directional cue.

#### Scenario: Two visitors approach from behind

- **WHEN** an awake moving visitor crosses within 2.2 m of the listener from the rear hemisphere
- **THEN** the client SHALL play one soft nearby rustle with an optional left or right outlined footprint for 350 ms. Rearm beyond 3 m and limit notices to one per listener every 2 s.

### Requirement: Snowman scarf follow-through

The hall SHALL let the snowman’s scarf follow its turn.

#### Scenario: The scarf changes direction

- **WHEN** the Scarf Snowman turns while walking
- **THEN** the client SHALL draw a two-pixel scarf tip on the existing silhouette with up to 8° of lag, easing back over 140 ms. Match the scarf’s existing red accent.

### Requirement: Gingerbread crumbs on a skip

The hall SHALL match gingerbread crumbs to the skipper’s gait.

#### Scenario: The skipper crosses the stone

- **WHEN** the Gingerbread Skipper reaches the fast beat of its current gait while displaced
- **THEN** the client SHALL leave two ginger-colored crumbs for 180 ms at the trailing foot, with a 350 ms minimum interval. Use the movement phase already driving the skipper.

### Requirement: A penguin skate scratch

The hall SHALL give the skater a trace at changes of direction.

#### Scenario: A penguin turns across the carpet

- **WHEN** the Penguin Skater reverses the side of its existing weave
- **THEN** the client SHALL draw one 0.22 m skate scratch on the floor for 220 ms, at most once every 300 ms. Orient it to the skater’s actual last displacement.

### Requirement: Clockwork quarter beats

The hall SHALL let the clockwork guard’s actual turns make a sound.

#### Scenario: The guard turns to face a friend

- **WHEN** the Clockwork Guard changes its quantized heading by at least 45°
- **THEN** the client SHALL play one 55 ms gear tick from the guard, audible within 6 m, with a minimum interval of 300 ms. Accumulate neither ticks nor history while offscreen and distant.

### Requirement: Frost Wisp drift

The hall SHALL make the wisp’s floating motion readable against the hall.

#### Scenario: The wisp rises in front of the tree

- **WHEN** an awake Frost Wisp changes height in its existing float cycle
- **THEN** the client SHALL leave two pale diamond motes below its silhouette, each lasting 160 ms, at most twice per second. Keep the wisp’s outline visible against the lit tree.

### Requirement: A visitor bows out

The hall SHALL give cleared visitors a brief material-specific farewell.

#### Scenario: A gingerbread visitor leaves the hall

- **WHEN** a visitor’s confirmed HP reaches zero in the hall
- **THEN** the client SHALL play a 160 ms departure at its last known position using three flecks in its own material, such as crumbs for the skipper or a loose gear for the guard. Clear the live silhouette at once.
