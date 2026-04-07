// synthwave_drive.metal — Neon synthwave cityscape, heavily audio-reactive
//
// Uniforms used:
//   time        → scene animation, road scroll, city flicker
//   beatPhase   → neon pulse sync
//   beatStrength→ bloom flash on beat  ← PRIMARY BEAT DRIVER
//   energy      → overall glow intensity and car speed feel
//   reactivity  → beat → neon coupling
//   complexity  → city density, star count, grid detail
//   speed       → road scroll and city scroll rate
//   colorPalette→ neon color scheme
//   jogValue    → horizontal scene drift / camera pan

#include <metal_stdlib>
using namespace metal;

// ─────────────────────────────────────────────
//  PALETTE
// ─────────────────────────────────────────────

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

// ─────────────────────────────────────────────
//  UTILITIES
// ─────────────────────────────────────────────

float hash(float2 p) {
    return fract(sin(dot(p, float2(127.1, 311.7))) * 43758.5453);
}

float hash1(float n) {
    return fract(sin(n) * 43758.5453);
}

float snoise(float2 p) {
    float2 i = floor(p);
    float2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    float a = hash(i), b = hash(i + float2(1,0));
    float c = hash(i + float2(0,1)), d = hash(i + float2(1,1));
    return mix(mix(a,b,f.x), mix(c,d,f.x), f.y);
}

// ─────────────────────────────────────────────
//  SCENE LAYERS
// ─────────────────────────────────────────────

// Stars — size pulses with beat
float3 draw_stars(float2 uv, float t, float beat, int pal) {
    float3 col = float3(0.0);
    float2 grid  = floor(uv * 80.0);
    float2 local = fract(uv * 80.0) - 0.5;
    float h = hash(grid);
    float twinkle = 0.5 + 0.5 * sin(t * 1.5 * h + h * 6.28);
    // Beat makes stars briefly flare
    float starSize = 0.02 + beat * 0.025 * h;
    float star = smoothstep(starSize + 0.01, starSize - 0.01, length(local)) * twinkle;
    float3 starColor = get_palette_color(h * 0.3 + 0.6, pal);
    col += starColor * star * (1.8 + beat * 1.5);
    return col;
}

// Retro sun — scanline bands breathe with beat
float3 draw_retro_sun(float2 uv, float horizonY, float t, float beat, float energy, int pal) {
    float3 col = float3(0.0);
    float2 sunCenter = float2(0.5, horizonY + 0.18);
    float sunR = 0.13 + energy * 0.015;

    float d = length(uv - sunCenter);

    // Beat compresses/expands band density — feels like bass thump
    float bandFreq = 28.0 + beat * 14.0;
    float bands = step(0.5, fract((uv.y - sunCenter.y) * bandFreq));
    float sunMask = smoothstep(sunR, sunR - 0.003, d) * bands;

    // Outer glow flares on beat
    float sunOuterGlow = exp(-d * (6.0 - beat * 3.0)) * (0.5 + beat * 0.8);

    float3 sunTop    = get_palette_color(0.88, pal);
    float3 sunBottom = get_palette_color(0.62, pal);
    float sunGrad = clamp((uv.y - (sunCenter.y - sunR)) / (sunR * 2.0), 0.0, 1.0);
    float3 sunColor = mix(sunTop, sunBottom, sunGrad);

    col += sunColor * sunMask;
    col += sunColor * sunOuterGlow;

    // Beat pulse ring emanating outward from sun
    float ringR = sunR + beat * 0.18;
    float ring  = smoothstep(0.012, 0.0, abs(d - ringR)) * beat * 1.5;
    col += sunColor * ring;

    return col;
}

// City skyline — windows flicker hard with beat, buildings wobble
float3 draw_skyline(float2 uv, float horizonY, float t, float scroll,
                    float density, float beat, float beatPhase, int pal) {
    float3 col = float3(0.0);

    for (int layer = 0; layer < 2; layer++) {
        float layerZ      = (layer == 0) ? 0.4 : 0.7;
        float layerScroll = scroll * layerZ * 0.12;
        float layerY      = horizonY + (layer == 0 ? 0.0 : 0.02);
        float heightScale = (layer == 0) ? 0.10 : 0.17;
        float widthScale  = (layer == 0) ? 0.07 : 0.10;
        int   buildingCount = 8 + int(density * 10.0);

        for (int b = 0; b < buildingCount; b++) {
            float bId = float(b) + float(layer) * 37.3;
            float bX  = fract(hash1(bId * 3.1) + layerScroll) * 1.4 - 0.2;
            float bW  = widthScale * (0.5 + hash1(bId * 7.3) * 0.5);
            float bH  = heightScale * (0.3 + hash1(bId * 13.7) * 0.7);

            // Buildings stretch upward on heavy beat
            bH *= 1.0 + beat * 0.12 * hash1(bId * 2.1);

            float inX = step(bX, uv.x) * step(uv.x, bX + bW);
            float inY = step(layerY - bH, uv.y) * step(uv.y, layerY);
            float inBuilding = inX * inY;

            float hasTower = step(0.6, hash1(bId * 5.7));
            float towerX   = bX + bW * 0.5;
            float towerInX = smoothstep(0.003, 0.0, abs(uv.x - towerX));
            float towerInY = step(layerY - bH - 0.025 * hasTower, uv.y) * step(uv.y, layerY - bH);
            float towerMask = towerInX * towerInY * hasTower;

            float3 buildColor = float3(0.03, 0.02, 0.06) * (1.0 + float(layer) * 0.3);
            col += buildColor * inBuilding;
            col += buildColor * towerMask;

            // Windows — flicker rate locked to beatPhase for sync'd strobing
            float2 winUV   = float2((uv.x - bX) / bW, (layerY - uv.y) / bH);
            float2 winGrid = floor(winUV * float2(5.0 + hash1(bId)*3.0, 8.0 + hash1(bId*2.3)*6.0));
            float winH     = hash(winGrid + float2(bId, bId * 2.7));
            // Base flicker + strong beat strobe
            float flicker = step(0.35, winH) * (0.6 + 0.4 * sin(t * 0.4 * winH + winH * 12.0));
            float beatStrobe = beat * step(0.5, sin(beatPhase * 3.14159 + winH * 6.28)) * 0.8;
            float winGlow = inBuilding * clamp(flicker + beatStrobe, 0.0, 1.0);
            float3 winColor = get_palette_color(winH * 0.5 + beatPhase * 0.3, pal);
            col += winColor * winGlow * (0.45 + beat * 0.55);

            // Neon edge outlines — brighter on beat
            float edgeL   = smoothstep(0.004, 0.0, abs(uv.x - bX)) * inY;
            float edgeR   = smoothstep(0.004, 0.0, abs(uv.x - (bX+bW))) * inY;
            float edgeTop = smoothstep(0.003, 0.0, abs(uv.y - (layerY - bH))) * inX;
            float3 edgeColor = get_palette_color(0.75 + float(layer) * 0.15 + beat * 0.1, pal);
            col += edgeColor * (edgeL + edgeR + edgeTop) * (0.4 + beat * 0.6) * layerZ;

            // Antenna blink — synced to beat
            float blinkRate = 0.8 + hash1(bId * 9.1) * 0.6;
            float blink = step(0.6, sin(t * blinkRate)) + beat * 0.5;
            float towerTip = smoothstep(0.006, 0.0, length(uv - float2(towerX, layerY - bH - 0.025 * hasTower)));
            col += float3(1.0, 0.2, 0.3) * towerTip * clamp(blink,0.0,1.0) * hasTower * (1.5 + beat * 2.0);
        }
    }
    return col;
}

// Road — grid speed warps with beat
float3 draw_road(float2 uv, float horizonY, float t, float speed, float beat, float energy, int pal) {
    float3 col = float3(0.0);
    if (uv.y >= horizonY) return col;

    float roadY = horizonY - uv.y;
    float depth = 0.04 / (roadY + 0.001);

    float roadWidth = 0.7 * depth;
    float roadEdge  = smoothstep(roadWidth, roadWidth - 0.01 * depth, abs(uv.x - 0.5));
    float3 asphalt  = float3(0.04, 0.03, 0.06) * roadEdge;
    col += asphalt;

    // Beat boosts scroll speed — sudden rush feel on kick
    float beatSpeed = speed + beat * speed * 3.0;
    float scroll    = fract(t * beatSpeed * 0.4);

    // Horizontal grid — rushes toward camera on beat
    float gridZ = fract(depth * 1.5 - scroll);
    float hLine = smoothstep(0.04, 0.0, abs(fract(gridZ * 8.0) - 0.5) - 0.45);
    float3 gridColor = get_palette_color(0.72 + beat * 0.08, pal);
    col += gridColor * hLine * roadEdge * (0.5 + beat * 0.7);

    // Vertical lane dividers
    float laneX = fract((uv.x - 0.5) / depth * 2.0 + 0.5);
    float vLine = smoothstep(0.03, 0.0, abs(fract(laneX) - 0.5) - 0.47);
    col += gridColor * vLine * roadEdge * (0.35 + beat * 0.4);

    // Neon rails — flare width on beat
    float railBloom = 0.018 + beat * 0.03;
    float railL = exp(-abs(uv.x - (0.5 - roadWidth)) / railBloom) * step(0.0, roadY);
    float railR = exp(-abs(uv.x - (0.5 + roadWidth)) / railBloom) * step(0.0, roadY);
    float3 railColor = get_palette_color(0.82 + beat * 0.05, pal);
    col += railColor * (railL + railR) * (0.7 + beat * 1.0);

    // Centre dash
    float dashScroll = fract(depth * 3.0 - scroll * 2.0);
    float centreDash = step(0.4, fract(dashScroll * 5.0));
    float centreLineW = smoothstep(0.006 * depth, 0.0, abs(uv.x - 0.5));
    col += float3(0.9, 0.85, 0.4) * centreLineW * centreDash * roadEdge * (0.6 + beat * 0.5);

    // Road neon reflection — blooms up on beat
    float reflection = exp(-roadY * (18.0 - beat * 10.0)) * roadEdge * (0.3 + beat * 0.5);
    float3 reflectColor = get_palette_color(0.78, pal);
    col += reflectColor * reflection;

    return col;
}

// Car — underglow pumps, bounces, headlights flare
float3 draw_car(float2 uv, float horizonY, float t, float beat, float beatPhase, int pal) {
    float3 col = float3(0.0);

    float2 carCenter = float2(0.5, horizonY - 0.045);
    float carW = 0.18;
    float carH = 0.038;

    // Hard vertical bounce on kick
    carCenter.y += beat * 0.008;
    // Subtle horizontal shimmy
    carCenter.x += sin(beatPhase * 6.28) * beat * 0.003;

    float2 cp = uv - carCenter;

    float body = step(-carW*0.5, cp.x) * step(cp.x, carW*0.5)
               * step(-carH,     cp.y) * step(cp.y, 0.0);

    float roofH     = carH * 0.8;
    float roofLeft  = -carW * 0.5 + carW * 0.18;
    float roofRight =  carW * 0.5 - carW * 0.10;
    float roof = step(roofLeft,  cp.x) * step(cp.x, roofRight)
               * step(0.0,       cp.y) * step(cp.y, roofH);

    float wsLeft  = roofLeft  + carW * 0.04;
    float wsRight = roofLeft  + carW * 0.22;
    float ws = step(wsLeft, cp.x) * step(cp.x, wsRight)
             * step(0.008,  cp.y) * step(cp.y, roofH - 0.005);

    float carMask = clamp(body + roof, 0.0, 1.0);
    col += float3(0.05, 0.04, 0.08) * carMask;
    col += float3(0.08, 0.10, 0.18) * ws;

    // Underglow — pumps hard with beat amplitude
    float underY   = carCenter.y - carH * 0.05;
    float underDist = abs(uv.y - underY);
    float underX   = step(carCenter.x - carW * 0.48, uv.x) * step(uv.x, carCenter.x + carW * 0.48);
    float underPulse = 1.8 + beat * 3.5;           // pumps 3.5x on kick
    float underglow  = exp(-underDist * (80.0 - beat * 40.0)) * underX * underPulse;
    float roadPool   = exp(-max(0.0, underY - uv.y) * (30.0 - beat * 18.0)) * underX * step(uv.y, underY);
    float3 glowColor = get_palette_color(0.82 + beatPhase * 0.1, pal);
    col += glowColor * underglow;
    col += glowColor * roadPool * (0.5 + beat * 0.8);

    // Headlights — cone lengthens and brightens on beat
    float hlX  = carCenter.x + carW * 0.5;
    float hlY1 = carCenter.y - carH * 0.35;
    float hlY2 = carCenter.y - carH * 0.65;
    for (int h = 0; h < 2; h++) {
        float hlCY = (h == 0) ? hlY1 : hlY2;
        float2 hlDir = uv - float2(hlX, hlCY);
        float coneAngle = abs(hlDir.y / (hlDir.x + 0.001));
        float coneMask  = step(0.0, hlDir.x) * smoothstep(0.28 - beat * 0.08, 0.0, coneAngle);
        float coneFade  = exp(-hlDir.x * (9.0 - beat * 5.0));
        col += float3(0.9, 0.85, 0.6) * coneMask * coneFade * (0.35 + beat * 0.5);
        float hlDot = smoothstep(0.007, 0.0, length(uv - float2(hlX, hlCY)));
        col += float3(1.0, 0.95, 0.8) * hlDot * (2.0 + beat * 2.0);
    }

    // Tail lights — strobe on beat
    float tlX = carCenter.x - carW * 0.5;
    float tlGlow = exp(-abs(uv.x - tlX) * 60.0)
                 * exp(-abs(uv.y - (carCenter.y - carH * 0.5)) * 50.0);
    col += float3(1.0, 0.05, 0.2) * tlGlow * (2.5 + beat * 4.0);

    // Wheels
    for (int w = 0; w < 2; w++) {
        float wheelX = carCenter.x + (w == 0 ? -carW * 0.3 : carW * 0.3);
        float wheelY = carCenter.y - carH;
        float wheelR = carH * 0.7;
        float2 wd = uv - float2(wheelX, wheelY);
        float wheelDist = length(wd);
        float wheelMask = smoothstep(wheelR, wheelR - 0.003, wheelDist);
        float wheelRim  = smoothstep(wheelR * 0.55, wheelR * 0.45, wheelDist);
        col -= float3(0.04, 0.03, 0.06) * wheelMask;
        float3 rimColor = get_palette_color(0.65 + beat * 0.1, pal);
        col += rimColor * (wheelMask - wheelRim) * (0.6 + beat * 0.8);
    }

    return col;
}

// Sky + horizon — horizon band flares wide on beat
float3 draw_sky(float2 uv, float horizonY, float t, float beat, float beatPhase, int pal) {
    float skyT = clamp((uv.y - horizonY) / (1.0 - horizonY), 0.0, 1.0);
    float3 skyTop     = float3(0.01, 0.0, 0.06);
    float3 skyHorizon = get_palette_color(0.68, pal) * 0.25;
    float3 sky = mix(skyHorizon, skyTop, skyT * skyT);

    // Horizon band — thickness and intensity driven by beat
    float horizonWidth = 18.0 - beat * 10.0;   // wider band on beat
    float horizonGlow  = exp(-abs(uv.y - horizonY) * horizonWidth) * (0.6 + beat * 1.2);
    horizonGlow += exp(-abs(uv.y - horizonY) * 4.0) * (0.12 + beat * 0.3);
    float3 horizonColor = get_palette_color(0.76 + beatPhase * 0.05, pal);
    sky += horizonColor * horizonGlow;

    // Beat color wash — tints the whole sky briefly on kick
    float3 beatWash = get_palette_color(beatPhase * 0.5 + 0.2, pal);
    sky += beatWash * beat * 0.18 * (1.0 - skyT * 0.5);

    return sky;
}

// ─────────────────────────────────────────────
//  MAIN FRAGMENT
// ─────────────────────────────────────────────

fragment float4 synthwave_drive(
    VertexOut in [[stage_in]],
    constant GeneratorUniforms &u [[buffer(0)]]
) {
    float2 uv = in.uv;
    float aspect = u.resolution.x / u.resolution.y;
    float2 cuv = uv - 0.5;
    cuv.x *= aspect;

    float t      = u.time * u.speed;
    float scroll = t + u.jogValue * 10.0;
    float beat   = u.beatStrength * u.reactivity;
    float energy = u.energy;

    // ── Camera shake on beat ──
    // UV nudged by a small random offset that spikes on kick
    float shakeX = (hash(float2(floor(u.time * 30.0), 1.3)) - 0.5) * beat * 0.008;
    float shakeY = (hash(float2(floor(u.time * 30.0), 7.1)) - 0.5) * beat * 0.005;
    uv  += float2(shakeX, shakeY);
    cuv += float2(shakeX, shakeY);

    float horizonY = 0.45;

    // ── Sky ──
    float3 col = draw_sky(uv, horizonY, t, beat, u.beatPhase, u.colorPalette);

    // ── Stars ──
    if (uv.y > horizonY)
        col += draw_stars(uv, t, beat, u.colorPalette);

    // ── Retro sun ──
    col += draw_retro_sun(uv, horizonY, t, beat, energy, u.colorPalette);

    // ── City skyline ──
    col += draw_skyline(uv, horizonY, t, scroll, u.complexity, beat, u.beatPhase, u.colorPalette);

    // ── Road ──
    col += draw_road(uv, horizonY, t, u.speed, beat, energy, u.colorPalette);

    // ── Car ──
    col += draw_car(uv, horizonY, t, beat, u.beatPhase, u.colorPalette);

    // ── Global beat bloom flash — white hot on kick ──
    float3 bloomColor = get_palette_color(u.beatPhase * 0.5, u.colorPalette);
    float bloomFade   = exp(-length(cuv / float2(aspect, 1.0)) * 2.5); // center-weighted
    col += bloomColor * beat * beat * 0.7 * bloomFade; // squared = punchy falloff

    // ── Chromatic aberration — spikes hard on beat ──
    float caStr = length(cuv) * (0.012 + beat * 0.035);
    float2 caDir = normalize(cuv + 0.0001) * caStr;
    col.r += snoise((uv + caDir) * 80.0) * (0.005 + beat * 0.015);
    col.b -= snoise((uv - caDir) * 80.0) * (0.005 + beat * 0.015);

    // ── CRT scanlines ──
    float scanline = 0.85 + 0.15 * sin(uv.y * u.resolution.y * 1.5);
    col *= scanline;

    // ── Film grain ──
    float grain = (hash(uv + fract(t * 7.3)) - 0.5) * 0.04;
    col += grain;

    // ── Vignette — tightens on beat for tunnel-vision effect ──
    float vignetteRadius = 0.85 - beat * 0.2;
    float vignette = smoothstep(vignetteRadius, 0.2, length(cuv / float2(aspect, 1.0)));
    col *= vignette;

    // ── Saturation boost ──
    float lum = dot(col, float3(0.299, 0.587, 0.114));
    col = mix(float3(lum), col, 1.3 + beat * 0.4);
    col = clamp(col, 0.0, 1.0);

    return float4(col, 1.0);
}