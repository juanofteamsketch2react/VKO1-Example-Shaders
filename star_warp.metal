// star_warp.metal — Hyperspace star field with warp streaks
//
// Uniforms used:
//   time        → star travel animation
//   beatPhase   → warp pulse timing
//   beatStrength→ speed burst on beat
//   energy      → warp speed and streak length
//   reactivity  → beat → speed burst coupling
//   complexity  → star density and layers
//   speed       → base travel speed
//   colorPalette→ star and streak colors
//   jogValue    → manual depth scroll

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

float hash_sw(float2 p) {
    return fract(sin(dot(p, float2(127.1, 311.7))) * 43758.5453);
}

fragment float4 star_warp(
    VertexOut in [[stage_in]],
    constant GeneratorUniforms &u [[buffer(0)]]
) {
    float2 uv = in.uv - 0.5;
    float aspect = u.resolution.x / u.resolution.y;
    uv.x *= aspect;

    float t = u.time * u.speed;
    float depth = u.jogValue != 0.0 ? u.jogValue * 10.0 + t * 0.5 : t;
    float warpFactor = 0.5 + u.energy * 1.5;
    float beatBurst = u.beatStrength * u.reactivity;
    float pulse = 1.0 + beatBurst * 0.5;

    int layers = 2 + int(u.complexity * 4.0);
    float starDensity = 6.0 + u.complexity * 14.0;

    float3 col = float3(0.0);

    // Multiple star layers at different depths
    for (int layer = 0; layer < layers; layer++) {
        float fl = float(layer);
        float layerDepth = 0.5 + fl * 0.8;
        float layerZ = fract(depth * layerDepth * 0.3 + fl * 0.17);

        // Perspective: stars closer to camera are further from center
        float perspective = 1.0 / (layerZ + 0.1);
        float2 starUV = uv * perspective * (1.0 + fl * 0.3);

        // Grid for star positions
        float2 cell = floor(starUV * starDensity);
        float2 cellUV = fract(starUV * starDensity) - 0.5;

        // Random star position within cell
        float2 starPos = float2(
            hash_sw(cell + fl * 100.0) - 0.5,
            hash_sw(cell.yx + fl * 100.0 + 50.0) - 0.5
        ) * 0.8;

        float2 delta = cellUV - starPos;
        float dist = length(delta);

        // Star brightness based on hash
        float brightness = hash_sw(cell + float2(fl * 37.0, 0.0));
        brightness = pow(brightness, 3.0); // fewer bright stars

        // Streak: elongate stars radially based on warp speed
        float2 radialDir = normalize(starUV + 0.001);
        float streakLen = warpFactor * (1.0 - layerZ) * 0.15;
        streakLen += beatBurst * 0.1 * sin(u.beatPhase * 6.283 + fl);

        // Elliptical distance for streak
        float radialDist = abs(dot(delta, radialDir));
        float perpDist = length(delta - radialDir * dot(delta, radialDir));
        float streakDist = perpDist + radialDist / max(1.0, 1.0 + streakLen * 20.0);

        // Star core + glow
        float starGlow = exp(-streakDist * (40.0 + layerZ * 30.0)) * brightness;
        float starCore = exp(-dist * 120.0) * brightness;

        // Depth fade: closer stars are brighter
        float depthBright = (1.0 - layerZ) * (1.0 - layerZ);

        // Color varies per star
        float colorSeed = hash_sw(cell + float2(0.0, fl * 73.0));
        float3 starColor = get_palette_color(colorSeed + depth * 0.01, u.colorPalette);

        col += starColor * (starGlow * 0.6 + starCore * 1.5) * depthBright * pulse;
    }

    // Central warp glow
    float centerDist = length(uv);
    float warpGlow = exp(-centerDist * (3.0 - u.energy * 1.5)) * 0.1;
    col += get_palette_color(depth * 0.05, u.colorPalette) * warpGlow * pulse;

    // Beat: flash ring expanding from center
    float beatRing = abs(centerDist - u.beatPhase * 0.6);
    float beatGlow = smoothstep(0.05, 0.0, beatRing) * beatBurst;
    col += get_palette_color(u.beatPhase * 0.5, u.colorPalette) * beatGlow * 0.5;

    // Radial streaks at high energy
    float angle = atan2(uv.y, uv.x);
    float radialStreak = pow(abs(sin(angle * 8.0 + depth)), 20.0);
    col += get_palette_color(angle * 0.3, u.colorPalette) * radialStreak * warpFactor * 0.04;

    return float4(col, 1.0);
}
