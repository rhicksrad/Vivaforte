# MVP Roadmap

## Core Gameplay
- Implement multiple enemy ship behaviors (basic chaser, turret, and formation flyer).
- Add enemy wave scheduler with escalating difficulty over time.
- Introduce collision-driven player damage and temporary invulnerability frames.
- Provide power-up drops that enhance fire rate, spread, or grant shields.

## Player Experience
- Create start, pause, and game-over screens with clear controls and feedback.
- Implement audio cues for shooting, explosions, UI interactions, and background music.
- Expand HUD with health, power-up status, and objective messaging.

## Content & Visuals
- Replace placeholder sprites with themed player, enemy, projectile, and background art.
- Add screen shake, hit flashes, and particle effects for combat feedback.
- Integrate CRT post-processing shader toggle with configurable intensity.

## Progression & Scoring
- Track score multipliers, combos, and persistent high-score table.
- Add mission objectives and simple narrative framing for stages.
- Implement basic save data for settings and high scores.

## Tooling & QA
- Set up automated gameplay smoke test that validates launch and basic movement.
- Add unit or integration tests for critical ECS systems (input, movement, collision).
- Document contributor setup, content pipeline workflow, and release checklist.

## Release Readiness
- Package cross-platform builds (Windows, macOS, Linux) with instructions.
- Prepare marketing assets: gameplay trailer, screenshots, and store description draft.
- Conduct playtest sessions and compile feedback for final polish pass.
