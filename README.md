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
  Esc or F1. Settings cover the microphone, chaos timings, flock size and volumes. In
  menus, the D-pad moves, the bottom face button picks, and the right one goes back.

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
   game to Steam (it appears under **Library > Non-Steam**) along with its library
   artwork, which Steam shows after its next restart. If it can't add the game, add it
   by hand: Steam > Games > Add a Non-Steam Game to My Library > Sheep!
3. Back in Game Mode, open the game's **controller settings** and pick the **Gamepad**
   layout for the Steam Controllers. This stops the trackpads acting as a mouse.
4. Make sure the USB microphone is the input device in SteamOS (Settings > Audio), or
   choose it in the game's grown-ups' settings. Then calibrate (above).

**Updating:** run `~/Games/sheep/update.sh` (from Desktop Mode, or over SSH). It
downloads the newest release and reinstalls.

**Family sounds:** drop `.wav`/`.ogg`/`.mp3` recordings into
`~/.local/share/sheep/family_sounds/<sound>/`. The sound names are `bark`, `baa`, `howl`,
`boing`, `land`, `pop`, `ding`, `star`, `fanfare`, `whoosh` and `tick`. They replace the
built-in sounds; with several files in a folder, one is picked at random each time.
For music, put `menu.ogg` (join screen) and/or `round.ogg` (playing) in
`family_sounds/music/`; a single file of any name is used for both. Press "Reload family sounds"
in settings. These recordings stay on the Steam Machine and are never committed.

### If something isn't working

**Grown-ups' settings > This machine** lists the GPU, screen, the controllers the
game can see and the microphone's state.

- If the shout button (the sheep at the bottom left during a round) is crossed out, the
  microphone wasn't found or hasn't sent any sound yet. Check it's plugged in, switched
  on (wireless mics have a transmitter) and not muted, then shout once.
- The game only sees Steam Controllers when Steam launches it, so start it from the
  Steam library rather than from Desktop Mode's app menu.

## Development

Needs Linux, `make`, `curl` and `unzip`. The Makefile downloads the pinned Godot version into
`.tools/` (checksum-verified) the first time.

```sh
make test       # unit tests (flock, microphone rules, cooldowns, geometry)
make run        # play in a window (keyboard players below)
make demo       # watch robot dogs herd while a robot chaos player causes trouble
make balance    # time three robot rounds headless: a quick check after tuning changes
make smoke      # export the game and click through every screen in it: run before a release
make shots      # render screenshots without a monitor (slow on software rendering)
make models     # rebuild the creature models with Blender
make sounds     # rebuild the CC0 sounds and music with ffmpeg
make artwork    # render the Steam library artwork from the game
make package    # export the Linux build and make the release tarball
```

`make demo DEMO=gallery` lines up every creature close to the camera, for checking models.

Keyboard players for testing: **WASD** + Space/E/Q/R, **IJKL** + U/O/Y/P, and
**arrows** + `.` `/` `,` `;`. Enter is Start and Tab is Back on all three.
**F2** and **F3** fake a small and a big shout, and **F12** saves a screenshot.

### Testing on the Steam Machine over SSH

Steam can't easily pass options to a non-Steam game, so for one launch the game also
reads them from `~/.local/share/sheep/next_launch_args.txt` (the file is deleted
once read):

```sh
ssh deck@steam-machine
echo '--diagnose --demo=round --shots=5,20 --quit-at=30' > ~/.local/share/sheep/next_launch_args.txt
steam steam://rungameid/<id>   # or start it from the library
cat ~/.local/share/sheep/diagnostics.txt   # GPU, frame rate, controllers and presses, microphone
```

Screenshots land in `~/.local/share/sheep/screenshots/` (F12 saves one any time).

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
- Creature models are generated in Blender by `tools/blender/build_models.py`.
- Music and sound effects are public domain (CC0). Music is "Children's March Theme" by
  Cleyton Kauffman and "Flowerbed Fields" by Zane Little Music (both on OpenGameArt).
  Sound effects are by Freesound contributors and Kenney. The full list is in
  [assets/audio/CREDITS.md](assets/audio/CREDITS.md).
