# VIVAFORTE (NES)

A Life Force / Salamander–style horizontally scrolling shooter written in
pure 6502 assembly for the Nintendo Entertainment System. Builds to a
cartridge-ready iNES ROM: **NROM-256 (mapper 0), 32 KB PRG + 8 KB CHR,
vertical mirroring, NTSC** — no mapper tricks, so it runs on real hardware
or any flash cart (EverDrive, PowerPak) as-is.

## Build

```
powershell -ExecutionPolicy Bypass -File nes\build.ps1
```

Output: `nes/build/vivaforte.nes` (40,976 bytes). Uses `ca65`/`ld65` from
`tools/cc65/bin`; no other dependencies. All graphics are authored as pixel
strings and font bitmaps inside [src/chr.s](src/chr.s) and assembled directly
into the CHR ROM — there is no external asset pipeline.

## Play

Any NES emulator (Mesen recommended) or real hardware via flash cart.

| Input | Action |
|-------|--------|
| D-pad | Move ship |
| B     | Fire (hold for autofire; also launches missiles when armed) |
| A     | Activate the selected power-up |
| Start | Pause / start game |
| Select | (title) start directly on stage 2, the vertical zone |

### Power meter (Gradius-style)

Destroy a full enemy wave and the last ship drops an orange capsule.
Each capsule advances the meter at the bottom of the screen:

`S`peed → `M`issile → `D`ouble → `L`aser → `O`ption → `F`orce

Press **A** to spend the meter on the highlighted upgrade. Missiles are
2-way: each volley sends one hugging the floor and one the ceiling
(in vertical zones, one crawling up each wall). Options are trailing
drones that mirror your fire; Force is a 3-hit shield. Death resets
all power-ups, Life Force style.

## The campaign

Six stages, Life Force style — odd stages scroll horizontally, even
stages scroll **vertically** — each with its own theme, terrain,
wave mix, and guardian:

| # | Zone | Scroll | Guardian |
|---|------|--------|----------|
| 1 | Deep cave (blue) | horizontal | **Guardian Orb** — bobbing core, aimed spreads |
| 2 | Volcanic canyon (red) | vertical | **Golem** — one-eyed stone head, sweeps and spits |
| 3 | Bio cavern (green) | horizontal | **Kraken** — figure-8 squid, tentacle shots + ink jet |
| 4 | Crystal chute (ice) | vertical | **Tetra** — fast-sweeping diamond, shard rings |
| 5 | Fortress (gunmetal) | horizontal | **Bastion** — hunts your altitude; only vulnerable while its armor is open |
| 6 | Final descent (violet) | vertical | **Overmind** — roaming brain, psychic rain |

Difficulty ramps every stage. Clear all six and the **credits roll** —
a victory-lap minigame: open starfield, the staff roll drifting past,
and endless waves of capsule-carrying fans to farm for score before
the game bows out to the title screen.

## Game structure

- Scrolling terrain generated from per-stage segment tables, streamed
  into the nametables during vblank — one column at a time horizontally,
  one row at a time vertically. Touching a wall is fatal.
- The vertical scroll works on stock NROM despite the cart's vertical
  mirroring: the play window is only 224px tall, so 16px of the nametable
  ride hidden behind the HUD and new rows stream into that band. The HUD
  parks in the second nametable and a mid-frame $2006/$2005/$2005/$2006
  write after the sprite-0 split sets the Y scroll.
- HUD (score / hi-score / lives) lives in a static strip separated from the
  scrolling playfield with a sprite-0 hit mid-frame scroll split.
- Enemy waves come from per-stage data tables: sine-wave fans, homing
  darts, terrain-mounted turrets firing aimed shots, and orbs.
- Each stage ends with a 32×32 boss driven by a per-stage movement and
  fire-pattern dispatch. Killing it awards a bonus, shows STAGE CLEAR,
  and moves on.
- APU sound: three 64-step music tracks (horizontal theme, vertical
  theme, credits theme — triangle bass, noise drums, pulse-2 melody)
  with hardware-sweep laser shots, explosions, and pickup jingles on top.

## Source layout (`src/`)

| File | Contents |
|------|----------|
| `main.s` | iNES header, includes, vectors |
| `defs.inc` / `vars.s` | constants, zeropage + BSS layout |
| `reset.s` | power-on init, PPU helpers, controller read |
| `nmi.s` | vblank: OAM DMA, VRAM streaming, sprite-0 scroll split |
| `game.s` | state machine (title/play/clear/game over), wave spawner |
| `player.s` | movement, weapons, power meter, death/respawn |
| `bullets.s` | player/enemy projectiles, missiles, capsules, explosions |
| `enemies.s` / `boss.s` | enemy behaviors, boss fight |
| `collide.s` | AABB collision passes |
| `terrain.s` | cave generator, column streaming, wall collision |
| `hud.s` | score, OAM builder, sprite text |
| `sound.s` | APU music driver + SFX |
| `data.s` | palettes, music patterns, wave table, terrain segments |
| `chr.s` | every tile, drawn as pixel strings / font bitmaps |

## Testing

Headless tests run under the Mesen 2 test runner (exit code 0 = pass):

```
Mesen.exe --testrunner nes\build\vivaforte.nes nes\test\smoke.lua
```

| Script | Covers |
|--------|--------|
| `test/smoke.lua` | boot, title, game start, scrolling, enemy spawns |
| `test/vertical.lua` | stage 2 via SELECT: vertical mode, row streamer, Y-scroll tracking |
| `test/transition.lua` | plays to the stage-1 boss, forces its death, verifies the STAGE CLEAR → vertical stage handoff |
| `test/transition2.lua` | stage 2 via SELECT, reaches the Golem, verifies the vertical → horizontal stage-3 handoff |
| `test/alllevels.lua` | full campaign: all 6 stages and bosses in order, credits minigame, return to title (with screenshots) |
| `test/shots_v.lua` / `shots_h.lua` / `shots_m.lua` | screenshot capture aids (not pass/fail) |

Zero-page addresses in the scripts come from `build/labels.txt`; regenerate
and update them after touching `vars.s`.
