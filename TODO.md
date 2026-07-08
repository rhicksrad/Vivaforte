# MVP Roadmap

## NES version (nes/ — VIVAFORTE)
- [x] Cartridge-ready iNES ROM (NROM-256) built from pure 6502 assembly with ca65/ld65.
- [x] Scrolling cave terrain, sprite-0 HUD split, wave spawner, Gradius-style power meter, boss loop, APU music/SFX.
- [x] Headless Mesen 2 test harness (`nes/test/smoke.lua`).
- [x] Second stage theme (new terrain segment table + palette swap).
- [x] Vertical-scrolling stage variant like Life Force's even-numbered zones
      (done NROM-style: single-nametable Y scroll + row streaming into the
      16px band hidden behind the HUD; no mirroring change needed).
- [x] Full six-stage campaign: per-stage themes/terrain/waves and six
      distinct bosses (Orb, Golem, Kraken, Tetra, Bastion, Overmind).
- [x] Credits minigame after stage 6 (staff roll + shooting gallery).
- [x] Three 64-step music tracks (horizontal / vertical / credits).
- [ ] Two-player alternating mode.

## Core Gameplay
- Implement multiple enemy ship behaviors (basic chaser, turret, and formation flyer).
- Add enemy wave scheduler with escalating difficulty over time.
- Introduce collision-driven player damage and temporary invulnerability frames.
- Provide power-up drops that enhance fire rate, spread, or grant shields.

## Player Experience
- Implement audio cues for shooting, explosions, UI interactions, and background music.
- Expand HUD with health, power-up status, and objective messaging.

## Content & Visuals
- Replace placeholder sprites with themed player, enemy, projectile, and background art.
- Add screen shake, hit flashes, and particle effects for combat feedback.

## Progression & Scoring
- Track score multipliers, combos, and persistent high-score table.
- Add mission objectives and simple narrative framing for stages.
- Implement basic save data for settings and high scores.

## Tooling & QA
- Set up automated gameplay smoke test that validates launch and basic movement.
- Add unit or integration tests for critical ECS systems (input, movement, collision).

## Release Readiness
- Package cross-platform builds (Windows, macOS, Linux) with instructions.
- Prepare marketing assets: gameplay trailer, screenshots, and store description draft.
- Conduct playtest sessions and compile feedback for final polish pass.
