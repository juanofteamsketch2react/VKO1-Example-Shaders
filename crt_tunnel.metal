// crt_tunnel.metal — Retro CRT Terminal / Wireframe Dungeon
//
// Aesthetic: Phosphor green terminal meets Computer Gaming World 1982.
// Perspective wireframe tunnel rushes toward you, phosphor CRT scanlines
// overlay everything, glitch artifacts flare on beats, and cascading
// data-readout text columns pulse at the borders.
//
// Uniforms used:
//   time         → tunnel scroll, text cascade, scanline drift
//   beatPhase    → tunnel flash sync
//   beatStrength → glitch intensity, brightness spikes
//   energy       → phosphor brightness / bloom level
//   reactivity   → beat-to-glitch coupling strength
//   complexity   → tunnel ring density + text column density
//   speed        → overall scroll / animation speed
//   colorPalette → phosphor color tint (green / amber / cyan / white)
//   jogValue     → manual tunnel Z offset

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

float hash1(float n) { return fract(sin(n) * 43758.5453); }
float hash1v(float2 p) { return fract(sin(dot(p, float2(127.1, 311.7))) * 43758.5453); }

// Glow line SDF helper
float glowLine(float d, float width, float blur) {
    return smoothstep(blur, 0.0, abs(d) - width);
}

// Phosphor primary color — leans into palette but always glows green-ish
float3 phosphorColor(int pal, float t, float intensity) {
    // Base phosphor: palette-driven but biased toward terminal green
    float3 palCol = get_palette_color(t, pal);
    // Phosphor green anchor: mix palette with pure phosphor
    float3 pGreen = float3(0.12, 1.0, 0.22);
    float3 pAmber = float3(1.0, 0.65, 0.05);
    float3 pCyan  = float3(0.05, 0.9,  1.0);
    // Blend based on palette index groups
    float3 phosphor;
    if (pal < 8)        phosphor = mix(pGreen, palCol, 0.35);
    else if (pal < 14)  phosphor = mix(pAmber, palCol, 0.30);
    else if (pal < 20)  phosphor = mix(pCyan,  palCol, 0.30);
    else                phosphor = mix(pGreen, palCol, 0.50);
    return phosphor * intensity;
}

// ─────────────────────────────────────────────
//  WIREFRAME TUNNEL
//  Rectilinear tunnel (Computer Gaming World aesthetic)
// ─────────────────────────────────────────────

float3 draw_tunnel(float2 uv, float t, float beat, float beatPhase,
                   float energy, float complexity, float jogVal, int pal) {

    float3 col = float3(0.0);
    float aspect = 16.0 / 9.0; // handled at call site

    // Center the UV
    float2 p = uv - 0.5;

    // Tunnel: rings of rectilinear boxes converging to center
    // Number of rings driven by complexity
    int rings = 6 + int(complexity * 10.0);
    float scroll = t + jogVal * 2.0;

    float3 phColor = phosphorColor(pal, 0.5 + beat * 0.15, 1.0);
    float3 phAccent = phosphorColor(pal, 0.2, 1.2);

    for (int i = 0; i < 18; i++) {
        if (i >= rings) break;

        // Each ring at a different depth — scroll gives forward motion
        float depth = fract(float(i) / float(rings) + scroll * 0.12) + 0.001;
        float scale = depth;  // smaller depth = closer = bigger ring

        // Perspective scale: closer rings are bigger
        float sz = (1.0 - depth) * 0.52 + 0.01;

        // Box SDF for this ring
        float2 absP = abs(p);
        float boxD = max(absP.x / sz, absP.y / (sz * 0.75)) - 1.0;

        // Line glow — tighter at distance, thicker up close
        float lineW = 0.003 + (1.0 - depth) * 0.006;
        float lineB = lineW * 2.5;
        float ring_glow = glowLine(boxD, lineW, lineB);

        // Depth-based brightness — closer = brighter, with beat punch
        float brightness = (1.0 - depth * 0.7) * (0.5 + beat * 0.5);

        // Color shifts across depth
        float colorT = float(i) / float(rings) + beatPhase * 0.1;
        float3 ringColor = mix(phColor, phAccent, fract(colorT));

        col += ringColor * ring_glow * brightness * (1.0 + energy * 0.5);

        // Corner accent dots — crosshair marks at box corners
        float2 corners[4];
        corners[0] = float2( sz,  sz * 0.75);
        corners[1] = float2(-sz,  sz * 0.75);
        corners[2] = float2( sz, -sz * 0.75);
        corners[3] = float2(-sz, -sz * 0.75);

        for (int c = 0; c < 4; c++) {
            float2 cp = p - corners[c];
            float crossH = glowLine(cp.y, 0.0, lineB * 0.5) * step(abs(cp.x), lineW * 4.0);
            float crossV = glowLine(cp.x, 0.0, lineB * 0.5) * step(abs(cp.y), lineW * 4.0);
            col += ringColor * (crossH + crossV) * brightness * 0.4;
        }

        // Diagonal cross-hatching inside tunnel — appears on deeper rings
        if (depth < 0.5) {
            // Left and right vanishing edges
            float edgeL = glowLine(p.x + sz, lineW * 0.5, lineB * 0.5);
            float edgeR = glowLine(p.x - sz, lineW * 0.5, lineB * 0.5);
            float edgeT = glowLine(p.y + sz * 0.75, lineW * 0.5, lineB * 0.5);
            float edgeB = glowLine(p.y - sz * 0.75, lineW * 0.5, lineB * 0.5);

            // Only where inside the previous ring
            float prevSz = sz + 0.05;
            float inPrev = step(max(abs(p.x) / prevSz, abs(p.y) / (prevSz * 0.75)), 1.0);
            col += ringColor * (edgeL + edgeR + edgeT + edgeB) * inPrev * brightness * 0.25;
        }
    }

    // Center vanishing point glow
    float centerGlow = exp(-length(p) * 6.0) * (0.3 + beat * 0.7) * energy;
    col += phColor * centerGlow;

    return col;
}

// ─────────────────────────────────────────────
//  DIAGONAL SCAN LINES (perspective, converging)
// ─────────────────────────────────────────────

float3 draw_perspective_lines(float2 uv, float t, float beat, int pal) {
    float2 p = uv - 0.5;
    float3 col = float3(0.0);
    float3 lineCol = phosphorColor(pal, 0.6, 0.4);

    // Radial lines from center (like the CGW tunnel cover)
    int numLines = 16;
    for (int i = 0; i < numLines; i++) {
        float angle = (float(i) / float(numLines)) * 3.14159 * 2.0;
        float2 dir = float2(cos(angle), sin(angle) * 0.75); // squished for aspect
        // Line perpendicular distance
        float dist = abs(p.x * dir.y - p.y * dir.x);
        float lineG = exp(-dist * 80.0) * 0.12;
        // Fade near center and edge
        float fade = smoothstep(0.0, 0.08, length(p)) * smoothstep(0.5, 0.3, length(p));
        col += lineCol * lineG * fade * (0.3 + beat * 0.2);
    }

    return col;
}

// ─────────────────────────────────────────────
//  CRT SCANLINES + PHOSPHOR BLOOM
// ─────────────────────────────────────────────

float3 apply_crt(float3 col, float2 uv, float t, float beat, float energy) {
    // Horizontal scanlines
    float scanFreq = 180.0;
    float scan = sin(uv.y * scanFreq * 3.14159) * 0.5 + 0.5;
    scan = pow(scan, 0.4);
    col *= mix(0.65, 1.0, scan);

    // Vertical phosphor columns (finer than scanlines)
    float colScan = sin(uv.x * scanFreq * 2.0 * 3.14159) * 0.5 + 0.5;
    colScan = pow(colScan, 0.7);
    col *= mix(0.88, 1.0, colScan);

    // Slow scanline sweep (visible bright line drifting down)
    float sweepLine = fract(t * 0.15);
    float sweepBright = exp(-abs(uv.y - sweepLine) * 60.0) * 0.25 * energy;
    col += col * sweepBright;

    // Screen curvature vignette
    float2 cv = uv * 2.0 - 1.0;
    float curvature = 0.15;
    cv += cv * cv * cv * curvature;
    float vign = smoothstep(1.1, 0.5, length(cv * float2(0.9, 1.0)));
    col *= vign * vign;

    // Phosphor glow bloom (additive)
    float bloom = 1.0 + energy * 0.4 + beat * 0.3;
    col *= bloom;

    // Subtle RGB chromatic shift (CRT mask color fringing)
    // Already in col via palette; just punch the green channel slightly
    col.g = min(col.g * 1.08, 1.5);

    return col;
}

// ─────────────────────────────────────────────
//  DATA READOUT COLUMNS (side borders)
//  Cascading hex/binary text simulation
// ─────────────────────────────────────────────

float3 draw_data_columns(float2 uv, float t, float beat, float complexity, int pal) {
    float3 col = float3(0.0);
    float3 textCol = phosphorColor(pal, 0.4, 0.7);

    // Left and right column strips
    float colW = 0.10 + complexity * 0.04;
    float inLeft  = smoothstep(colW, colW - 0.01, uv.x);
    float inRight = smoothstep(1.0 - colW, 1.0 - colW + 0.01, uv.x);
    float inSide  = max(inLeft, inRight);

    if (inSide < 0.001) return col;

    // Simulate cascading characters: use hash noise at grid cells
    float charH = 0.018; // character height
    float charW = 0.012; // character width
    float row = floor(uv.y / charH);
    float col_ = floor(uv.x / charW);

    // Speed of cascade per column
    float cascadeSpeed = 1.5 + hash1(col_) * 3.0;
    float cascadeOffset = hash1(col_ * 17.3);
    float charTime = t * cascadeSpeed + cascadeOffset * 10.0;

    // Current char value (hash-based pseudo-text)
    float charVal = hash1v(float2(col_, floor(charTime)));

    // Brightness falls off downward from head of cascade
    float headY = fract(charTime * 0.1) * 1.0;
    float distFromHead = fract(uv.y - headY + 1.0);
    float brightness = exp(-distFromHead * 4.0);
    brightness *= hash1v(float2(col_, row)); // flicker per cell

    // Draw a simple blocky "character" — just bright rect with noise gaps
    float2 cellUV = float2(fract(uv.x / charW), fract(uv.y / charH));
    // 5x7-ish pixel simulation: random pixel pattern
    float px = floor(cellUV.x * 5.0);
    float py = floor(cellUV.y * 7.0);
    float pixOn = step(0.4, hash1v(float2(px + col_ * 5.0, py + row * 7.0 + floor(charTime))));

    col += textCol * pixOn * brightness * inSide * 0.8;

    // Bright head character
    float headBright = exp(-distFromHead * 30.0) * (0.8 + beat * 0.5);
    col += float3(0.8, 1.0, 0.8) * pixOn * headBright * inSide;

    // Horizontal separator lines across columns
    float sepLine = step(0.97, fract(uv.y * 14.0)) * inSide;
    col += textCol * sepLine * 0.15;

    return col;
}

// ─────────────────────────────────────────────
//  TOP/BOTTOM HUD BARS (magazine header aesthetic)
// ─────────────────────────────────────────────

float3 draw_hud_bars(float2 uv, float t, float beat, float energy, int pal) {
    float3 col = float3(0.0);
    float3 barCol = phosphorColor(pal, 0.3, 1.0);
    float3 dimCol = phosphorColor(pal, 0.7, 0.3);

    float barH = 0.055;

    // Top bar
    float inTop = smoothstep(barH, barH - 0.004, uv.y);
    float inBot = smoothstep(1.0 - barH, 1.0 - barH + 0.004, uv.y);
    float inBar = max(inTop, inBot);

    // Bar fill: dark with subtle grid
    col += dimCol * inBar * 0.08;

    // Bar border lines
    float topLine  = glowLine(uv.y - barH, 0.001, 0.004);
    float botLine  = glowLine(uv.y - (1.0 - barH), 0.001, 0.004);
    col += barCol * (topLine + botLine) * (0.6 + beat * 0.4);

    // Horizontal tick marks inside bars — simulating labels
    float ticks = step(0.5, fract(uv.x * 28.0)) * step(0.6, fract(uv.x * 7.0 + 0.2));
    col += barCol * ticks * inTop * 0.4;
    col += barCol * ticks * inBot * 0.35;

    // Blinking "active" block cursor — top left of top bar
    float cursorX = 0.08;
    float cursorBlink = step(0.5, fract(t * 1.8));
    float cursor = smoothstep(0.003, 0.0, abs(uv.x - cursorX) - 0.015)
                 * smoothstep(0.003, 0.0, abs(uv.y - barH * 0.5) - barH * 0.3);
    col += barCol * cursor * cursorBlink * (0.8 + beat * 0.6);

    // Beat flash: top bar pulses white on strong beat
    float flash = beat * beat * energy * 0.4;
    col += float3(flash) * inTop;

    return col;
}

// ─────────────────────────────────────────────
//  GLITCH DISTORTION
// ─────────────────────────────────────────────

float2 glitch_uv(float2 uv, float t, float beat) {
    // Horizontal band glitch
    float glitchRow   = floor(uv.y * 55.0 + t * 7.0);
    float glitchChance = hash1(glitchRow + floor(t * 4.0));
    float glitchActive = step(1.0 - beat * 0.55, glitchChance);
    float glitchShift  = (hash1(glitchRow) - 0.5) * 0.04 * glitchActive * beat;
    float2 g = uv;
    g.x += glitchShift;

    // Occasional vertical roll on very strong beat
    float roll = step(0.93, beat) * step(0.88, hash1(floor(t * 2.5)));
    g.y = fract(g.y + roll * 0.02);

    return g;
}

// ─────────────────────────────────────────────
//  ISOMETRIC CITY GRID OVERLAY (subtle, corners)
// ─────────────────────────────────────────────

float3 draw_iso_city(float2 uv, float t, float beat, float energy, int pal) {
    float3 col = float3(0.0);
    float3 cityCol = phosphorColor(pal, 0.55, 0.5);

    // Only in bottom corners
    float leftCorner  = smoothstep(0.25, 0.0, uv.x) * smoothstep(0.6, 0.75, uv.y);
    float rightCorner = smoothstep(0.75, 1.0, uv.x) * smoothstep(0.6, 0.75, uv.y);
    float cornerMask  = max(leftCorner, rightCorner);
    if (cornerMask < 0.001) return col;

    // Isometric grid: two diagonal line families + vertical
    float2 p = uv;
    // Lines at +30 degrees
    float iso1 = abs(fract((p.x - p.y * 0.577) * 12.0) - 0.5);
    // Lines at -30 degrees
    float iso2 = abs(fract((p.x + p.y * 0.577) * 12.0) - 0.5);
    // Vertical lines
    float iso3 = abs(fract(p.x * 12.0) - 0.5);

    float grid = max(max(
        smoothstep(0.05, 0.0, iso1),
        smoothstep(0.05, 0.0, iso2)),
        smoothstep(0.04, 0.0, iso3) * 0.5
    );

    // Building heights: random columns
    float bx = floor(uv.x * 16.0);
    float buildH = hash1(bx + floor(t * 0.1)) * 0.12;
    float buildMask = step(1.0 - buildH, uv.y);

    col += cityCol * grid * cornerMask * (0.3 + beat * 0.3 + energy * 0.2);
    col += cityCol * buildMask * cornerMask * 0.1;

    return col;
}

// ─────────────────────────────────────────────
//  MAIN FRAGMENT
// ─────────────────────────────────────────────

fragment float4 crt_tunnel(
    VertexOut in [[stage_in]],
    constant GeneratorUniforms &u [[buffer(0)]]
) {
    float2 uv = in.uv;
    float aspect = u.resolution.x / u.resolution.y;

    float t      = u.time * u.speed;
    float beat   = u.beatStrength * u.reactivity;
    float energy = u.energy;

    // ── Glitch UV ──
    float2 guv = glitch_uv(uv, t, beat);

    // ── Deep black background with slight phosphor ambient ──
    float3 col = float3(0.01, 0.025, 0.012) * (1.0 + energy * 0.3);

    // ── Perspective radial lines (tunnel depth hint) ──
    col += draw_perspective_lines(guv, t, beat, u.colorPalette);

    // ── Main wireframe tunnel ──
    col += draw_tunnel(guv, t, beat, u.beatPhase, energy, u.complexity, u.jogValue, u.colorPalette);

    // ── Isometric city corner decoration ──
    col += draw_iso_city(guv, t, beat, energy, u.colorPalette);

    // ── Data cascade columns ──
    col += draw_data_columns(guv, t, beat, u.complexity, u.colorPalette);

    // ── HUD bars ──
    col += draw_hud_bars(guv, t, beat, energy, u.colorPalette);

    // ── CRT post-process ──
    col = apply_crt(col, uv, t, beat, energy);

    // Tone map
    col = col / (col + float3(0.5));
    col = pow(max(col, 0.0), float3(0.85));

    return float4(col, 1.0);
}
