// diamond_spin.metal — Rotating 3D diamond/gem with faceted reflections
//
// Uniforms used:
//   time        → rotation
//   beatPhase   → facet flash sync
//   beatStrength→ sparkle intensity
//   energy      → overall brilliance
//   reactivity  → beat → sparkle coupling
//   complexity  → number of facets
//   speed       → rotation speed
//   colorPalette→ gem color scheme
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

float hash(float2 p) {
    return fract(sin(dot(p, float2(127.1, 311.7))) * 43758.5453);
}

fragment float4 diamond_spin(
    VertexOut in [[stage_in]],
    constant GeneratorUniforms &u [[buffer(0)]]
) {
    float2 uv = in.uv - 0.5;
    float aspect = u.resolution.x / u.resolution.y;
    uv.x *= aspect;

    float t = u.time * u.speed;
    float rot = u.jogValue != 0.0 ? u.jogValue * 8.0 + t * 0.2 : t;
    float pulse = 1.0 + u.energy * u.reactivity * 0.5;

    // Rotate UV
    float ca = cos(rot * 0.6);
    float sa = sin(rot * 0.6);
    float2 rotUV = float2(uv.x * ca - uv.y * sa, uv.x * sa + uv.y * ca);

    // Diamond shape: rotated square distance
    float diamondDist = abs(rotUV.x) + abs(rotUV.y);
    float diamondSize = 0.3 + u.energy * 0.05;

    // Inside diamond?
    float inside = smoothstep(diamondSize + 0.005, diamondSize - 0.005, diamondDist);

    // Facets: divide the diamond into angular segments
    float facetCount = floor(4.0 + u.complexity * 12.0);
    float angle = atan2(rotUV.y, rotUV.x);
    float facetAngle = 6.283185 / facetCount;
    float facetID = floor(angle / facetAngle);
    float facetFrac = fract(angle / facetAngle);

    // Each facet has a different "reflection" brightness
    float facetBright = hash(float2(facetID, floor(rot * 2.0)));

    // Sparkle: certain facets flash on beat
    float sparkle = step(0.7, hash(float2(facetID, floor(t * 4.0))));
    sparkle *= u.beatStrength * u.reactivity;

    // Facet edge highlight
    float facetEdge = smoothstep(0.05, 0.0, min(facetFrac, 1.0 - facetFrac));

    // Inner fire pattern
    float innerPattern = sin(diamondDist * 30.0 - t * 3.0 + facetID * 2.0) * 0.5 + 0.5;
    innerPattern *= sin(angle * facetCount * 0.5 + t) * 0.3 + 0.7;

    // Colors
    float3 facetColor = get_palette_color(facetID / facetCount + rot * 0.02, u.colorPalette);
    float3 sparkleColor = get_palette_color(0.9, u.colorPalette);
    float3 edgeColorVal = get_palette_color(facetID / facetCount + 0.5, u.colorPalette);

    float3 col = float3(0.0);

    // Diamond body
    float shade = 0.3 + facetBright * 0.5 + innerPattern * 0.3;
    col += facetColor * shade * inside * pulse;

    // Facet edges (brighter lines between facets)
    col += edgeColorVal * facetEdge * inside * 0.8;

    // Sparkle highlights
    col += sparkleColor * sparkle * inside * 1.5;

    // Diamond outline glow
    float outlineDist = abs(diamondDist - diamondSize);
    float outline = smoothstep(0.02, 0.0, outlineDist);
    col += get_palette_color(rot * 0.05, u.colorPalette) * outline * 1.2 * pulse;

    // Outer glow
    float outerGlow = smoothstep(0.15, 0.0, diamondDist - diamondSize);
    col += get_palette_color(0.3, u.colorPalette) * outerGlow * 0.15;

    // Beat pulse ring around diamond
    float beatRing = abs(diamondDist - diamondSize - u.beatPhase * 0.3);
    float beatGlow = smoothstep(0.03, 0.0, beatRing) * u.beatStrength * u.reactivity;
    col += get_palette_color(u.beatPhase, u.colorPalette) * beatGlow * 0.8;

    // Vignette
    float2 vig = in.uv - 0.5;
    col *= 1.0 - dot(vig, vig) * 0.4;

    return float4(col, 1.0);
}
