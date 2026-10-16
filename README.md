# Sheep!

A bubbly couch co-op sheep-herding game for the Steam Machine. One to four grown-ups
play sheepdogs and herd the flock through a gate into the pen. One small person plays
**chaos**: shouting into the microphone spooks the sheep, and two big buttons summon a
**black sheep** (the flock follows it) or a **wolf** (the flock flees from it). Each
creature leaps in over the fence, runs about for 10 seconds, then leaps back out and
needs 20 seconds to recharge.

Nobody loses. When every sheep is home there's a party: the dogs get one to three stars
for speed, and the chaos player gets a star for every bit of mischief.

Built with [Godot 4.7](https://godotengine.org). See [docs/DESIGN.md](docs/DESIGN.md)
for how it works and how to add things.

## How to play

| Who | Move | Act |
|---|---|---|
| Sheepdog | Left stick or D-pad | Any face button (or R) barks: sheep near you scatter away |
| Chaos player | D-pad steers the creature that's out | Bottom/left face button (or L): black sheep. Right/top face button (or R): wolf |
| Anyone in the room | | Make a sudden loud noise: the flock jumps and bolts. Keep it up and they get used to it |

- **Joining:** press the bottom face button to join as a dog. Push right to become the
  chaos player (left to go back), and press the right face button to leave. Start begins
  the round. The game remembers who was what for next time.
- **Chaos:** if nobody touches the D-pad for 2 seconds, the creature wanders toward the
  flock by itself, so something fun always happens. On screen, the creature buttons show a
  grey wedge while they recharge and a sparkle when they're ready.
- **Pause:** press Start. **Grown-ups' settings:** hold Back/Select for a second, or press
  Esc or F1. Settings cover the microphone, chaos timings, flock size and volumes.

### First time: calibrate the microphone

Open the grown-ups' settings with the TV at its usual volume and press **Calibrate**.
It listens to the quiet room for 3 seconds, then plays a few game sounds to learn how
much of the TV leaks into the mic. This stops the game's own barks scaring its own sheep.
The live meter shows:

- green: the room's current loudness
- black line: what the flock is used to
- blue line: the game's own sound
- red line: how loud a sudden noise must be to scare the flock

## Installing on the Steam Machine

Releases are built by GitHub Actions (see "Making a release" below).

1. On the Steam Machine, switch to **Desktop Mode**, sign in to GitHub in the browser and
   download `sheep-vX.Y.Z-linux.tar.gz` from the repository's Releases page.
2. Extract it, open the `sheep` folder in a terminal (Konsole) and run `./install.sh`.
   It installs to `~/Games/sheep`, adds an app-menu entry and, on SteamOS, adds the
   game to Steam (it appears under **Library > Non-Steam**). If it can't, add it by hand:
   Steam > Games > Add a Non-Steam Game to My Library > Sheep!
3. Back in Game Mode, open the game's **controller settings** and pick the **Gamepad**
   layout for the Steam Controllers. This stops the trackpads acting as a mouse.
4. Make sure the USB microphone is the input device in SteamOS (Settings > Audio), or
   choose it in the game's grown-ups' settings. Then calibrate (above).

**Updating:** save a read-only GitHub token once (instructions at the top of
`~/Games/sheep/update.sh`), then run `~/Games/sheep/update.sh` from Desktop Mode.

**Family sounds:** drop `.wav`/`.ogg`/`.mp3` recordings into
`~/.local/share/sheep/family_sounds/<sound>/`. The sound names are `bark`, `baa`, `howl`,
`boing`, `pop`, `ding`, `star` and `fanfare`. They replace the built-in sounds; with
several files in a folder, one is picked at random each time. An `.ogg` or `.mp3` in
`family_sounds/music/` replaces the background music. Press "Reload family sounds"
in settings. These recordings stay on the Steam Machine and are never committed.

## Development

Needs Linux, `make`, `curl` and `unzip`. The Makefile downloads the pinned Godot version into
`.tools/` (checksum-verified) the first time.

```sh
make test       # unit tests (flock, microphone rules, cooldowns, geometry)
make run        # play in a window (keyboard players below)
make demo       # watch robot dogs herd while a robot chaos player causes trouble
make balance    # time three robot rounds headless: a quick check after tuning changes
make shots      # render screenshots without a monitor (slow on software rendering)
make package    # export the Linux build and make the release tarball
```

Keyboard players for testing: **WASD** + Space/E/Q/R, **IJKL** + U/O/Y/P, and
**arrows** + `.` `/` `,` `;`. Enter is Start and Tab is Back on all three.
**F2** and **F3** fake a small and a big shout, and **F12** saves a screenshot.

### Making a release

```sh
git tag v0.2.0
git push origin v0.2.0
```

The Release workflow runs the tests, exports the game and attaches
`sheep-v0.2.0-linux.tar.gz` to a new GitHub release.

## Credits

- [Fredoka](https://github.com/hafontia/Fredoka-One) font: SIL Open Font License, see
  `assets/fonts/Fredoka-OFL.txt`.
- Creature models are built from rounded shapes in code (see `src/visuals/`).
- Sounds and the music loop are synthesised placeholders for now (see `src/audio/synth.gd`).
