// aurora.metal — Northern lights curtains with vertical shimmer
//
// Uniforms used:
//   time        → curtain sway animation
//   beatPhase   → shimmer wave sync
//   beatStrength→ curtain flash intensity
//   energy      → aurora brightness and height
//   reactivity  → beat → shimmer coupling
//   complexity  → number of curtain layers and detail
//   speed       → sway speed
//   colorPalette→ aurora color bands
//   jogValue    → manual horizontal scroll

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

float aurora_noise(float x, float t) {
    float i = floor(x);
    float f = fract(x);
    f = f * f * (3.0 - 2.0 * f);
    float a = fract(sin(i * 127.1 + t) * 43758.5453);
    float b = fract(sin((i + 1.0) * 127.1 + t) * 43758.5453);
    return mix(a, b, f);
}

float aurora_fbm(float x, float t, int octaves) {
    float val = 0.0;
    float amp = 0.5;
    float freq = 1.0;
    for (int i = 0; i < octaves; i++) {
        val += amp * aurora_noise(x * freq, t + float(i) * 3.17);
        freq *= 2.1;
        amp *= 0.5;
    }
    return val;
}

fragment float4 aurora(
    VertexOut in [[stage_in]],
    constant GeneratorUniforms &u [[buffer(0)]]
) {
    float2 uv = in.uv;
    float aspect = u.resolution.x / u.resolution.y;

    float t = u.time * u.speed;
    float jogScroll = u.jogValue * 4.0;
    float pulse = 1.0 + u.energy * u.reactivity * 0.5;

    int layers = 2 + int(u.complexity * 5.0);
    int octaves = 2 + int(u.complexity * 3.0);

    float3 col = float3(0.0);

    // Dark sky gradient background
    float skyGrad = uv.y * 0.15;
    col += float3(0.01, 0.01, 0.03) + skyGrad * float3(0.02, 0.01, 0.04);

    // Aurora curtain layers
    for (int i = 0; i < layers; i++) {
        float fi = float(i);
        float layerOffset = fi * 1.7;
        float layerSpeed = 0.3 + fi * 0.15;

        // Horizontal position with sway
        float x = (uv.x * aspect + jogScroll) * (1.5 + fi * 0.5) + layerOffset;

        // Curtain height from noise
        float curtainBase = 0.3 + fi * 0.08;
        float curtainHeight = aurora_fbm(x * 0.8, t * layerSpeed, octaves);
        curtainHeight = curtainBase + curtainHeight * (0.4 + u.energy * 0.2);

        // Beat shimmer
        float shimmer = sin(x * 8.0 - u.beatPhase * 6.283 * 2.0) * 0.5 + 0.5;
        shimmer *= u.beatStrength * u.reactivity * 0.3;

        // Vertical curtain shape: bright at top, fading down
        float curtainY = uv.y - (1.0 - curtainHeight);
        float curtainAlpha = 0.0;

        if (curtainY > 0.0) {
            // Vertical fade with streaky detail
            float verticalNoise = aurora_fbm(uv.y * 8.0 + x * 0.5, t * 0.5 + fi, 3);
            curtainAlpha = exp(-curtainY * (3.0 - u.energy)) * (0.5 + verticalNoise * 0.5);
            curtainAlpha += shimmer * curtainAlpha;
        }

        // Color varies per layer and position
        float colorParam = fi * 0.2 + x * 0.05 + t * 0.02;
        float3 curtainColor = get_palette_color(colorParam, u.colorPalette);

        // Brighten the leading edge
        float edgeBright = smoothstep(0.0, 0.05, curtainY) * smoothstep(0.3, 0.0, curtainY);

        col += curtainColor * curtainAlpha * (0.3 + edgeBright * 0.7) * pulse / float(layers) * 2.5;
    }

    // Subtle star field background
    float2 starUV = uv * float2(aspect, 1.0) * 80.0;
    float2 starCell = floor(starUV);
    float starHash = fract(sin(dot(starCell, float2(127.1, 311.7))) * 43758.5453);
    float star = step(0.985, starHash);
    float starTwinkle = sin(t * 3.0 + starHash * 100.0) * 0.5 + 0.5;
    col += float3(star * starTwinkle * 0.4);

    // Beat flash across the whole aurora
    float beatFlash = exp(-abs(uv.y - 0.5) * 4.0) * u.beatStrength * 0.15;
    col += get_palette_color(u.beatPhase, u.colorPalette) * beatFlash;

    return float4(col, 1.0);
}
