# VKO1 Example Shaders

![VKO1 Shader Sampler](vko1-shader-lib-sampler.gif)

24 audio-reactive Metal fragment shaders for [VKO1](https://temperamento.net/vko1/) — a visual performance app for iOS/iPadOS/macOS.

## Shaders

| Shader | Description |
|--------|-------------|
| `aurora` | Northern lights curtains with vertical shimmer and star field |
| `biocore_monitor` | Biolab contamination monitor — ECG lines, hex cell panels, DNA readouts, organ status rings on black |
| `cga_dither` | CGA/C64 era computer art — bold flat palette, Bayer ordered dithering, horizontal bands with scan-line interference |
| `crt_monitor` | Retro CRT screen with scanlines and phosphor glow |
| `crt_tunnel` | Phosphor-green terminal wireframe dungeon tunnel with CRT scanlines and beat-flaring glitch artifacts |
| `diamond_spin` | Rotating 3D diamond with faceted reflections and sparkle |
| `digital_rain` | Matrix-style falling code columns |
| `hex_wave` | Hexagonal tiled surface with beat-reactive wave deformation |
| `holo_hud` | Sci-fi holographic HUD with tactical reticle, hex overlays, and scan-line glitches |
| `kaleidoscope` | Mirror-symmetry kaleidoscope with configurable segments |
| `laser_grid` | Perspective laser grid with beat-synced scan lines |
| `neon_tunnel` | Fly-through polygonal neon tunnel |
| `nihon_grid` | Japanese rock poster — crimson perspective grid tunnel with bold SDF kanji blocks and EKG divider strip |
| `pixel_warp` | Pixel-art style warp distortion |
| `plasma_orb` | Pulsating energy sphere with electric plasma tendrils |
| `retro_grid` | Synthwave sunset grid |
| `signal_intercept` | Cold-war signals intelligence terminal — radar sweeps, spectrum columns, waveform decoders, targeting reticles |
| `spiral_vortex` | Hypnotic multi-arm spiral with depth illusion |
| `star_warp` | Hyperspace star field with warp streaks |
| `synth-city` | Neon synthwave cityscape with scrolling road, city skyline, and beat-driven bloom |
| `system_crash_hud` | SYSTEM FAILURE glitch diagnostic HUD — dense neon info panels on black with cascading error readouts |
| `tech_diag_hud` | Technical diagnostic readout — circuit schematic art, human silhouette with measurement overlays, radial gauges |
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
| `colorPalette` | Index into 33 built-in cosine color palettes (0 = Custom for custom shaders) |
| `jogValue` | Manual control value from jog wheel |
| `resolution` | Viewport size in pixels |

## Requirements

**VKO1 beta 1.20 or later** is required for custom shader support.

## How to use

1. Open VKO1
2. Tap the **Graph Editor**
3. Add a **Custom Shader** node
4. Paste the contents of any `.metal` file into the code editor

For full documentation on the Graph Editor and custom shaders, see the [Graph Editor docs](https://temperamento.net/vko1/grapheditor.html).

## License

MIT — use freely in your own VKO1 performances and projects.
