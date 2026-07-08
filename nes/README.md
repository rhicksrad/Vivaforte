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

### Power meter (Gradius-style)

Destroy a full enemy wave and the last ship drops an orange capsule.
Each capsule advances the meter at the bottom of the screen:

`S`peed → `M`issile → `D`ouble → `L`aser → `O`ption → `F`orce

Press **A** to spend the meter on the highlighted upgrade. Options are
trailing drones that mirror your fire; Force is a 3-hit shield. Death
resets all power-ups, Life Force style.

## Game structure

- Scrolling cave terrain (top/bottom walls) generated from a segment table,
  streamed into the nametables one column at a time during vblank.
  Touching a wall is fatal.
- HUD (score / hi-score / lives) lives in a static strip separated from the
  scrolling playfield with a sprite-0 hit mid-frame scroll split.
- Enemy waves come from a data table: sine-wave fans, homing darts,
  terrain-mounted turrets (floor and ceiling) firing aimed shots, and orbs.
- Each loop ends with a 32×32 guardian boss; killing it awards a bonus,
  shows STAGE CLEAR, and restarts the wave table at higher difficulty
  (faster fire rates, tougher boss).
- APU sound: triangle bassline + noise drums + pulse-2 melody, with
  hardware-sweep laser shots, explosions, and pickup jingles on top.

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

`test/smoke.lua` runs under the Mesen 2 test runner and verifies boot,
title, game start, scrolling, and enemy spawns headlessly:

```
Mesen.exe --testrunner nes\build\vivaforte.nes nes\test\smoke.lua
```
