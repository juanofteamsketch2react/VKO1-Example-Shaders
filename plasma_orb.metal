// plasma_orb.metal — Pulsating energy orb with electric plasma tendrils
//
// Uniforms used:
//   time        → plasma flow animation
//   beatPhase   → tendril pulse timing
//   beatStrength→ orb flash intensity
//   energy      → orb size and brightness
//   reactivity  → beat → plasma coupling
//   complexity  → number of plasma tendrils and noise octaves
//   speed       → plasma flow speed
//   colorPalette→ plasma color scheme
//   jogValue    → manual plasma rotation

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

// Simplex-style noise for plasma flow
float plasma_noise(float2 p, float t) {
    float2 i = floor(p);
    float2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);

    float a = sin(dot(i, float2(127.1, 311.7)) + t) * 43758.5453;
    float b = sin(dot(i + float2(1,0), float2(127.1, 311.7)) + t) * 43758.5453;
    float c = sin(dot(i + float2(0,1), float2(127.1, 311.7)) + t) * 43758.5453;
    float d = sin(dot(i + float2(1,1), float2(127.1, 311.7)) + t) * 43758.5453;

    return mix(mix(fract(a), fract(b), f.x),
               mix(fract(c), fract(d), f.x), f.y);
}

float fbm_plasma(float2 p, float t, int octaves) {
    float val = 0.0;
    float amp = 0.5;
    float freq = 1.0;
    for (int i = 0; i < octaves; i++) {
        val += amp * plasma_noise(p * freq, t + float(i) * 1.37);
        freq *= 2.0;
        amp *= 0.5;
    }
    return val;
}

fragment float4 plasma_orb(
    VertexOut in [[stage_in]],
    constant GeneratorUniforms &u [[buffer(0)]]
) {
    float2 uv = in.uv - 0.5;
    float aspect = u.resolution.x / u.resolution.y;
    uv.x *= aspect;

    float t = u.time * u.speed;
    float jogRot = u.jogValue * 6.283;
    float pulse = 1.0 + u.energy * u.reactivity * 0.6;

    float radius = length(uv);
    float angle = atan2(uv.y, uv.x) + jogRot;

    // Orb size breathes with energy
    float orbSize = 0.18 + u.energy * 0.06;
    float orbDist = radius - orbSize;

    // Plasma tendrils count from complexity
    float tendrilCount = floor(3.0 + u.complexity * 8.0);
    int octaves = 2 + int(u.complexity * 4.0);

    // Tendril distortion using fbm
    float plasmaField = fbm_plasma(
        float2(angle * tendrilCount / 6.283, radius * 4.0),
        t * 0.8, octaves
    );

    // Tendrils extend outward from orb
    float tendrilReach = 0.15 + u.energy * 0.1 + u.beatStrength * u.reactivity * 0.08;
    float tendrilShape = plasmaField * tendrilReach;
    float tendrilDist = orbDist - tendrilShape;

    // Core orb glow
    float coreGlow = exp(-max(0.0, orbDist) * 20.0);
    float innerCore = exp(-radius * 12.0);

    // Tendril glow
    float tendrilGlow = exp(-max(0.0, tendrilDist) * 8.0);

    // Beat pulse: expanding ring
    float beatRing = abs(radius - orbSize - u.beatPhase * 0.4);
    float beatGlow = smoothstep(0.04, 0.0, beatRing) * u.beatStrength * u.reactivity;

    // Surface crackling (visible on the orb surface)
    float surfaceCrackle = fbm_plasma(
        float2(angle * 3.0, radius * 10.0 - t * 2.0),
        t * 2.0, 3
    );
    float surfaceDetail = smoothstep(0.4, 0.6, surfaceCrackle) * coreGlow;

    // Colors
    float3 coreColor = get_palette_color(t * 0.05, u.colorPalette);
    float3 tendrilColor = get_palette_color(plasmaField + t * 0.1, u.colorPalette);
    float3 beatColor = get_palette_color(u.beatPhase * 0.5, u.colorPalette);
    float3 crackleColor = get_palette_color(surfaceCrackle + 0.5, u.colorPalette);

    float3 col = float3(0.0);

    // Inner core (bright white-ish center)
    col += (coreColor * 0.5 + 0.5) * innerCore * 2.0 * pulse;

    // Orb body
    col += coreColor * coreGlow * pulse * 0.8;

    // Surface detail
    col += crackleColor * surfaceDetail * 0.6;

    // Tendrils
    col += tendrilColor * tendrilGlow * 0.7 * pulse;

    // Beat ring
    col += beatColor * beatGlow * 1.5;

    // Ambient background glow
    float ambientGlow = exp(-radius * 3.0) * 0.08;
    col += get_palette_color(0.7, u.colorPalette) * ambientGlow;

    return float4(col, 1.0);
}
