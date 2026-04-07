// nihon_grid.metal — 日本グリッド / Japanese Rock Poster
//
// Aesthetic: The Chinese Rock poster energy — dark crimson field,
// rectilinear perspective grid tunnel (floor + ceiling + walls converging),
// bold SDF kanji/katakana headline blocks, EKG divider strip,
// dot-row accents, bracketed header bar, scanline texture throughout.
//
// Uniforms:
//   time         → grid scroll, waveform animate, glyph pulse
//   beatPhase    → grid flash sync
//   beatStrength → glyph slam, waveform spike, flash
//   energy       → glow level
//   reactivity   → beat coupling
//   complexity   → grid density
//   speed        → scroll rate
//   colorPalette → color theme (crimson/green, amber/dark, cyan/black…)
//   jogValue     → manual grid scroll

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
//  COLOR THEME — derive poster colors from palette
// ─────────────────────────────────────────────

// bg: deep crimson/dark field
// grid: bright accent (green on the poster)
// typo: dominant saturated (red/orange on poster)
// sub: secondary (dimmer grid accent)

float3 bgColor(int pal) {
    // Always very dark, slightly tinted
    float3 base = get_palette_color(0.05, pal);
    return base * 0.08 + float3(0.06, 0.01, 0.01); // crimson dark default
}

float3 gridColor(int pal, float t) {
    // Bright accent — maps to the green lines in poster
    return get_palette_color(0.35 + t * 0.05, pal);
}

float3 typoColor(int pal) {
    // Dominant bold — maps to the red/orange type
    float3 warm = get_palette_color(0.85, pal);
    return warm * 1.3;
}

float3 subColor(int pal) {
    return get_palette_color(0.45, pal) * 0.7;
}

// ─────────────────────────────────────────────
//  UTILITIES
// ─────────────────────────────────────────────

float hash1(float n)  { return fract(sin(n) * 43758.5453); }
float hash2(float2 p) { return fract(sin(dot(p, float2(127.1,311.7))) * 43758.5453); }

float sdBox(float2 p, float2 b) {
    float2 d = abs(p) - b;
    return length(max(d, 0.0)) + min(max(d.x, d.y), 0.0);
}

float sdSegment(float2 p, float2 a, float2 b) {
    float2 pa = p - a, ba = b - a;
    float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
    return length(pa - ba * h);
}

float glow(float d, float w, float str) {
    return str * exp(-max(d - w, 0.0) * 60.0) * smoothstep(w + 0.01, w, d);
}

// ─────────────────────────────────────────────
//  PERSPECTIVE GRID TUNNEL
//  Floor + ceiling + left/right walls converging
//  Vanishing point at (0.5, horizon)
// ─────────────────────────────────────────────

float3 draw_grid_tunnel(float2 uv, float t, float beat, float beatPhase,
                        float energy, float complexity, float jogVal, int pal) {

    float3 col = float3(0.0);
    float3 gc  = gridColor(pal, beatPhase);

    float scroll = t + jogVal * 3.0;

    // Horizon at 45% from top — upper half is ceiling grid, lower is floor grid
    float horizon = 0.44;
    float vp_x = 0.5; // vanishing point X

    // Grid density
    float density = 6.0 + complexity * 14.0;

    // ── Floor grid (uv.y > horizon) ──
    if (uv.y > horizon) {
        float gv = (uv.y - horizon) / (1.0 - horizon);
        float depth = 0.08 / (gv + 0.005);

        float wx = (uv.x - vp_x) * depth * 1.8;
        float wz = depth - scroll * 1.2;

        float gx = abs(fract(wx * density + 0.5) - 0.5);
        float gz = abs(fract(wz * density + 0.5) - 0.5);

        float lw = 0.018 + gv * 0.02;
        float lineX = smoothstep(lw, 0.0, gx) * (0.5 + gv * 0.5);
        float lineZ = smoothstep(lw, 0.0, gz) * (0.5 + gv * 0.5);
        float grid = max(lineX, lineZ);

        float fade = smoothstep(0.0, 0.15, gv) * (1.0 - gv * 0.6);
        col += gc * grid * fade * (0.7 + beat * 0.4) * (0.6 + energy * 0.4);
    }

    // ── Ceiling grid (uv.y < horizon) ──
    if (uv.y < horizon) {
        float gv = (horizon - uv.y) / horizon;
        float depth = 0.08 / (gv + 0.005);

        float wx = (uv.x - vp_x) * depth * 1.8;
        float wz = depth - scroll * 1.2;

        float gx = abs(fract(wx * density + 0.5) - 0.5);
        float gz = abs(fract(wz * density + 0.5) - 0.5);

        float lw = 0.018 + gv * 0.02;
        float lineX = smoothstep(lw, 0.0, gx) * (0.5 + gv * 0.5);
        float lineZ = smoothstep(lw, 0.0, gz) * (0.5 + gv * 0.5);
        float grid = max(lineX, lineZ);

        float fade = smoothstep(0.0, 0.15, gv) * (1.0 - gv * 0.6);
        col += gc * grid * fade * (0.5 + beat * 0.3) * (0.5 + energy * 0.4);
    }

    // ── Radial diagonal lines converging to VP (the "perspective rays") ──
    int numRays = 12;
    for (int i = 0; i < numRays; i++) {
        float fi = float(i) / float(numRays);
        // Ray x positions spread from left to right
        float rayX = fi;
        float2 vp = float2(vp_x, horizon);
        float2 edge = float2(rayX, (fi < 0.5) ? 0.0 : 1.0);
        // Screen-space ray distance
        float d = sdSegment(uv, vp, edge);
        float rayGlow = exp(-d * 180.0) * 0.15 * (0.4 + beat * 0.3);
        col += gc * rayGlow;
    }

    // ── Horizon line ──
    float hLine = exp(-abs(uv.y - horizon) * 300.0) * (0.8 + beat * 0.5) * energy;
    col += gc * hLine;

    // ── Vanishing point bright flash ──
    float2 vp2 = float2(vp_x, horizon);
    float vpGlow = exp(-length(uv - vp2) * 25.0) * (0.2 + beat * 0.8) * energy;
    col += gc * vpGlow;

    return col;
}

// ─────────────────────────────────────────────
//  SDF KANJI / KATAKANA GLYPHS
//  Handcrafted stroke-based SDF for key characters
//  We build: 日 本 ロ ッ ク + roman title chars
// ─────────────────────────────────────────────

// SDF for a single rectangular stroke
float stroke(float2 p, float2 center, float2 size) {
    return sdBox(p - center, size);
}

// Glyph: 日 (Nichi/hi — sun/day) — two boxes with horizontal bar
float glyph_nichi(float2 p) {
    float outer = sdBox(p, float2(0.38, 0.48));
    float innerTop = stroke(p, float2(0.0, -0.1), float2(0.26, 0.15));
    float innerBot = stroke(p, float2(0.0,  0.2), float2(0.26, 0.15));
    float mid = stroke(p, float2(0.0, 0.05), float2(0.38, 0.03));
    // Outline only
    return min(abs(outer) - 0.04, min(abs(mid) - 0.03,
           min(abs(innerTop) + 0.2, abs(innerBot) + 0.2)));
}

// Glyph: 本 (Moto/hon — origin/root) — cross with extra strokes
float glyph_hon(float2 p) {
    float vert  = stroke(p, float2(0.0, 0.0),   float2(0.04, 0.48));
    float horiz = stroke(p, float2(0.0, -0.05), float2(0.38, 0.04));
    float bot   = stroke(p, float2(0.0,  0.3),  float2(0.28, 0.04));
    float diagL = sdSegment(p, float2(-0.22, 0.05), float2(-0.38, 0.4));
    float diagR = sdSegment(p, float2( 0.22, 0.05), float2( 0.38, 0.4));
    float topL  = sdSegment(p, float2(-0.05,-0.22), float2(-0.32,-0.48));
    float topR  = sdSegment(p, float2( 0.05,-0.22), float2( 0.32,-0.48));
    return min(min(min(vert, horiz), min(bot, diagL)),
               min(min(diagR, topL), topR));
}

// Glyph: ロ (Ro katakana) — square
float glyph_ro(float2 p) {
    float outer = sdBox(p, float2(0.38, 0.44));
    float inner = sdBox(p, float2(0.26, 0.31));
    return min(abs(outer) - 0.05, inner + 0.3);
}

// Glyph: ッ (Tsu small katakana) — three strokes
float glyph_tsu(float2 p) {
    float s1 = sdSegment(p, float2(-0.35, -0.1), float2(-0.10, 0.35));
    float s2 = sdSegment(p, float2(-0.02, -0.1), float2( 0.10, 0.35));
    float s3 = sdSegment(p, float2( 0.20, -0.1), float2( 0.38, 0.35));
    float top = sdSegment(p, float2(-0.38, -0.35), float2(0.38, -0.18));
    return min(min(s1, s2), min(s3, top));
}

// Glyph: ク (Ku katakana)
float glyph_ku(float2 p) {
    float top  = sdSegment(p, float2(-0.38, -0.35), float2(0.32, -0.35));
    float vert = sdSegment(p, float2( 0.32, -0.35), float2( 0.10,  0.48));
    float d1   = sdSegment(p, float2(-0.10, -0.05), float2(-0.38,  0.38));
    return min(min(top, vert), d1);
}

// Draw a glyph at position with stroke width
float drawGlyph(int id, float2 p, float sw) {
    float d;
    if      (id == 0) d = glyph_nichi(p);
    else if (id == 1) d = glyph_hon(p);
    else if (id == 2) d = glyph_ro(p);
    else if (id == 3) d = glyph_tsu(p);
    else              d = glyph_ku(p);
    return smoothstep(sw, 0.0, d);
}

// ─────────────────────────────────────────────
//  TYPOGRAPHY LAYOUT
//  Top header: bracket + katakana title
//  Lower half: big bold kanji block + sub line
// ─────────────────────────────────────────────

float3 draw_typography(float2 uv, float t, float beat, float energy, int pal) {
    float3 col     = float3(0.0);
    float3 typoCol = typoColor(pal);
    float3 accentCol = gridColor(pal, 0.0) * 1.2;

    // ── TOP HEADER BAR ──
    // "[  ロ ッ ク  ]" style bracket header
    float headerY  = 0.07;
    float headerH  = 0.055;
    float inHeader = smoothstep(headerH, headerH - 0.003, abs(uv.y - headerY));

    // Bracket lines: left [ and right ]
    float brackLx = 0.05;
    float brackRx = 0.95;
    float brackW  = 0.018;

    // Left bracket
    float bL_vert = exp(-abs(uv.x - brackLx)  * 400.0) * step(abs(uv.y - headerY), headerH);
    float bL_top  = exp(-abs(uv.y - (headerY - headerH)) * 600.0)
                  * step(brackLx, uv.x) * step(uv.x, brackLx + brackW);
    float bL_bot  = exp(-abs(uv.y - (headerY + headerH)) * 600.0)
                  * step(brackLx, uv.x) * step(uv.x, brackLx + brackW);
    col += accentCol * (bL_vert + bL_top + bL_bot) * 0.9;

    // Right bracket
    float bR_vert = exp(-abs(uv.x - brackRx)  * 400.0) * step(abs(uv.y - headerY), headerH);
    float bR_top  = exp(-abs(uv.y - (headerY - headerH)) * 600.0)
                  * step(brackRx - brackW, uv.x) * step(uv.x, brackRx);
    float bR_bot  = exp(-abs(uv.y - (headerY + headerH)) * 600.0)
                  * step(brackRx - brackW, uv.x) * step(uv.x, brackRx);
    col += accentCol * (bR_vert + bR_top + bR_bot) * 0.9;

    // Header center: three katakana glyphs: ロ ッ ク (Rock)
    float glyphScale = 0.042;
    float2 headerCenter = float2(0.5, headerY);

    // ロ at center-left of header
    {
        float2 lp = (uv - float2(0.37, headerY)) / glyphScale;
        col += accentCol * drawGlyph(2, lp, 0.12) * (0.7 + beat * 0.4);
    }
    // ッ center
    {
        float2 lp = (uv - float2(0.50, headerY)) / glyphScale;
        col += accentCol * drawGlyph(3, lp, 0.12) * (0.7 + beat * 0.4);
    }
    // ク right
    {
        float2 lp = (uv - float2(0.63, headerY)) / glyphScale;
        col += accentCol * drawGlyph(4, lp, 0.12) * (0.7 + beat * 0.4);
    }

    // Header side text dots (date columns like the poster)
    for (int d = 0; d < 5; d++) {
        float dx = 0.14 + float(d) * 0.012;
        float dotY = headerY - 0.025 + float(d % 3) * 0.022;
        float dot = exp(-length(uv - float2(dx, dotY)) * 250.0);
        col += accentCol * dot * 0.6;
    }
    for (int d = 0; d < 5; d++) {
        float dx = 0.86 - float(d) * 0.012;
        float dotY = headerY - 0.025 + float(d % 3) * 0.022;
        float dot = exp(-length(uv - float2(dx, dotY)) * 250.0);
        col += accentCol * dot * 0.6;
    }

    // ── EKG / WAVEFORM DIVIDER ──
    // Separates grid zone from type zone — horizontal bar with a waveform
    float ekgY = 0.56;
    float ekgH = 0.022;
    float inEkg = smoothstep(ekgH, ekgH - 0.003, abs(uv.y - ekgY));

    // Background fill for EKG strip
    col += float3(0.0) * inEkg; // intentionally black — cuts against bg

    // EKG border lines
    col += accentCol * exp(-abs(uv.y - (ekgY - ekgH)) * 500.0) * 0.7;
    col += accentCol * exp(-abs(uv.y - (ekgY + ekgH)) * 500.0) * 0.7;

    // Waveform signal inside EKG strip
    {
        float wx = (uv.x - 0.3) * 12.0 + t * 2.0;
        // Composite waveform: sharp spikes like ECG
        float wave = 0.0;
        wave += 0.4 * sin(wx * 1.0);
        wave += 0.3 * sin(wx * 2.3 + 1.0);
        // Sharp spike
        float spike = exp(-abs(fract(wx * 0.15) - 0.5) * 22.0) * 1.8;
        wave += spike * 0.6;
        wave *= 0.55; // normalize
        wave = ekgY + wave * ekgH * 0.7;
        float wDist = abs(uv.y - wave);
        float wGlow = exp(-wDist * 400.0) * (1.0 + beat * 1.0);
        float inWaveX = step(0.05, uv.x) * step(uv.x, 0.95);
        col += accentCol * wGlow * inWaveX * (0.6 + energy * 0.5);
    }

    // Decade labels on EKG sides: "1990S" left, "2019S" right (simulated as dashes)
    // Left tick pattern
    for (int i = 0; i < 4; i++) {
        float tx = 0.06 + float(i) * 0.018;
        float tickG = exp(-abs(uv.x - tx) * 300.0) * step(abs(uv.y - ekgY), ekgH * 0.5);
        col += accentCol * tickG * 0.5;
    }
    // Right tick pattern
    for (int i = 0; i < 4; i++) {
        float tx = 0.94 - float(i) * 0.018;
        float tickG = exp(-abs(uv.x - tx) * 300.0) * step(abs(uv.y - ekgY), ekgH * 0.5);
        col += accentCol * tickG * 0.5;
    }

    // ── DOT ROW accent (between header and grid) ──
    float dotRowY = 0.145;
    // 5 dots left group, 5 dots right group
    for (int d = 0; d < 5; d++) {
        float dx = 0.12 + float(d) * 0.04;
        float dotR = 0.008 + beat * 0.003;
        float dotD = length(uv - float2(dx, dotRowY)) - dotR;
        col += accentCol * glow(dotD, 0.0, 0.6 + beat * 0.5);
        // right side
        float dx2 = 0.88 - float(d) * 0.04;
        float dotD2 = length(uv - float2(dx2, dotRowY)) - dotR;
        col += accentCol * glow(dotD2, 0.0, 0.6 + beat * 0.5);
    }

    // ── BIG BOLD KANJI BLOCK ──
    // Two rows of two glyphs: 日 本 / ロ ッ
    // Bottom half of screen, below EKG divider
    // These are LARGE — they dominate like the poster's red characters

    // Beat-driven vertical slam: glyphs drop in on strong beat
    float slam = 1.0 + beat * beat * 0.015;

    float bigScale  = 0.115 * slam;
    float typoTop   = 0.65; // Y center of first row
    float typoBot   = 0.80; // Y center of second row

    // Row 1 glyph 1: 日
    {
        float2 lp = (uv - float2(0.28, typoTop)) / bigScale;
        float g = drawGlyph(0, lp, 0.06);
        col += typoCol * g * (0.85 + beat * 0.4);
        // Heavy glow halo
        float2 lp2 = (uv - float2(0.28, typoTop)) / (bigScale * 1.4);
        float g2 = drawGlyph(0, lp2, 0.08);
        col += typoCol * g2 * 0.15 * energy;
    }
    // Row 1 glyph 2: 本
    {
        float2 lp = (uv - float2(0.60, typoTop)) / bigScale;
        float g = drawGlyph(1, lp, 0.06);
        col += typoCol * g * (0.85 + beat * 0.4);
        float2 lp2 = (uv - float2(0.60, typoTop)) / (bigScale * 1.4);
        float g2 = drawGlyph(1, lp2, 0.08);
        col += typoCol * g2 * 0.15 * energy;
    }
    // Row 2 glyph 1: ロ (larger variant)
    {
        float2 lp = (uv - float2(0.28, typoBot)) / bigScale;
        float g = drawGlyph(2, lp, 0.06);
        col += typoCol * g * (0.9 + beat * 0.45);
        float2 lp2 = (uv - float2(0.28, typoBot)) / (bigScale * 1.4);
        float g2 = drawGlyph(2, lp2, 0.08);
        col += typoCol * g2 * 0.18 * energy;
    }
    // Row 2 glyph 2: ッ
    {
        float2 lp = (uv - float2(0.60, typoBot)) / bigScale;
        float g = drawGlyph(3, lp, 0.06);
        col += typoCol * g * (0.9 + beat * 0.45);
        float2 lp2 = (uv - float2(0.60, typoBot)) / (bigScale * 1.4);
        float g2 = drawGlyph(3, lp2, 0.08);
        col += typoCol * g2 * 0.18 * energy;
    }

    // ── SMALL SUBTITLE LINE (bottom) ──
    // Simulated as a thin horizontal rule + tick marks (text implied)
    float subY = 0.935;
    col += subColor(pal) * exp(-abs(uv.y - subY) * 400.0) * step(0.05, uv.x) * step(uv.x, 0.95) * 0.6;
    // Tick-mark "characters"
    for (int i = 0; i < 28; i++) {
        float tx = 0.08 + float(i) * 0.033;
        float th = 0.006 + hash1(float(i)) * 0.008;
        float tickG = exp(-abs(uv.x - tx) * 500.0) * step(abs(uv.y - subY), th);
        col += subColor(pal) * tickG * (0.4 + hash1(float(i) * 3.7) * 0.4);
    }

    // ── VERTICAL SIDE TEXT ──
    // Rotated thin text columns like the poster's side labels
    // Simulated as repeated thin vertical dashes
    float sideW = 0.016;
    // Left side column
    float inLeftSide = smoothstep(sideW, sideW - 0.003, uv.x);
    float vText = step(0.5, hash2(float2(floor(uv.y * 40.0 + t * 0.3), 0.0)));
    col += subColor(pal) * vText * inLeftSide * 0.35;

    // Right side column
    float inRightSide = smoothstep(1.0 - sideW, 1.0 - sideW + 0.003, uv.x);
    float vText2 = step(0.5, hash2(float2(floor(uv.y * 40.0 + t * 0.3), 1.0)));
    col += subColor(pal) * vText2 * inRightSide * 0.35;

    // ── HORIZON LABEL DOTS (like "2005 s." "2015 s." annotations) ──
    // Small floating dots scattered in the grid zone
    for (int d = 0; d < 6; d++) {
        float angle = float(d) * 1.047 + t * 0.05;
        float radius = 0.08 + float(d) * 0.055;
        float2 dotPos = float2(0.5 + cos(angle) * radius * 0.9,
                                0.30 + sin(angle) * radius * 0.28);
        dotPos.y = clamp(dotPos.y, 0.16, 0.52);
        float dotD = length(uv - dotPos) - 0.004;
        col += accentCol * glow(dotD, 0.0, 0.5 + beat * 0.3);
    }

    return col;
}

// ─────────────────────────────────────────────
//  SCANLINE TEXTURE
// ─────────────────────────────────────────────

float3 apply_scanlines(float3 col, float2 uv, float t, float energy) {
    // Horizontal scanlines — fine
    float scan = pow(sin(uv.y * 3.14159 * 140.0) * 0.5 + 0.5, 0.3);
    col *= mix(0.78, 1.0, scan);

    // Slow rolling highlight
    float roll = fract(t * 0.08);
    float rollLine = exp(-abs(uv.y - roll) * 50.0) * 0.12 * energy;
    col += col * rollLine;

    // Vignette — stronger corners, print-poster feel
    float2 vig = (uv - 0.5) * 2.0;
    float v = 1.0 - dot(vig * float2(0.7, 0.85), vig * float2(0.7, 0.85));
    col *= max(v * v * 0.7 + 0.5, 0.0);

    return col;
}

// ─────────────────────────────────────────────
//  GLITCH
// ─────────────────────────────────────────────

float2 glitch_uv(float2 uv, float t, float beat) {
    float row = floor(uv.y * 60.0 + t * 6.0);
    float g   = hash1(row + floor(t * 3.0));
    float active = step(1.0 - beat * 0.45, g);
    uv.x += (hash1(row) - 0.5) * 0.035 * active * beat;
    return uv;
}

// ─────────────────────────────────────────────
//  MAIN
// ─────────────────────────────────────────────

fragment float4 nihon_grid(
    VertexOut in [[stage_in]],
    constant GeneratorUniforms &u [[buffer(0)]]
) {
    float2 uv    = in.uv;
    float t      = u.time * u.speed;
    float beat   = u.beatStrength * u.reactivity;
    float energy = u.energy;
    int   pal    = u.colorPalette;

    // Glitch distortion
    float2 guv = glitch_uv(uv, t, beat);

    // ── BACKGROUND ──
    // Deep crimson-dark — reddish-near-black, slightly lighter at center
    float3 col = bgColor(pal);
    float centerGlow = exp(-length(uv - float2(0.5, 0.44)) * 2.5) * 0.06 * energy;
    col += get_palette_color(0.5, pal) * centerGlow;

    // Subtle noise grain (poster texture)
    float grain = hash2(guv * float2(531.0, 723.0) + t * 0.1) * 0.03;
    col += float3(grain);

    // ── GRID TUNNEL ──
    // Only render in upper portion (grid zone) — below header, above EKG
    float inGridZone = step(0.145, guv.y) * step(guv.y, 0.58);
    col += draw_grid_tunnel(guv, t, beat, u.beatPhase, energy, u.complexity, u.jogValue, pal)
           * mix(0.3, 1.0, inGridZone);

    // ── TYPOGRAPHY ──
    col += draw_typography(guv, t, beat, energy, pal);

    // ── SCANLINES + POST ──
    col = apply_scanlines(col, uv, t, energy);

    // Tone map + gamma
    col = col / (col + float3(0.4));
    col = pow(max(col, 0.0), float3(0.88));

    return float4(col, 1.0);
}
