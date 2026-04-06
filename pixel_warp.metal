// pixel_warp.metal — Retro pixelated warp-speed starfield
//
// Uniforms used:
//   time        → star movement
//   beatPhase   → warp pulse timing
//   beatStrength→ warp burst on beat
//   energy      → star density/brightness
//   reactivity  → beat → warp speed coupling
//   complexity  → pixel size (chunky → fine)
//   speed       → base warp speed
//   colorPalette→ star colors
//   jogValue    → manual warp control

#include <metal_stdlib>
using namespace metal;

float3 cosine_palette(float t, float3 a, float3 b, float3 c, float3 d) {
    return a + b * cos(6.283185 * (c * t + d));
}
float3 get_palette_color(float t, int i) {
    switch(i) {
        case 0:  return cosine_palette(t, float3(0.5), float3(0.5), float3(1.0,1.0,1.0), float3(0.00,0.10,0.20));
        case 1:  return cosine_palette(t, float3(0.5), float3(0.5), float3(1.0,1.0,0.5), float3(0.80,0.90,0.30));
        case 2:  return cosine_palette(t, float3(0.5), float3(0.5), float3(1.0,0.7,0.4), float3(0.00,0.15,0.20));
        case 3:  return cosine_palette(t, float3(0.5,0.5,0.8), float3(0.4,0.4,0.2), float3(1.0), float3(0.00,0.33,0.67));
        case 4:  return cosine_palette(t, float3(0.5), float3(0.5), float3(1.0,0.7,0.4), float3(0.30,0.20,0.20));
        case 5:  return cosine_palette(t, float3(0.5), float3(0.5), float3(2.0,1.0,0.0), float3(0.50,0.20,0.25));
        case 6:  return cosine_palette(t, float3(0.5), float3(0.5), float3(1.0), float3(0.0));
        case 7:  return cosine_palette(t, float3(0.5), float3(0.5), float3(1.0), float3(0.00,0.33,0.67));
        case 8:  return cosine_palette(t, float3(0.2,0.6,0.0), float3(0.3,0.5,0.2), float3(1.0,1.5,0.5), float3(0.00,0.05,0.30));
        case 9:  return cosine_palette(t, float3(0.6,0.1,0.1), float3(0.5,0.3,0.3), float3(1.0,0.5,0.5), float3(0.00,0.10,0.30));
        case 10: return cosine_palette(t, float3(0.2,0.2,0.8), float3(0.5,0.5,0.5), float3(1.0,1.0,2.0), float3(0.10,0.20,0.00));
        case 11: return cosine_palette(t, float3(0.6,0.3,0.0), float3(0.5,0.4,0.3), float3(1.5,1.0,0.5), float3(0.00,0.05,0.10));
        case 12: return cosine_palette(t, float3(0.4,0.0,0.6), float3(0.5,0.3,0.5), float3(1.5,0.5,2.0), float3(0.30,0.20,0.00));
        case 13: return cosine_palette(t, float3(0.8,0.4,0.5), float3(0.5,0.5,0.5), float3(1.0,1.0,1.0), float3(0.00,0.15,0.50));
        case 14: return cosine_palette(t, float3(0.0,0.4,0.0), float3(0.1,0.5,0.1), float3(0.5,1.5,0.5), float3(0.0));
        case 15: return cosine_palette(t, float3(0.7,0.4,0.2), float3(0.6,0.5,0.4), float3(1.0,0.8,0.5), float3(0.00,0.05,0.15));
        case 16: return cosine_palette(t, float3(0.4,0.0,0.0), float3(0.4,0.1,0.1), float3(1.0,0.3,0.3), float3(0.0));
        case 17: return cosine_palette(t, float3(0.0,0.0,0.4), float3(0.1,0.1,0.5), float3(0.3,0.3,1.0), float3(0.0));
        case 18: return cosine_palette(t, float3(0.0,0.3,0.0), float3(0.1,0.5,0.1), float3(0.3,1.0,0.3), float3(0.0));
        case 19: return cosine_palette(t, float3(0.3,0.0,0.4), float3(0.3,0.1,0.5), float3(0.8,0.3,1.0), float3(0.0));
        case 20: return cosine_palette(t, float3(0.4,0.2,0.0), float3(0.5,0.3,0.1), float3(1.0,0.6,0.2), float3(0.0));
        case 21: return cosine_palette(t, float3(0.0,0.3,0.4), float3(0.1,0.4,0.5), float3(0.2,1.0,1.0), float3(0.0));
        case 22: return cosine_palette(t, float3(0.4,0.0,0.2), float3(0.5,0.1,0.3), float3(1.0,0.2,0.6), float3(0.0));
        case 23: return cosine_palette(t, float3(0.5,0.5,0.5), float3(0.5,0.5,0.3), float3(1.0,0.7,0.7), float3(0.00,0.15,0.40));
        case 24: return cosine_palette(t, float3(0.0,0.3,0.5), float3(0.3,0.4,0.4), float3(0.5,1.0,1.0), float3(0.20,0.10,0.00));
        case 25: return cosine_palette(t, float3(0.8,0.7,0.8), float3(0.2,0.2,0.2), float3(1.0), float3(0.00,0.10,0.20));
        case 26: return cosine_palette(t, float3(0.5,0.3,0.15), float3(0.4,0.3,0.2), float3(1.0,0.7,0.4), float3(0.00,0.05,0.10));
        case 27: return cosine_palette(t, float3(0.3,0.5,0.4), float3(0.4,0.4,0.4), float3(1.0,1.0,1.5), float3(0.00,0.20,0.50));
        case 28: return cosine_palette(t, float3(0.6,0.4,0.4), float3(0.4,0.3,0.3), float3(1.0,0.8,0.6), float3(0.00,0.10,0.25));
        case 29: return cosine_palette(t, float3(0.1,0.1,0.3), float3(0.3,0.3,0.5), float3(0.5,0.5,1.5), float3(0.25,0.25,0.00));
        case 30: return cosine_palette(t, float3(0.5,0.25,0.1), float3(0.4,0.3,0.2), float3(1.2,0.6,0.3), float3(0.00,0.10,0.20));
        case 31: return cosine_palette(t, float3(0.5), float3(0.5), float3(1.5), float3(0.30,0.20,0.10));
        case 32: return cosine_palette(t, float3(0.45,0.55,0.30), float3(0.55,0.50,0.50), float3(1.0,0.8,1.2), float3(0.00,0.15,0.35));
        default: return cosine_palette(t, float3(0.5), float3(0.5), float3(1.0), float3(0.00,0.10,0.20));
    }
}

float hash(float2 p) {
    return fract(sin(dot(p, float2(127.1, 311.7))) * 43758.5453);
}
float2 hash2(float2 p) {
    p = float2(dot(p, float2(127.1, 311.7)), dot(p, float2(269.5, 183.3)));
    return fract(sin(p) * 43758.5453);
}

fragment float4 pixel_warp(
    VertexOut in [[stage_in]],
    constant GeneratorUniforms &u [[buffer(0)]]
) {
    float2 uv = in.uv;
    float aspect = u.resolution.x / u.resolution.y;
    float t = u.time * u.speed;
    float warp = u.jogValue != 0.0 ? abs(u.jogValue) * 3.0 : 1.0;

    // Pixelation — larger pixels at low complexity
    float pixelSize = mix(64.0, 320.0, u.complexity);
    float2 pixUV = floor(uv * pixelSize) / pixelSize;

    // Center-relative for radial warp
    float2 centered = pixUV - 0.5;
    centered.x *= aspect;
    float dist = length(centered);

    float pulse = 1.0 + u.beatStrength * u.reactivity * 0.8;

    // --- Layer multiple star fields at different depths ---
    float3 col = float3(0.0);
    for (int layer = 0; layer < 4; layer++) {
        float layerF = float(layer);
        float layerSpeed = (1.0 + layerF * 0.8) * warp;
        float layerPhase = fract(t * layerSpeed * 0.3 + layerF * 0.25);

        // Stars fly outward from center
        float zoom = 0.1 + layerPhase * 2.0;
        float2 starUV = centered / zoom;

        // Quantize for pixel look
        float starPix = pixelSize * 0.3;
        starUV = floor(starUV * starPix) / starPix;

        // Star placement via hash
        float2 starID = floor(starUV * 8.0);
        float2 starRand = hash2(starID + layerF * 100.0);

        // Only some cells have stars
        float hasStar = step(0.6 - u.energy * 0.2, starRand.x);

        // Star brightness: brighter as it zooms out, fades at edges
        float brightness = smoothstep(0.0, 0.3, layerPhase) *
                          smoothstep(1.0, 0.6, layerPhase);

        // Streak effect: elongate in radial direction during warp
        float streakLen = layerPhase * 0.5 * warp;
        float2 cellUV = fract(starUV * 8.0) - 0.5;
        float radialDot = abs(dot(normalize(centered + 0.001), normalize(cellUV)));
        float streak = smoothstep(streakLen, 0.0, length(cellUV)) *
                      (1.0 + radialDot * streakLen * 4.0);

        float star = hasStar * brightness * streak;

        // Color each layer differently
        float3 starColor = get_palette_color(layerF * 0.25 + starRand.y * 0.3, u.colorPalette);
        col += starColor * star * pulse * 0.5;
    }

    // Beat flash — radial burst
    float burstDist = length(pixUV - 0.5);
    float burstRing = abs(fract(burstDist * 3.0 - u.beatPhase) - 0.5);
    float burst = smoothstep(0.15, 0.0, burstRing) * u.beatStrength * u.reactivity * 0.4;
    col += get_palette_color(u.beatPhase, u.colorPalette) * burst;

    // Center glow
    float centerGlow = exp(-dist * 5.0) * 0.2 * pulse;
    col += get_palette_color(0.9, u.colorPalette) * centerGlow;

    return float4(col, 1.0);
}
