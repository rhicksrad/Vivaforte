# lifeforce-2025-mg

`lifeforce-2025-mg` is a minimalist MonoGame 2D shooter starter project targeting .NET 8 and Windows DesktopGL. It showcases an entity-component-system (ECS) architecture, deterministic bullet patterns, and a lightweight toolchain suitable for rapid iteration.

## Features

- MonoGame 3.8.2 DesktopGL project configured for 1600x900 rendering
- Lightweight ECS with input, movement, shooting, bullet, parallax, render, and HUD systems
- Deterministic randomization for repeatable bullet patterns
- Start, pause, and game-over overlays that surface core controls at a glance
- Configurable CRT post-processing with runtime toggle and intensity controls
- Content pipeline with procedural placeholder art, a system font sprite font, and CRT shader stub
- Packaging script for producing a distributable Windows build

## Getting started

```bash
# Build the game
 dotnet build

# Run the game
 dotnet run --project src/Game
```

The game launches with a scrolling parallax starfield, a controllable player ship, and a simple HUD displaying FPS, lives, and score.

## Gameplay controls

- **Move**: WASD / Arrow Keys / Left Stick
- **Fire**: Space / A / Right Shoulder
- **Focus**: Left or Right Shift / Right Trigger
- **Pause / Resume**: Esc / Start
- **Confirm menus**: Enter / A
- **Toggle CRT**: C / Y
- **Adjust CRT intensity**: `[ ]` keys / D-Pad Left & Right
- **Exit**: Q / Back

## Contributor setup

- Install .NET 8 SDK and MonoGame Content Builder (`dotnet tool install dotnet-mgcb-editor`).
- Clone this repository and initialize submodules (none today, but the command is provided for future use).
- Run `dotnet restore` and `dotnet build` from the repository root to validate your environment.
- Launch the game with `dotnet run --project src/Game` to confirm graphics and input function locally.
- Use an editor with C# analyzers enabled; nullability warnings help catch ECS wiring mistakes early.

## Content pipeline workflow

- Edit assets under `src/Content` and register them inside `Content.mgcb` using the MonoGame Content Builder.
- Run `dotnet mgcb-editor` for a GUI, or `dotnet mgcb /@:src/Content/Content.mgcb /build` for headless builds.
- Keep large binary assets out of Git; prefer procedural placeholders or pack them via release artifacts.
- Update `TextureFactory` helpers when swapping placeholder sprites to ensure runtime generation remains deterministic.
- After adding new content, rebuild the project to ensure the asset pipeline compiles without errors.

## Release checklist

- Bump the version and changelog entries to reflect the feature set included in the build.
- Run `dotnet clean` and `dotnet build -c Release` to generate optimized binaries for verification.
- Execute smoke tests on Windows, macOS (via Metal ANGLE), and Linux to confirm controller and keyboard input paths.
- Package the game with `pwsh tools/pack-win/pack.ps1` (and equivalent scripts per platform) into the `dist/` folder.
- Capture fresh screenshots and short gameplay clips for marketing updates and store page refreshes.

## Tooling

- **Content**: Managed via the MonoGame Content Builder (`Content.mgcb`).
- **Packaging**: Use `pwsh tools/pack-win/pack.ps1` to generate a Windows distribution zip in `dist/`.
- **Continuous Integration**: GitHub Actions workflow validates builds and generates distributable artifacts on Windows runners.

## Fonts

The HUD sprite font is built from the Windows system font **Consolas** at build time. No font binaries are included in this
repository to keep the tree free of binary assets. If Consolas is unavailable on your system, edit
`src/Content/Fonts/Arcade.spritefont` to point at an installed monospace font before building.

## License

This project is released under the MIT License. See [LICENSE](LICENSE) for details.
