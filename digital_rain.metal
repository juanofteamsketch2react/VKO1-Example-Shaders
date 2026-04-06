// digital_rain.metal — Matrix-style cascading columns of glyphs
//
// Uniforms used:
//   time        → rain fall speed
//   beatPhase   → column flash sync
//   beatStrength→ brightness burst on beat
//   energy      → overall glow
//   reactivity  → beat → brightness coupling
//   complexity  → column density (few → many)
//   speed       → fall speed multiplier
//   colorPalette→ glyph colors (Matrix green, cyberpunk, etc.)
//   jogValue    → manual scroll

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

// Pseudo-random hash
float hash(float2 p) {
    return fract(sin(dot(p, float2(127.1, 311.7))) * 43758.5453);
}

// Simple glyph pattern — creates a blocky character-like shape in a cell
float glyph(float2 cellUV, float seed) {
    // 3x5 grid bitmap from hash
    float2 g = floor(cellUV * float2(3.0, 5.0));
    float bit = step(0.5, hash(g + seed * 100.0));

    // Cell border
    float2 inner = fract(cellUV * float2(3.0, 5.0));
    float border = step(0.15, inner.x) * step(inner.x, 0.85) *
                   step(0.1, inner.y) * step(inner.y, 0.9);

    return bit * border;
}

fragment float4 digital_rain(
    VertexOut in [[stage_in]],
    constant GeneratorUniforms &u [[buffer(0)]]
) {
    float2 uv = in.uv;
    float t = u.time * u.speed;
    float scroll = u.jogValue != 0.0 ? u.jogValue * 3.0 : t;
    float pulse = 1.0 + u.energy * u.reactivity * 0.5;

    // Column count from complexity
    float columns = floor(12.0 + u.complexity * 28.0);
    float cellW = 1.0 / columns;
    float cellH = cellW * 1.4; // taller than wide

    // Which column/row
    float col = floor(uv.x / cellW);
    float colHash = hash(float2(col, 0.0));

    // Each column falls at different speed
    float fallSpeed = 0.5 + colHash * 1.5;
    float columnOffset = scroll * fallSpeed + colHash * 100.0;

    float row = floor((uv.y + columnOffset * cellH) / cellH);
    float2 cellUV = float2(
        fract(uv.x / cellW),
        fract((uv.y + columnOffset * cellH) / cellH)
    );

    // Glyph seed changes over time (characters "change")
    float changeRate = 0.5 + colHash;
    float glyphSeed = floor(t * changeRate + row * 0.1) + col;

    // Rain trail: bright at head, fading behind
    float trailLength = 8.0 + colHash * 12.0;
    float headPos = fract(columnOffset * 0.1 + colHash);
    float cellNorm = fract(row * 0.05);
    float trailDist = fract(cellNorm - headPos);
    float trail = smoothstep(trailLength * 0.05, 0.0, trailDist);
    trail = pow(trail, 1.5);

    // Head glow (brightest cell)
    float head = smoothstep(0.02, 0.0, trailDist);

    // Glyph shape
    float g = glyph(cellUV, glyphSeed);

    // Color: head is bright white-ish, trail uses palette
    float3 trailColor = get_palette_color(0.3 + trailDist * 0.5, u.colorPalette);
    float3 headColor = get_palette_color(0.9, u.colorPalette);

    float3 finalCol = float3(0.0);
    finalCol += trailColor * g * trail * 0.8 * pulse;
    finalCol += headColor * g * head * 2.0;

    // Beat flash — random columns flash on beat
    float beatFlash = step(0.7, colHash) * u.beatStrength * u.reactivity;
    finalCol += get_palette_color(0.5, u.colorPalette) * g * beatFlash * 0.5;

    // Subtle scanlines
    float scanline = 0.9 + 0.1 * sin(uv.y * u.resolution.y * 3.14159);
    finalCol *= scanline;

    return float4(finalCol, 1.0);
}
