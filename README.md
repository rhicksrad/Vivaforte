# lifeforce-2025-mg

`lifeforce-2025-mg` is a minimalist MonoGame 2D shooter starter project targeting .NET 8 and Windows DesktopGL. It showcases an entity-component-system (ECS) architecture, deterministic bullet patterns, and a lightweight toolchain suitable for rapid iteration.

## Features

- MonoGame 3.8.2 DesktopGL project configured for 1600x900 rendering
- Lightweight ECS with input, movement, shooting, bullet, parallax, render, and HUD systems
- Deterministic randomization for repeatable bullet patterns
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
