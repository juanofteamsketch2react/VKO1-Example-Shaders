// retro_grid.metal — Synthwave perspective grid with horizon sun
//
// Uniforms used:
//   time        → grid scroll speed
//   beatPhase   → sun pulse sync
//   energy      → grid brightness boost
//   reactivity  → how much beat affects grid glow
//   complexity  → number of grid lines (sparse → dense)
//   speed       → overall animation speed
//   colorPalette→ palette for grid + sun colors
//   jogValue    → manual scroll override

#include <metal_stdlib>
using namespace metal;

// --- VKO1 palette helpers (all 33 built-in palettes) ---
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

fragment float4 retro_grid(
    VertexOut in [[stage_in]],
    constant GeneratorUniforms &u [[buffer(0)]]
) {
    float2 uv = in.uv;
    float aspect = u.resolution.x / u.resolution.y;

    // Horizon line at 40% from top
    float horizon = 0.4;
    float3 col = float3(0.0);

    float t = u.time * u.speed;
    float scroll = u.jogValue != 0.0 ? u.jogValue * 4.0 : t;
    float pulse = 1.0 + u.energy * u.reactivity * 0.6;

    // --- Sky: gradient + sun ---
    if (uv.y < horizon) {
        // Dark sky gradient
        float skyGrad = uv.y / horizon;
        float3 skyTop = get_palette_color(0.7, u.colorPalette) * 0.1;
        float3 skyBot = get_palette_color(0.3, u.colorPalette) * 0.3;
        col = mix(skyTop, skyBot, skyGrad);

        // Sun circle
        float2 sunPos = float2(0.5, horizon * 0.55);
        float2 sunUV = float2((uv.x - sunPos.x) * aspect, uv.y - sunPos.y);
        float sunDist = length(sunUV);
        float sunRadius = 0.12 + 0.015 * sin(u.beatPhase * 6.2831);
        float sunGlow = smoothstep(sunRadius + 0.04, sunRadius, sunDist);
        float3 sunColor = get_palette_color(0.1, u.colorPalette);

        // Horizontal scanline stripes through sun
        float stripe = step(0.5, fract(uv.y * 30.0));
        float sunBody = smoothstep(sunRadius, sunRadius - 0.005, sunDist);
        sunBody *= mix(1.0, stripe, smoothstep(sunPos.y - sunRadius, sunPos.y + sunRadius * 0.5, uv.y));

        col += sunColor * sunBody * 1.5;
        col += sunColor * sunGlow * 0.4 * pulse;

        // Sun haze
        float haze = exp(-sunDist * 4.0) * 0.3;
        col += get_palette_color(0.2, u.colorPalette) * haze;
    }

    // --- Ground: perspective grid ---
    if (uv.y >= horizon) {
        float groundV = (uv.y - horizon) / (1.0 - horizon); // 0 at horizon → 1 at bottom

        // Perspective depth: map groundV to world Z
        float depth = 0.1 / (groundV + 0.001);

        // Grid world coordinates
        float worldX = (uv.x - 0.5) * aspect * depth;
        float worldZ = depth - scroll * 2.0;

        // Grid line density driven by complexity
        float gridScale = 2.0 + u.complexity * 6.0;
        float lineX = abs(fract(worldX * gridScale) - 0.5);
        float lineZ = abs(fract(worldZ * gridScale) - 0.5);

        // Sharper lines close, faded far away
        float lineWidth = 0.02 + 0.03 * groundV;
        float gridX = 1.0 - smoothstep(0.0, lineWidth, lineX);
        float gridZ = 1.0 - smoothstep(0.0, lineWidth, lineZ);
        float grid = max(gridX, gridZ);

        // Fade with distance
        float distanceFade = exp(-groundV * 0.5);
        grid *= distanceFade;

        // Color the grid
        float3 gridColor = get_palette_color(0.5 + groundV * 0.3, u.colorPalette);
        col = gridColor * grid * pulse * 0.8;

        // Add slight ground fog near horizon
        float fog = exp(-groundV * 3.0) * 0.15;
        col += get_palette_color(0.3, u.colorPalette) * fog;
    }

    // Vignette
    float2 vig = uv - 0.5;
    col *= 1.0 - dot(vig, vig) * 0.8;

    return float4(col, 1.0);
}
