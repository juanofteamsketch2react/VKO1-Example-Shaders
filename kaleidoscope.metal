// kaleidoscope.metal — Mirror-symmetry kaleidoscope with flowing patterns
//
// Uniforms used:
//   time        → pattern rotation and flow
//   beatPhase   → pattern pulse sync
//   beatStrength→ flash intensity on beat
//   energy      → pattern brightness and zoom
//   reactivity  → beat → pattern warp coupling
//   complexity  → number of mirror segments (3–16)
//   speed       → rotation and flow speed
//   colorPalette→ pattern color scheme
//   jogValue    → manual rotation offset

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

fragment float4 kaleidoscope(
    VertexOut in [[stage_in]],
    constant GeneratorUniforms &u [[buffer(0)]]
) {
    float2 uv = in.uv - 0.5;
    float aspect = u.resolution.x / u.resolution.y;
    uv.x *= aspect;

    float t = u.time * u.speed;
    float jogRot = u.jogValue * 6.283;
    float pulse = 1.0 + u.energy * u.reactivity * 0.4;

    // Rotate the whole view slowly
    float globalRot = t * 0.15 + jogRot;
    float ca = cos(globalRot);
    float sa = sin(globalRot);
    uv = float2(uv.x * ca - uv.y * sa, uv.x * sa + uv.y * ca);

    // Mirror segments from complexity
    float segments = floor(3.0 + u.complexity * 13.0);
    float sectorAngle = 6.283185 / segments;

    // Convert to polar
    float angle = atan2(uv.y, uv.x);
    float radius = length(uv);

    // Fold into one sector, then mirror
    float sector = fmod(angle + 3.14159, sectorAngle);
    if (sector > sectorAngle * 0.5) sector = sectorAngle - sector;

    // Back to cartesian in folded space
    float2 folded = float2(cos(sector), sin(sector)) * radius;

    // Zoom with energy
    float zoom = 2.0 + u.energy * 1.5;
    folded *= zoom;

    // Flowing pattern: layered sine waves
    float pattern = 0.0;
    pattern += sin(folded.x * 4.0 + t * 1.2) * 0.5;
    pattern += sin(folded.y * 5.0 - t * 0.9) * 0.4;
    pattern += sin((folded.x + folded.y) * 3.0 + t * 0.7) * 0.3;
    pattern += sin(length(folded) * 6.0 - t * 1.5) * 0.35;

    // Beat ripple through the kaleidoscope
    float beatRipple = sin(radius * 12.0 - u.beatPhase * 6.283) * 0.5 + 0.5;
    beatRipple *= u.beatStrength * u.reactivity;

    // Normalize pattern to 0-1 range
    float p1 = pattern * 0.35 + 0.5;

    // Edge highlighting between mirror segments
    float origSector = fmod(angle + 3.14159, sectorAngle);
    float edgeDist = min(origSector, sectorAngle - origSector);
    float mirrorEdge = smoothstep(0.02, 0.0, edgeDist);

    // Colors
    float3 patternColor = get_palette_color(p1 + radius * 0.3, u.colorPalette);
    float3 accentColor = get_palette_color(p1 + 0.5, u.colorPalette);
    float3 edgeColor = get_palette_color(t * 0.05, u.colorPalette);
    float3 beatColor = get_palette_color(u.beatPhase, u.colorPalette);

    // Build final color
    float3 col = float3(0.0);

    // Main pattern
    float brightness = smoothstep(-0.2, 0.8, p1);
    col += patternColor * brightness * pulse * 0.7;

    // Secondary pattern layer
    float p2 = sin(folded.x * 8.0 + folded.y * 6.0 + t * 2.0) * 0.5 + 0.5;
    col += accentColor * p2 * 0.3 * pulse;

    // Mirror edges glow
    col += edgeColor * mirrorEdge * 0.6;

    // Beat ripple
    col += beatColor * beatRipple * 0.4;

    // Center jewel
    float centerGem = exp(-radius * 8.0);
    col += get_palette_color(t * 0.1, u.colorPalette) * centerGem * 1.5 * pulse;

    // Vignette
    float2 vig = in.uv - 0.5;
    col *= 1.0 - dot(vig, vig) * 0.5;

    return float4(col, 1.0);
}
