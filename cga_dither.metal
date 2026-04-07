// cga_dither.metal — CGA / C64 era computer art
//
// Aesthetic: Bold flat palette, 4×4 Bayer ordered dithering, horizontal
// color bands with CGA composite scan-line interference. Inspired by
// early-80s computer art, C64 demos, and CGA landscape screenshots.
//
// Uniforms used:
//   time        → band scroll and animation
//   beatPhase   → band-snap timing
//   beatStrength→ glitch / distortion intensity  ← PRIMARY BEAT DRIVER
//   energy      → interference pattern intensity
//   reactivity  → beat coupling strength
//   complexity  → pixel block size, band count, interference density
//   speed       → scroll speed
//   colorPalette→ CGA palette mode (0-7, 8 sets of 4 colors each)
//   jogValue    → horizontal phase shift / manual scan

#include <metal_stdlib>
using namespace metal;

// ─── 4×4 Bayer ordered-dither threshold ─────────────────────────────────────
float bayer4x4(int x, int y) {
    switch ((y & 3) * 4 + (x & 3)) {
        case  0: return  0.0/16.0; case  1: return  8.0/16.0;
        case  2: return  2.0/16.0; case  3: return 10.0/16.0;
        case  4: return 12.0/16.0; case  5: return  4.0/16.0;
        case  6: return 14.0/16.0; case  7: return  6.0/16.0;
        case  8: return  3.0/16.0; case  9: return 11.0/16.0;
        case 10: return  1.0/16.0; case 11: return  9.0/16.0;
        case 12: return 15.0/16.0; case 13: return  7.0/16.0;
        case 14: return 13.0/16.0; default: return  5.0/16.0;
    }
}

// ─── CGA 16-color hardware palette ──────────────────────────────────────────
float3 cgaColor(int idx) {
    switch (idx & 15) {
        case  0: return float3(0.000, 0.000, 0.000); // black
        case  1: return float3(0.000, 0.000, 0.667); // blue
        case  2: return float3(0.000, 0.667, 0.000); // green
        case  3: return float3(0.000, 0.667, 0.667); // cyan
        case  4: return float3(0.667, 0.000, 0.000); // red
        case  5: return float3(0.667, 0.000, 0.667); // magenta
        case  6: return float3(0.667, 0.333, 0.000); // brown / orange
        case  7: return float3(0.667, 0.667, 0.667); // light gray
        case  8: return float3(0.333, 0.333, 0.333); // dark gray
        case  9: return float3(0.333, 0.333, 1.000); // light blue
        case 10: return float3(0.333, 1.000, 0.333); // lime green
        case 11: return float3(0.333, 1.000, 1.000); // light cyan
        case 12: return float3(1.000, 0.333, 0.333); // light red
        case 13: return float3(1.000, 0.333, 1.000); // light magenta / pink
        case 14: return float3(1.000, 1.000, 0.333); // yellow
        default: return float3(1.000, 1.000, 1.000); // white
    }
}

// ─── 4-color CGA palette subsets (classic hardware mode groups) ──────────────
//  0: C64 beach        — blue, lime, pink, yellow
//  1: CGA mode 1       — black, cyan, magenta, white
//  2: CGA mode 2       — black, green, red, brown
//  3: Electric neon    — black, light blue, light cyan, yellow
//  4: Warm CGA         — brown, red, light red, yellow
//  5: Cool CGA         — blue, cyan, light blue, white
//  6: Acid             — black, lime, pink, white
//  7: C64 sunset       — blue, red, magenta, yellow
float3 paletteLookup(int colorIdx, int mode) {
    const int pals[8][4] = {
        {  1, 10, 13, 14 },
        {  0,  3,  5, 15 },
        {  0,  2,  4,  6 },
        {  0,  9, 11, 14 },
        {  6,  4, 12, 14 },
        {  1,  3,  9, 15 },
        {  0, 10, 13, 15 },
        {  1,  4,  5, 14 },
    };
    return cgaColor(pals[mode % 8][clamp(colorIdx, 0, 3)]);
}

// ─────────────────────────────────────────────────────────────────────────────
fragment float4 cga_dither(VertexOut in [[stage_in]],
                            constant GeneratorUniforms &u [[buffer(0)]]) {

    float2 res = u.resolution;
    float2 fc  = in.uv * res;
    float  t   = u.time * u.speed;
    float  str = u.beatStrength * u.reactivity;
    float  eng = u.energy * u.reactivity;

    // ── Chunky pixel grid ────────────────────────────────────────────────────
    // complexity 0 → 8×8 blocks   complexity 1 → 2×2 blocks
    float pxSize    = max(2.0, mix(8.0, 2.0, u.complexity));
    int2  pixCoord  = int2(floor(fc / pxSize));
    float2 puv      = float2(pixCoord) / floor(res / pxSize); // pixel-snapped 0-1

    // ── Bayer dither threshold ───────────────────────────────────────────────
    float threshold = bayer4x4(pixCoord.x, pixCoord.y); // 0 → ~0.94

    // ── Beat-reactive vertical wave displacement ─────────────────────────────
    float waveAmt = 0.07 * str + 0.015 * eng;
    float xPhase  = puv.x * 5.5 + u.jogValue * 3.14159;
    float dispY   = sin(xPhase + t * 1.3) * waveAmt
                  + sin(xPhase * 2.7 + t * 0.6) * waveAmt * 0.35;

    // Strong beat snaps the bands — gives it that C64 raster-bar feel
    float beatSnap = str * sin(clamp(u.beatPhase * 3.14159, 0.0, 3.14159)) * 0.10;
    float y = puv.y + dispY + beatSnap;

    // ── CGA composite diagonal scan interference ─────────────────────────────
    // Tilted stripes emulate the characteristic CGA composite color fringing
    float diagVal      = fmod(float(pixCoord.y) + float(pixCoord.x) * 0.5, 4.0);
    float scanMask     = (diagVal < 1.5) ? 1.0 : 0.0;
    float scanStrength = (eng * 0.4 + str * 0.25) * (0.3 + u.complexity * 0.7);

    // ── Stacked sinusoidal band field ────────────────────────────────────────
    float bandCount = 2.5 + u.complexity * 4.5;  // 2.5 to 7 visible bands

    // Wavy band edges — adds the organic noise seen in CGA landscape art
    float xWave = sin(puv.x * 7.0 * u.complexity + t * 0.5) * 0.04 * u.complexity
                + cos(puv.x * 19.0 + t * 1.1) * 0.015 * u.complexity;

    // High-frequency interference noise driven by audio energy
    float ifreq = 27.0 + u.complexity * 30.0;
    float ifNoise = sin(puv.x * ifreq + t * 2.5)
                  * sin(puv.y * ifreq * 0.73 + t * 1.9)
                  * eng * 0.35;

    float scroll  = t * 0.12 + u.jogValue * 0.5;
    float bandPos = (y + xWave + ifNoise + scroll) * bandCount;

    // ── Dithered quantization → 4 palette colors ─────────────────────────────
    float sceneVal = fract(bandPos * 0.25); // wrap into 0-1

    // Bayer dithering spread — wider during interference bursts
    float spread   = 0.22 + scanMask * scanStrength * 0.15;
    float dithered = clamp(sceneVal + (threshold - 0.5) * spread, 0.0, 0.9999);

    int colorIdx = int(dithered * 4.0); // 0, 1, 2, 3
    colorIdx = clamp(colorIdx, 0, 3);

    // Scan-line darkens a strip: shifts color one step down = darker band
    if (scanMask > 0.5 && scanStrength > threshold * 0.3) {
        colorIdx = max(0, colorIdx - 1);
    }

    float3 col = paletteLookup(colorIdx, u.colorPalette);

    // ── White flash on strong kick ───────────────────────────────────────────
    float flash = max(0.0, str - 0.80) * 4.0 * step(u.beatPhase, 0.05);
    col = mix(col, float3(1.0), flash * 0.20);

    return float4(col, 1.0);
}
