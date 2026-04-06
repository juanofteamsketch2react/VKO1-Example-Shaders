// crt_monitor.metal — Retro CRT screen with barrel distortion and phosphor glow
//
// Uniforms used:
//   time        → screen flicker and content animation
//   beatPhase   → sync glitch timing to beat
//   beatStrength→ horizontal glitch/tear intensity
//   energy      → phosphor brightness
//   reactivity  → beat → glitch coupling
//   complexity  → scanline density + CRT curvature
//   speed       → animation speed
//   colorPalette→ phosphor dot colors
//   jogValue    → manual content scroll

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

fragment float4 crt_monitor(
    VertexOut in [[stage_in]],
    constant GeneratorUniforms &u [[buffer(0)]]
) {
    float2 uv = in.uv;
    float t = u.time * u.speed;
    float scroll = u.jogValue != 0.0 ? u.jogValue * 2.0 : 0.0;

    // --- CRT barrel distortion ---
    float2 centered = uv - 0.5;
    float curvature = 0.1 + u.complexity * 0.3;
    float r2 = dot(centered, centered);
    float2 warped = centered * (1.0 + curvature * r2) + 0.5;

    // Screen border — black outside the CRT glass
    float border = smoothstep(0.0, 0.01, warped.x) * smoothstep(1.0, 0.99, warped.x) *
                   smoothstep(0.0, 0.01, warped.y) * smoothstep(1.0, 0.99, warped.y);
    if (border < 0.01) return float4(0.0, 0.0, 0.0, 1.0);

    float2 crtUV = warped;

    // --- Glitch: horizontal tear on beat ---
    float glitchStrength = u.beatStrength * u.reactivity;
    float glitchLine = step(0.97, hash(float2(floor(crtUV.y * 40.0), floor(t * 8.0))));
    crtUV.x += glitchLine * glitchStrength * 0.08 * (hash(float2(t, crtUV.y)) - 0.5);

    // Manual scroll
    crtUV.y = fract(crtUV.y + scroll);

    // --- Content: animated waveform/oscilloscope pattern ---
    float wave1 = sin(crtUV.x * 12.0 + t * 3.0) * 0.15;
    float wave2 = sin(crtUV.x * 20.0 - t * 5.0 + u.beatPhase * 6.28) * 0.08;
    float wave3 = sin(crtUV.x * 6.0 + t * 1.5) * 0.1 * u.energy;
    float waveY = 0.5 + wave1 + wave2 + wave3;
    float waveDist = abs(crtUV.y - waveY);
    float waveGlow = smoothstep(0.03, 0.0, waveDist);
    float waveCore = smoothstep(0.008, 0.0, waveDist);

    // Secondary trace
    float wave2Y = 0.5 + sin(crtUV.x * 8.0 - t * 2.0) * 0.2 * (0.5 + u.energy * 0.5);
    float wave2Dist = abs(crtUV.y - wave2Y);
    float wave2Glow = smoothstep(0.04, 0.0, wave2Dist) * 0.5;

    // --- Horizontal grid lines ---
    float gridH = smoothstep(0.01, 0.0, abs(fract(crtUV.y * 8.0) - 0.5) - 0.48) * 0.08;
    float gridV = smoothstep(0.01, 0.0, abs(fract(crtUV.x * 8.0) - 0.5) - 0.48) * 0.08;

    // --- Compose content ---
    float pulse = 1.0 + u.energy * u.reactivity * 0.4;
    float3 col = float3(0.0);

    float3 waveColor = get_palette_color(0.3, u.colorPalette);
    float3 wave2Color = get_palette_color(0.7, u.colorPalette);
    float3 gridColor = get_palette_color(0.5, u.colorPalette) * 0.3;

    col += waveColor * waveGlow * 0.6 * pulse;
    col += waveColor * waveCore * 1.5 * pulse;
    col += wave2Color * wave2Glow * pulse;
    col += gridColor * (gridH + gridV);

    // --- Scanlines ---
    float scanlineCount = 200.0 + u.complexity * 400.0;
    float scanline = 0.7 + 0.3 * sin(crtUV.y * scanlineCount * 3.14159);
    col *= scanline;

    // --- RGB phosphor sub-pixels ---
    float subpixel = fract(crtUV.x * u.resolution.x * 0.33);
    float3 phosphor;
    if (subpixel < 0.333) phosphor = float3(1.4, 0.6, 0.6);
    else if (subpixel < 0.666) phosphor = float3(0.6, 1.4, 0.6);
    else phosphor = float3(0.6, 0.6, 1.4);
    col *= mix(float3(1.0), phosphor, 0.3);

    // --- Screen flicker ---
    float flicker = 0.97 + 0.03 * sin(t * 60.0);
    col *= flicker;

    // --- Brightness from energy ---
    col *= 0.7 + u.energy * 0.5;

    // --- Vignette (CRT edges are darker) ---
    float vig = 1.0 - r2 * 2.5;
    col *= max(vig, 0.0);

    // --- Screen edge glow ---
    float edgeGlow = smoothstep(0.02, 0.0, min(min(warped.x, 1.0 - warped.x),
                                                  min(warped.y, 1.0 - warped.y)));
    col += get_palette_color(0.2, u.colorPalette) * edgeGlow * 0.15;

    return float4(col * border, 1.0);
}
