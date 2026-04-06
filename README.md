# VKO1 Example Shaders

15 audio-reactive Metal fragment shaders for [VKO1](https://apps.apple.com/app/id6742042648) — a visual performance app for iOS/iPadOS/macOS.

## Shaders

| Shader | Description |
|--------|-------------|
| `aurora` | Northern lights curtains with vertical shimmer and star field |
| `crt_monitor` | Retro CRT screen with scanlines and phosphor glow |
| `diamond_spin` | Rotating 3D diamond with faceted reflections and sparkle |
| `digital_rain` | Matrix-style falling code columns |
| `hex_wave` | Hexagonal tiled surface with beat-reactive wave deformation |
| `kaleidoscope` | Mirror-symmetry kaleidoscope with configurable segments |
| `laser_grid` | Perspective laser grid with beat-synced scan lines |
| `neon_tunnel` | Fly-through polygonal neon tunnel |
| `pixel_warp` | Pixel-art style warp distortion |
| `plasma_orb` | Pulsating energy sphere with electric plasma tendrils |
| `retro_grid` | Synthwave sunset grid |
| `spiral_vortex` | Hypnotic multi-arm spiral with depth illusion |
| `star_warp` | Hyperspace star field with warp streaks |
| `voronoi_glass` | Stained glass Voronoi cells with glowing edges |
| `wireframe_cube` | Rotating wireframe cube |

## Uniforms

All shaders use VKO1's `GeneratorUniforms` struct:

| Uniform | Purpose |
|---------|---------|
| `time` | Continuous time for animation |
| `beatPhase` | 0–1 phase synced to detected beat |
| `beatStrength` | Current beat intensity |
| `energy` | Overall audio energy level |
| `reactivity` | How strongly beats affect the visual |
| `complexity` | Detail level (e.g. number of arms, cells, layers) |
| `speed` | Animation speed multiplier |
| `colorPalette` | Index into 33 built-in cosine color palettes |
| `jogValue` | Manual control value from jog wheel |
| `resolution` | Viewport size in pixels |

## How to use

1. Open VKO1
2. Tap the **Graph Editor**
3. Add a **Custom Shader** node
4. Paste the contents of any `.metal` file into the code editor

## License

MIT — use freely in your own VKO1 performances and projects.
