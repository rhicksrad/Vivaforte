# MVP Roadmap

## Phase 1 – Core Combat Loop
- [ ] Profile current enemy spawner to confirm baseline difficulty curve.
- [ ] Implement distinct enemy archetypes: chaser, stationary turret, formation flyer.
- [ ] Add encounter scheduler that ramps enemy composition and spawn rates.
- [ ] Wire collision callbacks for player ship, apply damage, and grant invulnerability frames.
- [ ] Author first-pass power-up drops for fire rate, spread shot, and shield pickup.

## Phase 2 – Player Experience
- [ ] Build start menu with control legend and "Press Start" prompt.
- [ ] Add pause overlay with resume, restart, and quit options.
- [ ] Implement game-over screen summarizing score, multipliers, and survival time.
- [ ] Hook up audio events for shooting, explosions, UI, and background music loop.
- [ ] Expand HUD to show player health, active power-ups, and objective hints.

## Phase 3 – Presentation & Feel
- [ ] Swap placeholder sprites with themed player, enemy, projectile, and backdrop art.
- [ ] Layer screen shake, hit flashes, and particles on collision and kills.
- [ ] Finalize CRT post-processing shader toggle with adjustable intensity slider.
- [ ] Tune camera framing and parallax layers for a sense of depth.

## Phase 4 – Progression & Persistence
- [ ] Track score multipliers, combo decay, and persist best scores locally.
- [ ] Script simple mission objectives and narrative blurbs per stage.
- [ ] Serialize player settings (audio, display, controls) to disk.
- [ ] Add minimal save-slot selection for high scores and preferences.

## Phase 5 – Tooling & QA
- [ ] Create automated smoke test covering boot, input, and player movement.
- [ ] Author unit/integration tests for input, movement, collision, and scoring systems.
- [ ] Document developer setup, art pipeline, audio pipeline, and release checklist.
- [ ] Integrate CI job to run tests and package nightly builds.

## Phase 6 – Launch Readiness
- [ ] Package Windows, macOS, and Linux builds with installation docs.
- [ ] Capture gameplay trailer, screenshots, and store copy draft.
- [ ] Schedule external playtests and capture actionable feedback list.
- [ ] Conduct final bug scrub and update changelog for v1.0.0.
