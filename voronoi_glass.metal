// voronoi_glass.metal — Stained glass Voronoi cells with glowing edges
//
// Uniforms used:
//   time        → cell animation and color drift
//   beatPhase   → cell pulse wave
//   beatStrength→ edge flash intensity
//   energy      → edge brightness and cell vibrancy
//   reactivity  → beat → cell glow coupling
//   complexity  → cell density (few large → many small)
//   speed       → cell drift speed
//   colorPalette→ glass panel colors
//   jogValue    → manual pattern scroll

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

float2 voronoi_hash(float2 p) {
    float2 h = float2(
        fract(sin(dot(p, float2(127.1, 311.7))) * 43758.5453),
        fract(sin(dot(p, float2(269.5, 183.3))) * 43758.5453)
    );
    return h;
}

fragment float4 voronoi_glass(
    VertexOut in [[stage_in]],
    constant GeneratorUniforms &u [[buffer(0)]]
) {
    float2 uv = in.uv - 0.5;
    float aspect = u.resolution.x / u.resolution.y;
    uv.x *= aspect;

    float t = u.time * u.speed;
    float2 scroll = float2(u.jogValue * 2.0, 0.0);
    float pulse = 1.0 + u.energy * u.reactivity * 0.4;

    // Cell density from complexity
    float cellScale = 3.0 + u.complexity * 10.0;
    float2 p = (uv + scroll) * cellScale;

    float2 cellI = floor(p);
    float2 cellF = fract(p);

    // Find closest and second-closest Voronoi points
    float minDist = 10.0;
    float secondDist = 10.0;
    float2 closestCell = float2(0.0);

    for (int y = -1; y <= 1; y++) {
        for (int x = -1; x <= 1; x++) {
            float2 neighbor = float2(float(x), float(y));
            float2 point = voronoi_hash(cellI + neighbor);

            // Animate points slowly
            point = 0.5 + 0.4 * sin(t * 0.3 + point * 6.283);

            float2 diff = neighbor + point - cellF;
            float dist = length(diff);

            if (dist < minDist) {
                secondDist = minDist;
                minDist = dist;
                closestCell = cellI + neighbor;
            } else if (dist < secondDist) {
                secondDist = dist;
            }
        }
    }

    // Edge detection: difference between closest and second closest
    float edgeDist = secondDist - minDist;
    float edge = smoothstep(0.0, 0.08, edgeDist);

    // Cell ID for unique color per cell
    float cellHash = fract(sin(dot(closestCell, float2(127.1, 311.7))) * 43758.5453);
    float cellHash2 = fract(sin(dot(closestCell, float2(269.5, 183.3))) * 43758.5453);

    // Beat pulse: cells light up in a wave from center
    float cellDist = length(closestCell / cellScale);
    float beatWave = sin(cellDist * 6.0 - u.beatPhase * 6.283) * 0.5 + 0.5;
    float beatPulse = beatWave * u.beatStrength * u.reactivity;

    // Glass panel color
    float3 glassColor = get_palette_color(cellHash + t * 0.02, u.colorPalette);

    // Subtle internal gradient within each cell (stained glass light effect)
    float internalGrad = minDist * 2.0;
    float lightEffect = 0.6 + internalGrad * 0.4;

    // Edge color (lead between glass panels)
    float3 edgeColor = get_palette_color(cellHash2 + 0.5, u.colorPalette);
    float edgeGlow = smoothstep(0.08, 0.0, edgeDist) * (1.0 + u.energy * 2.0);

    float3 col = float3(0.0);

    // Glass fill
    col += glassColor * edge * lightEffect * 0.6 * pulse;

    // Beat-activated cells glow brighter
    col += glassColor * beatPulse * edge * 0.5;

    // Glowing edges (the "lead" in stained glass)
    col += edgeColor * edgeGlow * 0.8 * pulse;

    // Specular highlight on glass (fake light source from top-right)
    float2 lightDir = normalize(float2(0.5, 0.7));
    float2 cellCenter = closestCell / cellScale - uv;
    float spec = pow(max(0.0, dot(normalize(cellCenter), lightDir)), 8.0);
    col += float3(1.0) * spec * 0.15 * edge;

    // Beat flash on edges
    float beatEdgeFlash = (1.0 - edge) * u.beatStrength * 0.5;
    col += get_palette_color(u.beatPhase, u.colorPalette) * beatEdgeFlash;

    // Vignette
    float2 vig = in.uv - 0.5;
    col *= 1.0 - dot(vig, vig) * 0.4;

    return float4(col, 1.0);
}
