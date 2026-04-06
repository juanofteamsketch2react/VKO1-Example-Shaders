// wireframe_cube.metal — Rotating 3D wireframe cube with neon edges
//
// Uniforms used:
//   time        → rotation angle
//   beatPhase   → edge pulse sync
//   beatStrength→ flash on downbeat
//   energy      → edge glow intensity
//   reactivity  → beat → glow coupling
//   complexity  → number of nested cubes (1–4)
//   speed       → rotation speed
//   colorPalette→ edge colors
//   jogValue    → manual rotation control

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

// --- 3D rotation matrices ---
float3 rotateY(float3 p, float a) {
    float c = cos(a), s = sin(a);
    return float3(p.x * c + p.z * s, p.y, -p.x * s + p.z * c);
}
float3 rotateX(float3 p, float a) {
    float c = cos(a), s = sin(a);
    return float3(p.x, p.y * c - p.z * s, p.y * s + p.z * c);
}

// Distance from point to line segment (projected to 2D)
float segmentDist(float2 p, float2 a, float2 b) {
    float2 ab = b - a;
    float t = clamp(dot(p - a, ab) / dot(ab, ab), 0.0, 1.0);
    return length(p - a - ab * t);
}

// Project 3D point to 2D (perspective)
float2 project(float3 p) {
    float persp = 3.0 / (3.0 + p.z);
    return p.xy * persp;
}

fragment float4 wireframe_cube(
    VertexOut in [[stage_in]],
    constant GeneratorUniforms &u [[buffer(0)]]
) {
    float2 uv = in.uv - 0.5;
    float aspect = u.resolution.x / u.resolution.y;
    uv.x *= aspect;

    float t = u.time * u.speed;
    float rot = u.jogValue != 0.0 ? u.jogValue * 10.0 + t * 0.2 : t;
    float pulse = 1.0 + u.energy * u.reactivity * 0.8;
    float flash = u.beatStrength * u.reactivity;

    int cubeCount = 1 + int(u.complexity * 3.0);
    float3 col = float3(0.0);

    for (int c = 0; c < 4; c++) {
        if (c >= cubeCount) break;

        float scale = 0.2 + float(c) * 0.12;
        float rotOffset = float(c) * 0.5;

        // 8 vertices of a cube
        float3 verts[8];
        for (int i = 0; i < 8; i++) {
            float3 v = float3(
                (i & 1) ? scale : -scale,
                (i & 2) ? scale : -scale,
                (i & 4) ? scale : -scale
            );
            v = rotateY(v, rot * 0.7 + rotOffset);
            v = rotateX(v, rot * 0.5 + rotOffset * 0.7);
            verts[i] = v;
        }

        // 12 edges of a cube
        int edges[24] = {
            0,1, 2,3, 4,5, 6,7,  // parallel to X
            0,2, 1,3, 4,6, 5,7,  // parallel to Y
            0,4, 1,5, 2,6, 3,7   // parallel to Z
        };

        for (int e = 0; e < 12; e++) {
            float2 a = project(verts[edges[e*2]]);
            float2 b = project(verts[edges[e*2+1]]);
            float d = segmentDist(uv, a, b);

            float lineWidth = 0.003 + 0.002 * pulse;
            float glow = smoothstep(lineWidth * 4.0, lineWidth, d);
            float core = smoothstep(lineWidth, lineWidth * 0.3, d);

            float edgeT = float(e) / 12.0 + float(c) * 0.25;
            float3 edgeColor = get_palette_color(edgeT + u.beatPhase * 0.3, u.colorPalette);

            col += edgeColor * glow * 0.4;
            col += edgeColor * core * 1.2 * pulse;
        }
    }

    // Beat flash overlay
    col += get_palette_color(0.5, u.colorPalette) * flash * 0.15;

    // Vignette
    float2 vig = in.uv - 0.5;
    col *= 1.0 - dot(vig, vig) * 0.6;

    return float4(col, 1.0);
}
