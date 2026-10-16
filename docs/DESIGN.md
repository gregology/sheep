# Design

## Decisions

Settled in the design interview (2026-10-16):

| Area | Decision | Why |
|---|---|---|
| Engine | Godot 4.7 (GDScript) | Native Linux build for SteamOS, SDL3 controllers, raw mic access, and plain-text scenes and resources |
| Look | Orthographic 3D, fixed front tilt of 55° | Every sheep is the same size wherever it is, so the field is easy to read from the couch. Real height makes the fence jumps read well |
| Style | Soft two-tone toon shading, dark outlines, bright palette, round shadow under each creature | Bubbly and readable. In an orthographic view the round shadow is what shows how high something is |
| Models | Built from rounded shapes in code now; Blender scripts later | Named parts drive one procedural animation for both (see "Models") |
| Controllers | Two Steam Controllers plus three small D-pad-only Bluetooth pads | All input is position-based and works with a D-pad alone |
| Chaos input | D-pad steers; two buttons summon; autopilot after 2 s idle | Fits small hands, and something fun happens even when she stops steering |
| Rounds | Pen every sheep and everyone wins. Dogs get 1–3 stars, the chaos player earns stars for mischief | Nobody loses, and both roles get praised |
| Pen | One-way gate | Progress never goes backwards. The wolf only makes penned sheep dance |
| Dogs vs her creatures | No interaction | She can't be "beaten" by grown-ups |
| Joining | Join screen with role picking; roles remembered | Any controller can take any role |
| Mic feedback | In-game ducking plus calibration, no system echo cancellation | No SteamOS setup. Echo cancellation would also blur the sudden onsets the game detects |
| Audio | CC0 sounds plus a local family-sounds folder; synthesised placeholders for now | Personal touches without committing a child's voice to git |
| Delivery | GitHub Actions builds a release from each version tag; `install.sh` and `update.sh` on the Steam Machine | Repeatable builds of a private repo |

## Architecture

```
InputHub ──polls──▶ InputDevice (JoypadDevice | KeyboardDevice | ScriptedDevice)
   │                     ▲
   ▼                     │ PlayerSlot(device, role)
Players (who plays what) ┘
   │
   ▼
Main ── screens: JoinScreen, Hud, Celebration, PauseMenu, SettingsScreen
   │
   ▼
Game (one meadow; a round's lifecycle)
   ├── Meadow           visuals only: grass, fences, gate, scenery
   ├── FlockSim         the sheep brain: pure simulation, no nodes
   │     ▲  ▲
   │     │  └── FlockInfluence (RepelInfluence: dogs, barks, wolf; AttractInfluence: black sheep)
   │     └───── startle(): Events.flock_startled ◀── Mic ◀── StartleDetector
   ├── SheepView ×N     draws SheepState
   ├── Dog ×1–4         input → movement + a RepelInfluence; barks add a short burst
   └── ChaosController  input → summons ChaosCreature scenes from config/chaos_roster.tres
```

Autoloads: `Events` (game-wide signals), `Settings` (the live `Tuning`), `InputHub`,
`Players`, `Sfx`, `Mic`.

- **Simulation and drawing are separate.** `FlockSim` works on the ground plane
  (`Vector2` = x, z) and knows nothing about nodes, so it is unit-tested directly.
  The views read the sim's state each frame.
- **Influences are the extension point for the flock.** Anything that pushes, pulls,
  frightens or calms sheep is a `FlockInfluence` registered with the sim. Sheep don't
  know what a dog or a wolf is.
- **Events decouple features.** The microphone, the creatures, the HUD and the stars
  talk through `Events` signals.
- **Every number is in `Tuning`** (`src/core/tuning.gd`, defaults in
  `config/tuning.tres`). The grown-ups' settings screen edits the live copy and saves it
  to `user://tuning.tres`.

## The flock

Each tick, every loose sheep adds up a desired velocity from:

- **influences:** dogs push gently and linearly out to 5 m, a bark pushes hard for 0.3 s,
  the wolf pushes about 5× as hard as a dog over 9 m, and the black sheep pulls and calms
  over 12 m
- **flocking:** separation, plus cohesion that gets stronger with fear (scared sheep
  bunch up), plus alignment
- **calm behaviour:** stand and munch, or wander a few metres. A sheep with no
  neighbours ambles back to the flock
- **fences:** soft avoidance, plus hard collision. Diagonal "corner cuts" (marked by hay
  bales) stop sheep wedging into corners where no dog can get behind them
- **the gate funnel:** near the gate, a gentle drift inward. It widens late in long
  rounds (`assist_after`)

Fear is the strongest threat felt this tick, or a share of a neighbour's fear (contagion),
fading over time. Fear sets the running speed. A sheep becomes penned once fully inside
the pen, and from then on is kept inside it.

## The microphone

`Mic` reads raw frames (`AudioServer.get_input_frames`), high-passes them to ignore rumble,
and feeds 10 ms loudness blocks (dB) to `StartleDetector`:

- **Startle:** loudness jumps more than `mic_threshold_db` above the reference. The
  reference is the highest of: what the flock is used to, the room's noise floor, and
  the game's own sound at the mic. Bigger jumps make stronger scares.
- **Habituation:** `baseline_db` follows the loudness, quickly upward and slowly back
  down. So a continuing noise stops working, and a new noise has to be louder than it.
- **Tiring:** each scare drains `alertness`, which then recovers. Repeated shouts get
  weaker.
- **Ignoring itself:** the Master bus peak, held for `mic_self_hold` to cover latency
  and echo, plus the calibrated `mic_self_coupling_db`, estimates how loud the game is at
  the mic. That level never counts as a scare.

The settings screen's calibration measures the noise floor (3 s of quiet). It then plays
game sounds to measure the coupling.

## Extending

### A new chaos ability

1. Make a scene whose root node runs a script extending `ChaosCreature`
   (see `src/chaos/wolf.gd`). Override `_make_model()` and `_make_influence()`, and
   optionally `_speed()`, `_on_landed()`, `_active_tick()` and `_autopilot()`.
2. Add a `ChaosAbility` to `config/chaos_roster.tres` with an `id`, the scene, the
   `buttons` that summon it, a `color` and a `portrait` model.

The HUD button, cooldown, leap in and out, steering and autopilot all come for free.
A non-creature ability (thunder, say) can still be a `ChaosCreature` with an empty
model that calls `sim.startle()` when it lands.

### A new kind of flock behaviour

Extend `FlockInfluence`, implement `affect(sheep, sim)` by adding to `sheep.steer`,
`sheep.threat`, `sheep.urge` or `sheep.calming`, then call `sim.add_influence()`.

### A new field

Make another `MeadowLayout` resource with a different field size, pen position, gate
side or spawn area.

### Models

`Models.make(kind)` uses `res://assets/models/<kind>.glb` if it exists (dogs:
`dog_<breed>.glb`). Otherwise it builds the code stand-in. Models must face −Z and use
these node names, so the procedural animation in `CreatureModel` keeps working:
`Body`, `Head` (pivot at the neck), `LegFL`, `LegFR`, `LegBL`, `LegBR` (pivots at the
hips), and optionally `Tail`, `EarL` and `EarR`. Separate rigid parts are enough; no
skeleton is needed.

### Sounds

Use `Sfx.play(&"name")` or `Sfx.play_at(&"name", position)`. Files in
`assets/audio/sfx/<name>/` replace the synthesised placeholder for that name, and the
family-sounds folder replaces both. `Music` works the same way with `assets/audio/music/`
and `family_sounds/music/`. The placeholder loop is built on a worker thread at start-up.

## Testing

- `make test`: unit tests for the flock, the microphone rules, cooldowns and geometry.
- `make balance`: robot dogs (`HerdingBot`) play three full rounds against a scripted
  chaos player and report the times. At the time of writing they win in about 1–3 minutes.
- `make shots`: renders the join screen, a round and the celebration under a virtual
  display, using lavapipe (software Vulkan). The grass shader avoids a uniform that
  crashes lavapipe; see the comment in `tuft.gdshader`.

## Not yet verified on the real hardware

These need a playtest on the Steam Machine:

- How SDL and Steam Input order and name five mixed controllers.
- The USB mic's levels.
- How much TV sound leaks into the mic.
- Rumble on the small pads.

## Next

1. Playtest on the Steam Machine and tune `Tuning` from what the family does.
2. Blender scripts for the creature models, following the part names above.
3. CC0 sound effects and music to replace the placeholders.
4. More fields: obstacles, ponds, a pen on a different side.
