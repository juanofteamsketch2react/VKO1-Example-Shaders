// spiral_vortex.metal — Hypnotic multi-arm spiral with depth illusion
//
// Uniforms used:
//   time        → spiral rotation
//   beatPhase   → spiral pulse wave
//   beatStrength→ arm flash intensity
//   energy      → spiral brightness and arm width
//   reactivity  → beat → rotation burst coupling
//   complexity  → number of spiral arms and detail
//   speed       → rotation speed
//   colorPalette→ arm color scheme
//   jogValue    → manual rotation

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

fragment float4 spiral_vortex(
    VertexOut in [[stage_in]],
    constant GeneratorUniforms &u [[buffer(0)]]
) {
    float2 uv = in.uv - 0.5;
    float aspect = u.resolution.x / u.resolution.y;
    uv.x *= aspect;

    float t = u.time * u.speed;
    float jogRot = u.jogValue * 6.283;
    float pulse = 1.0 + u.energy * u.reactivity * 0.5;

    float radius = length(uv);
    float angle = atan2(uv.y, uv.x);

    // Number of spiral arms from complexity
    float arms = floor(2.0 + u.complexity * 8.0);
    float spiralTightness = 3.0 + u.complexity * 5.0;

    // Spiral equation: angle offset based on radius
    float spiralAngle = angle * arms - radius * spiralTightness * 6.283 + t * 2.0 + jogRot;

    // Primary spiral pattern
    float spiral = sin(spiralAngle) * 0.5 + 0.5;
    spiral = pow(spiral, 1.5 - u.energy * 0.5); // sharper arms at low energy

    // Secondary inner spiral (counter-rotating)
    float innerSpiral = sin(-angle * (arms + 1.0) + radius * spiralTightness * 4.0 - t * 3.0) * 0.5 + 0.5;
    innerSpiral *= smoothstep(0.35, 0.0, radius); // only visible near center

    // Depth rings along the spiral
    float rings = sin(radius * 20.0 - t * 4.0) * 0.5 + 0.5;
    rings = smoothstep(0.3, 0.7, rings);

    // Beat pulse: spiral arms flash outward
    float beatSpiral = sin(spiralAngle - u.beatPhase * 6.283 * 2.0) * 0.5 + 0.5;
    beatSpiral *= smoothstep(0.5, 0.0, abs(radius - u.beatPhase * 0.5));
    beatSpiral *= u.beatStrength * u.reactivity;

    // Radial fade
    float radialFade = exp(-radius * 2.5);

    // Colors
    float colorParam = spiral * 0.5 + radius * 0.3;
    float3 spiralColor = get_palette_color(colorParam + t * 0.03, u.colorPalette);
    float3 innerColor = get_palette_color(colorParam + 0.5, u.colorPalette);
    float3 ringColor = get_palette_color(radius * 2.0, u.colorPalette);
    float3 beatColor = get_palette_color(u.beatPhase + 0.3, u.colorPalette);

    float3 col = float3(0.0);

    // Main spiral arms
    col += spiralColor * spiral * radialFade * pulse * 0.8;

    // Depth rings overlay
    col += ringColor * rings * radialFade * 0.2;

    // Inner counter-spiral
    col += innerColor * innerSpiral * 1.2 * pulse;

    // Beat flash
    col += beatColor * beatSpiral * 1.0;

    // Center glow
    float centerGlow = exp(-radius * 10.0);
    col += get_palette_color(t * 0.08, u.colorPalette) * centerGlow * 1.5 * pulse;

    // Outer edge glow (vortex rim)
    float rimDist = abs(radius - 0.45);
    float rim = smoothstep(0.05, 0.0, rimDist) * 0.3;
    col += get_palette_color(angle * 0.3 + t * 0.1, u.colorPalette) * rim * pulse;

    // Vignette
    float2 vig = in.uv - 0.5;
    col *= 1.0 - dot(vig, vig) * 0.5;

    return float4(col, 1.0);
}
