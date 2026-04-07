// biocore_monitor.metal — Biological Systems Monitor
//
// Aesthetic: Contamination / biolab monitoring station on pure black.
// ECG heartbeat lines, cellular hex grid panels, DNA column readout,
// organ status rings with fill levels, viral load tile matrices,
// drip counter, specimen scan reticle, pressure/temperature gauges.
// Flat, crisp, no gradients — pure signal art.
// Native palette: acid green, deep red, white, amber on black.
//
// colorPalette = 0  →  native biocore colors
// colorPalette 1-32 →  full VKO1 cosine palette recoloring
//
// Uniforms used:
//   time         → animation, ECG scroll, cell cycle
//   beatPhase    → ECG spike timing
//   beatStrength → cardiac spike amplitude  ← PRIMARY BEAT DRIVER
//   energy       → overall system health / brightness
//   reactivity   → beat coupling
//   complexity   → cell density, detail level
//   speed        → ECG and scroll rate
//   colorPalette → 0 = native, 1-32 = cosine recolor
//   jogValue     → specimen scan position / manual scrub

#include <metal_stdlib>
using namespace metal;

// ─── VKO1 cosine palette ──────────────────────────────────────────────────────
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

// ─── Recolor ──────────────────────────────────────────────────────────────────
float3 recolor(float3 native_col, float hue, int pal) {
    if (pal == 0) return native_col;
    float lum = dot(native_col, float3(0.299, 0.587, 0.114));
    return get_palette_color(hue + lum * 0.35, pal) * (0.15 + lum * 1.5);
}

// ─── Hash ─────────────────────────────────────────────────────────────────────
float h1(float  n) { return fract(sin(n) * 43758.5453); }
float h2(float2 p) { return fract(sin(dot(p, float2(127.1, 311.7))) * 43758.5453); }

// ─── Native palette ───────────────────────────────────────────────────────────
float3 bGreen()  { return float3(0.08, 1.00, 0.10); }  // acid green
float3 bRed()    { return float3(1.00, 0.05, 0.05); }  // deep red
float3 bWhite()  { return float3(1.00, 1.00, 1.00); }  // white
float3 bAmber()  { return float3(1.00, 0.70, 0.00); }  // amber
float3 bCyan()   { return float3(0.00, 0.90, 0.80); }  // bio-cyan

// ─── Shape primitives ─────────────────────────────────────────────────────────
float fillRect(float2 uv, float x0, float y0, float x1, float y1) {
    return step(x0,uv.x)*step(uv.x,x1)*step(y0,uv.y)*step(uv.y,y1);
}
float borderRect(float2 uv, float x0, float y0, float x1, float y1, float th) {
    return fillRect(uv,x0,y0,x1,y1) - fillRect(uv,x0+th,y0+th,x1-th,y1-th);
}
float fillCircle(float2 uv, float2 c, float r) {
    return step(length(uv-c), r);
}
float ringCircle(float2 uv, float2 c, float r, float th) {
    float d = length(uv-c);
    return step(r-th,d)*step(d,r);
}
float hLine(float2 uv, float y, float x0, float x1, float th) {
    return fillRect(uv, x0, y-th, x1, y+th);
}
float vLine(float2 uv, float x, float y0, float y1, float th) {
    return fillRect(uv, x-th, y0, x+th, y1);
}
float bracketCorners(float2 uv, float x0, float y0, float x1, float y1, float arm, float th) {
    float m = 0.0;
    m += fillRect(uv,x0,y0,x0+arm,y0+th); m += fillRect(uv,x0,y0,x0+th,y0+arm);
    m += fillRect(uv,x1-arm,y0,x1,y0+th); m += fillRect(uv,x1-th,y0,x1,y0+arm);
    m += fillRect(uv,x0,y1-th,x0+arm,y1); m += fillRect(uv,x0,y1-arm,x0+th,y1);
    m += fillRect(uv,x1-arm,y1-th,x1,y1); m += fillRect(uv,x1-th,y1-arm,x1,y1);
    return clamp(m,0.0,1.0);
}

// ─── ECG / HEARTBEAT LINE ─────────────────────────────────────────────────────
// Classic PQRST cardiac waveform scrolling left, beat drives spike height
// jogValue scrubs the waveform phase manually
float3 draw_ecg(float2 uv, float x0, float y0, float pw, float ph,
                float t, float beat, float beatPhase, float jogValue, int pal) {
    float3 col = float3(0.0);
    if (uv.x < x0 || uv.x > x0+pw || uv.y < y0 || uv.y > y0+ph) return col;

    float lx = (uv.x - x0) / pw;
    float ly = (uv.y - y0) / ph;

    // Scroll position — jog scrubs phase
    float scroll = fract(t * 0.55 + jogValue * 0.5);
    float phase  = fract(lx - scroll + 1.0); // 0→1 across one heartbeat cycle

    // PQRST wave construction
    float wave = 0.5;
    // P wave (small bump)
    wave += 0.06 * exp(-pow((phase - 0.12) * 25.0, 2.0));
    // Q dip
    wave -= 0.04 * exp(-pow((phase - 0.22) * 35.0, 2.0));
    // R spike — beat drives height
    float rHeight = 0.32 + beat * 0.28;
    wave += rHeight * exp(-pow((phase - 0.27) * 55.0, 2.0));
    // S dip
    wave -= 0.09 * exp(-pow((phase - 0.32) * 40.0, 2.0));
    // T wave
    wave += 0.08 * exp(-pow((phase - 0.50) * 18.0, 2.0));
    // Baseline noise
    wave += sin(phase * 180.0 + t * 2.0) * 0.008;

    float dist = abs(ly - wave);
    // Color: green normally, spikes red on heavy beat
    float isSpike = smoothstep(0.10, 0.0, abs(phase - 0.27));
    float3 lineC  = mix(recolor(bGreen(), 0.3, pal),
                        recolor(bRed(),   0.0, pal), isSpike * beat);
    col += lineC * smoothstep(0.035, 0.0, dist) * 1.8;
    col += lineC * smoothstep(0.10,  0.0, dist) * 0.25;

    // Scan head dot — moving read head
    float headX = fract(t * 0.55 + jogValue * 0.5);
    float headDist = abs(lx - headX);
    col += recolor(bAmber(), 0.15, pal) * smoothstep(0.01, 0.0, headDist)
         * smoothstep(0.05, 0.0, dist);

    return col;
}

// ─── CELLULAR HEX GRID ───────────────────────────────────────────────────────
// Honeycomb cell pattern, cells activate/deactivate like living tissue
// jogValue shifts which cell column is active
float3 draw_hex_grid(float2 uv, float x0, float y0, float pw, float ph,
                     float t, float beat, float jogValue, int pal) {
    float3 col = float3(0.0);
    if (uv.x < x0 || uv.x > x0+pw || uv.y < y0 || uv.y > y0+ph) return col;

    float2 local = (uv - float2(x0, y0)) / float2(pw, ph);
    float  cellSize = 0.065;
    // Hex grid: offset alternating rows
    float row  = floor(local.y / (cellSize * 0.866));
    float offset = (fmod(row, 2.0) > 0.5) ? cellSize * 0.5 : 0.0;
    float col_f = floor((local.x + offset) / cellSize);
    float2 cellCenter = float2((col_f + 0.5) * cellSize - offset,
                               (row + 0.5) * cellSize * 0.866);
    float2 cellUV  = local - cellCenter;
    float  hexDist = max(abs(cellUV.x), abs(cellUV.x * 0.5 + cellUV.y * 0.866));
    float  hexSize = cellSize * 0.42;

    // Cell activity from hash — jog shifts which cells are lit
    float seed   = h2(float2(col_f, row) + float2(floor(t * 0.4 + jogValue * 3.0), 0.0));
    float active = step(0.45, seed);
    float pulse  = 0.5 + 0.5 * sin(t * 1.8 + seed * 6.28);

    float3 fillC = (seed > 0.7) ? recolor(bRed(), 0.0, pal)
                 : (seed > 0.5) ? recolor(bAmber(), 0.15, pal)
                 :                recolor(bGreen(), 0.3, pal);

    // Hex border
    float border = step(hexDist, hexSize) - step(hexDist, hexSize * 0.82);
    col += recolor(bGreen(), 0.3, pal) * border * 0.4;
    // Hex fill
    float fill = step(hexDist, hexSize * 0.78) * active * (0.6 + pulse * 0.4 + beat * 0.3);
    col += fillC * fill;

    return col;
}

// ─── DNA COLUMN ───────────────────────────────────────────────────────────────
// Vertical double-helix with rungs, scrolls upward
// jogValue scrubs vertical position
float3 draw_dna(float2 uv, float cx, float y0, float h,
                float t, float beat, float jogValue, int pal) {
    float3 col  = float3(0.0);
    if (uv.x < cx-0.040 || uv.x > cx+0.040 || uv.y < y0 || uv.y > y0+h) return col;

    float ly    = (uv.y - y0) / h;        // 0-1 within column
    float scroll = t * 0.4 + jogValue * 0.8;
    float freq   = 12.0;                   // helix frequency
    float phase  = (ly + scroll) * freq;

    // Two backbone strands
    float strand1X = cx + sin(phase)        * 0.028;
    float strand2X = cx + sin(phase + 3.14) * 0.028;
    float3 sc1 = recolor(bGreen(), 0.3, pal);
    float3 sc2 = recolor(bRed(),   0.0, pal);

    col += sc1 * smoothstep(0.006, 0.0, abs(uv.x - strand1X));
    col += sc2 * smoothstep(0.006, 0.0, abs(uv.x - strand2X));

    // Rungs — connect the two strands at regular intervals
    float rungPhase = fract(phase / (2.0 * 3.14159));
    float rungMask  = smoothstep(0.06, 0.0, abs(rungPhase - 0.5));
    // Horizontal rung line
    float minX = min(strand1X, strand2X);
    float maxX = max(strand1X, strand2X);
    float inRung = step(minX, uv.x) * step(uv.x, maxX);
    float3 rungC = recolor(bWhite(), 0.0, pal);
    col += rungC * inRung * rungMask * 0.7;

    // Base-pair dots at rung midpoints
    float2 rungMid = float2((strand1X + strand2X) * 0.5, uv.y);
    col += rungC * fillCircle(uv, rungMid, 0.007 * (1.0 + beat * 0.2)) * rungMask;

    return col;
}

// ─── ORGAN STATUS RING ────────────────────────────────────────────────────────
// Circular fill-level gauge like organ capacity indicator
// jogValue offsets the fill angle start
float3 draw_organ_ring(float2 uv, float2 ctr, float r,
                       float fill, float t, float beat, float jogValue,
                       float3 fillC, float3 borderC, int pal) {
    float3 col = float3(0.0);
    float2 d   = uv - ctr;
    float  dist = length(d);
    float  angle = atan2(d.y, d.x) + 1.5708 + jogValue * 1.0; // jog rotates start angle
    float  normA = fract(angle / 6.2831 + 1.0);

    // Border ring
    col += recolor(borderC, 0.0, pal) * ringCircle(uv, ctr, r, 0.005);

    // Fill arc
    float inFill = step(normA, fill) * step(dist, r-0.007) * step(r-0.025, dist);
    col += recolor(fillC, 0.1, pal) * inFill * (0.8 + beat * 0.2);

    // Center status dot
    float3 dotC = (fill > 0.7) ? bGreen() : (fill > 0.4 ? bAmber() : bRed());
    col += recolor(dotC, fill * 0.3, pal) * fillCircle(uv, ctr, r * 0.22 * (1.0 + beat * 0.1));

    return col;
}

// ─── VIRAL LOAD TILE MATRIX ───────────────────────────────────────────────────
// Dense grid of red/amber tiles representing infection density
// jogValue shifts the tile pattern
float3 draw_viral_tiles(float2 uv, float x0, float y0, float x1, float y1,
                        float t, float beat, float jogValue, int pal) {
    float3 col = float3(0.0);
    if (uv.x < x0 || uv.x > x1 || uv.y < y0 || uv.y > y1) return col;
    float cw = (x1-x0) / 10.0, ch = (y1-y0) / 8.0;
    float2 cell = floor((uv - float2(x0,y0)) / float2(cw,ch));
    float  seed = h2(cell + float2(floor(t * 0.9 + jogValue * 3.0), 0.0));
    float  on   = step(0.38, seed);
    float3 c;
    if      (seed > 0.75) c = recolor(bRed(),   0.0, pal);
    else if (seed > 0.55) c = recolor(bAmber(), 0.1, pal);
    else                  c = recolor(bGreen(),  0.3, pal);
    return c * on * (0.65 + beat * 0.35);
}

// ─── DRIP COUNTER ─────────────────────────────────────────────────────────────
// Animated falling drop dots in a vertical column, count resets on beat
float3 draw_drip(float2 uv, float cx, float y0, float h,
                 float t, float beat, int pal) {
    float3 col  = float3(0.0);
    float3 gc   = recolor(bGreen(), 0.3, pal);
    float3 wc   = recolor(bWhite(), 0.0, pal);

    // Vertical tube outline
    col += wc * vLine(uv, cx-0.010, y0, y0+h, 0.002);
    col += wc * vLine(uv, cx+0.010, y0, y0+h, 0.002);
    col += wc * hLine(uv, y0+h, cx-0.012, cx+0.012, 0.002);

    // Falling drops — 5 drops staggered
    for (int i = 0; i < 5; i++) {
        float fi    = float(i);
        float phase = fract(t * 0.8 + fi * 0.2);
        float dy    = y0 + h - phase * h;  // falls top to bottom
        float fade  = 1.0 - phase;
        col += gc * fillCircle(uv, float2(cx, dy), 0.007 * fade * (1.0 + beat * 0.2));
    }

    return col;
}

// ─── PRESSURE GAUGE (semicircle arc + needle) ─────────────────────────────────
// jogValue controls needle position
float3 draw_pressure(float2 uv, float2 ctr, float r,
                     float t, float beat, float jogValue, int pal) {
    float3 col  = float3(0.0);
    float3 wc   = recolor(bWhite(),  0.0, pal);
    float3 gc   = recolor(bGreen(),  0.3, pal);
    float3 rc   = recolor(bRed(),    0.0, pal);
    float3 ac   = recolor(bAmber(),  0.1, pal);

    float2 d    = uv - ctr;
    float  dist = length(d);
    float  angle = atan2(d.y, d.x); // -pi to pi

    // Semicircle arc (bottom half open) — from -3pi/4 to -pi/4 range displayed
    float arcStart = -3.1416 * 0.75;
    float arcEnd   =  3.1416 * 0.75;
    float normAngle = (angle - arcStart) / (arcEnd - arcStart);
    float inArc    = step(arcStart, angle) * step(angle, arcEnd)
                   * step(r - 0.006, dist) * step(dist, r);
    // Color coded arc: green safe, amber warning, red danger
    float3 arcC = (normAngle < 0.5) ? gc : (normAngle < 0.75 ? ac : rc);
    arcC = recolor(arcC, normAngle * 0.4, pal);
    col += arcC * inArc;

    // Tick marks
    for (int i = 0; i <= 8; i++) {
        float fi    = float(i) / 8.0;
        float ta    = arcStart + fi * (arcEnd - arcStart);
        float2 tip  = ctr + float2(cos(ta), sin(ta)) * r;
        float2 inn  = ctr + float2(cos(ta), sin(ta)) * (r - 0.022);
        float2 mid2 = (tip + inn) * 0.5;
        col += wc * fillCircle(uv, mid2, 0.005);
    }

    // Needle — jogValue controls position across the arc range
    float needlePos = clamp(jogValue * 0.5 + 0.5, 0.0, 1.0);
    float needleA   = arcStart + needlePos * (arcEnd - arcStart);
    float2 needleTip = ctr + float2(cos(needleA), sin(needleA)) * r * 0.78;
    float2 needleMid = (needleTip + ctr) * 0.5;
    col += ac * fillCircle(uv, needleMid, 0.009 + beat * 0.005);
    col += ac * fillCircle(uv, needleTip, 0.007);
    col += wc * fillCircle(uv, ctr, 0.013 * (1.0 + beat * 0.15));
    col += wc * ringCircle(uv, ctr, 0.018, 0.003);

    return col;
}

// ─────────────────────────────────────────────────────────────────────────────
fragment float4 biocore_monitor(
    VertexOut in [[stage_in]],
    constant GeneratorUniforms &u [[buffer(0)]]
) {
    float2 uv    = in.uv;
    float  t     = u.time * u.speed;
    float  beat  = u.beatStrength * u.reactivity;
    float  energy= u.energy;
    int    pal   = u.colorPalette;
    float  jog   = u.jogValue;
    float  th    = 0.003;

    float3 col  = float3(0.0);

    float3 wc  = recolor(bWhite(),  0.0, pal);
    float3 gc  = recolor(bGreen(),  0.3, pal);
    float3 rc  = recolor(bRed(),    0.0, pal);
    float3 ac  = recolor(bAmber(),  0.1, pal);
    float3 cc  = recolor(bCyan(),   0.2, pal);

    // ══════════════════════════════════════════════════════════════════════
    //  TOP: ECG STRIP — full width, primary display
    // ══════════════════════════════════════════════════════════════════════
    {
        float px = 0.010, py = 0.870, pw = 0.980, ph = 0.110;
        col += wc * borderRect(uv, px, py, px+pw, py+ph, th);
        col += draw_ecg(uv, px+0.005, py+0.005, pw-0.010, ph-0.010,
                        t, beat, u.beatPhase, jog, pal);
        // BPM label block
        col += ac * fillRect(uv, px+0.010, py+ph-0.025, px+0.060, py+ph-0.015);
        // CARDIAC label top-right
        col += gc * fillRect(uv, px+pw-0.090, py+ph-0.025, px+pw-0.010, py+ph-0.015);
    }

    // Second ECG strip (different channel)
    {
        float px = 0.010, py = 0.748, pw = 0.600, ph = 0.100;
        col += wc * borderRect(uv, px, py, px+pw, py+ph, th);
        col += draw_ecg(uv, px+0.005, py+0.005, pw-0.010, ph-0.010,
                        t * 1.3, beat * 0.8, u.beatPhase, jog * 0.6, pal);
    }

    // ══════════════════════════════════════════════════════════════════════
    //  MID-LEFT: CELLULAR HEX GRID
    // ══════════════════════════════════════════════════════════════════════
    {
        float px = 0.010, py = 0.405, pw = 0.340, ph = 0.325;
        col += wc * bracketCorners(uv, px, py, px+pw, py+ph, 0.022, th);
        col += draw_hex_grid(uv, px+0.006, py+0.006, pw-0.012, ph-0.012,
                             t, beat, jog, pal);
        // CELL label
        col += gc * fillRect(uv, px+0.010, py+0.008, px+0.055, py+0.018);
    }

    // ══════════════════════════════════════════════════════════════════════
    //  MID-CENTER: DNA COLUMN
    // ══════════════════════════════════════════════════════════════════════
    {
        float cx = 0.500, py = 0.390, h = 0.355;
        col += wc * borderRect(uv, cx-0.055, py, cx+0.055, py+h, th);
        col += draw_dna(uv, cx, py+0.005, h-0.010, t, beat, jog, pal);
        // DNA label
        col += gc * fillRect(uv, cx-0.045, py+h-0.022, cx+0.045, py+h-0.012);
    }

    // ══════════════════════════════════════════════════════════════════════
    //  MID-RIGHT: ORGAN STATUS RINGS (4 organs)
    // ══════════════════════════════════════════════════════════════════════
    {
        float fills[4]   = { 0.82, 0.55, 0.38, 0.71 };
        float2 ctrs[4]   = {
            float2(0.720, 0.660),
            float2(0.840, 0.660),
            float2(0.720, 0.545),
            float2(0.840, 0.545)
        };
        float3 fColors[4] = { bGreen(), bAmber(), bRed(), bGreen() };
        for (int i = 0; i < 4; i++) {
            float fillLevel = clamp(fills[i] + sin(t * 0.4 + float(i)) * 0.08
                                  + beat * 0.05, 0.0, 1.0);
            col += draw_organ_ring(uv, ctrs[i], 0.048, fillLevel,
                                   t, beat, jog, fColors[i], bWhite(), pal);
            // Label below each ring
            col += wc * fillRect(uv, ctrs[i].x-0.030, ctrs[i].y-0.060,
                                 ctrs[i].x+0.030, ctrs[i].y-0.052);
        }
        // Outer bracket
        col += wc * bracketCorners(uv, 0.665, 0.488, 0.900, 0.720, 0.018, th);
    }

    // ══════════════════════════════════════════════════════════════════════
    //  RIGHT-MID: VIRAL LOAD TILE MATRIX
    // ══════════════════════════════════════════════════════════════════════
    {
        float px = 0.620, py = 0.390, pw = 0.370, ph = 0.085;
        col += wc * borderRect(uv, px, py, px+pw, py+ph, th);
        col += draw_viral_tiles(uv, px+0.004, py+0.004,
                               px+pw-0.004, py+ph-0.004, t, beat, jog, pal);
        // VIRAL label
        col += rc * fillRect(uv, px+0.008, py+ph-0.020, px+0.060, py+ph-0.012);
    }

    // ══════════════════════════════════════════════════════════════════════
    //  RIGHT-UPPER: Pressure/temp gauges
    // ══════════════════════════════════════════════════════════════════════
    {
        col += draw_pressure(uv, float2(0.730, 0.285), 0.072, t, beat, jog, pal);
        col += draw_pressure(uv, float2(0.860, 0.285), 0.072, t*1.2, beat, jog*0.6, pal);
        // Labels
        col += wc * fillRect(uv, 0.690, 0.200, 0.770, 0.208);
        col += wc * fillRect(uv, 0.822, 0.200, 0.900, 0.208);
    }

    // ══════════════════════════════════════════════════════════════════════
    //  LOWER-LEFT: DRIP COUNTER columns
    // ══════════════════════════════════════════════════════════════════════
    {
        for (int i = 0; i < 4; i++) {
            float fi = float(i);
            float cx = 0.045 + fi * 0.048;
            col += draw_drip(uv, cx, 0.035, 0.350, t + fi * 0.25, beat, pal);
        }
        // Base label row
        col += gc * fillRect(uv, 0.010, 0.030, 0.230, 0.040);
    }

    // ══════════════════════════════════════════════════════════════════════
    //  LOWER-CENTER: Specimen scan reticle
    // ══════════════════════════════════════════════════════════════════════
    {
        float2 ctr = float2(0.500, 0.195);
        float  r   = 0.140;

        // Outer bracket frame
        col += wc * bracketCorners(uv, ctr.x-r, ctr.y-r*0.75,
                                   ctr.x+r, ctr.y+r*0.75, 0.022, th);
        // Concentric scan rings — innermost pulses on beat
        col += cc * ringCircle(uv, ctr, r * 0.68, 0.004);
        col += cc * ringCircle(uv, ctr, r * 0.42, 0.003) * (0.7 + beat * 0.3);
        col += gc * ringCircle(uv, ctr, r * 0.20, 0.004) * (0.5 + beat * 0.5);

        // Cross-hair
        col += wc * 0.4 * hLine(uv, ctr.y, ctr.x-r*0.90, ctr.x-r*0.30, th);
        col += wc * 0.4 * hLine(uv, ctr.y, ctr.x+r*0.30, ctr.x+r*0.90, th);
        col += wc * 0.4 * vLine(uv, ctr.x, ctr.y-r*0.70, ctr.y-r*0.22, th);
        col += wc * 0.4 * vLine(uv, ctr.x, ctr.y+r*0.22, ctr.y+r*0.70, th);

        // Rotating scan arm — jog controls angle
        float scanA = t * 0.9 + jog * 6.2831;
        float2 scanTip = ctr + float2(cos(scanA), sin(scanA)) * r * 0.65;
        float2 scanMid = (scanTip + ctr) * 0.5;
        col += gc * fillCircle(uv, scanMid, 0.010 + beat * 0.006);

        // Specimen dot center — pulses on beat
        col += rc * fillCircle(uv, ctr, 0.015 * (1.0 + beat * 0.35));
        col += wc * ringCircle(uv, ctr, 0.022, 0.003);

        // Sample blips around inner ring
        for (int i = 0; i < 6; i++) {
            float fi    = float(i);
            float ba    = fi * 1.0472 + t * 0.2;
            float2 bpos = ctr + float2(cos(ba), sin(ba)) * r * 0.42;
            float3 bc2  = (i % 2 == 0) ? gc : rc;
            bc2         = recolor(bc2, fi * 0.15, pal);
            col        += bc2 * fillCircle(uv, bpos, 0.009 * (1.0 + beat * 0.2));
        }
    }

    // ══════════════════════════════════════════════════════════════════════
    //  LOWER-RIGHT: Horizontal status bars (system readouts)
    // ══════════════════════════════════════════════════════════════════════
    {
        float px = 0.625, py = 0.035, pw = 0.365, ph = 0.345;
        col += wc * borderRect(uv, px, py, px+pw, py+ph, th);
        float bh = 0.024, gap = 0.035;
        float3 barColors[8] = {gc, gc, ac, rc, gc, ac, gc, rc};
        for (int i = 0; i < 8; i++) {
            float fi   = float(i);
            float by   = py + 0.018 + fi * gap;
            float fill = clamp(0.15 + h1(fi*5.7 + floor(t*0.45 + jog*2.0))*0.85, 0.0, 1.0);
            float3 c   = recolor(barColors[i], fi * 0.10, pal);
            // Alert flash on critical bars when fill is low
            float alert = (i == 3 || i == 7) ? step(fill, 0.35) * step(0.5, beat) : 0.0;
            c           = mix(c, rc, alert);
            col        += c * 0.09 * fillRect(uv, px+0.010, by, px+pw-0.010, by+bh);
            col        += c        * fillRect(uv, px+0.010, by,
                                             px+0.010+(pw-0.020)*fill, by+bh);
            // Tick mark right edge
            col += wc * fillRect(uv, px+pw-0.015, by+0.004,
                                 px+pw-0.008, by+bh-0.004);
        }
    }

    // ══════════════════════════════════════════════════════════════════════
    //  TOP-RIGHT: Secondary ECG + time display block
    // ══════════════════════════════════════════════════════════════════════
    {
        float px = 0.620, py = 0.748, pw = 0.370, ph = 0.100;
        col += wc * borderRect(uv, px, py, px+pw, py+ph, th);
        col += draw_ecg(uv, px+0.005, py+0.005, pw-0.010, ph-0.010,
                        t * 0.9, beat, u.beatPhase, jog * 0.8, pal);
    }

    // ══════════════════════════════════════════════════════════════════════
    //  GLOBAL FX
    // ══════════════════════════════════════════════════════════════════════

    // Heartbeat scan flash — vertical white line that sweeps on each beat spike
    {
        float beatDecay = exp(-u.beatPhase * 6.0) * beat;
        float scanX     = fract(t * 0.55 + jog * 0.5);
        float beam      = exp(-abs(uv.x - scanX) * 80.0) * beatDecay * 0.35;
        col            += gc * beam;
    }

    // Horizontal scan sweep
    {
        float scanY = fract(t * 0.14 + jog * 0.35);
        float beam  = exp(-abs(uv.y - scanY) * 70.0) * (0.03 + beat * 0.07);
        col += cc * beam;
    }

    // Beat flash
    {
        float flash = max(0.0, beat - 0.82) * 3.5 * step(u.beatPhase, 0.05);
        col = mix(col, wc, flash * 0.15);
    }

    // Chromatic aberration on beat
    {
        float ca = 0.0012 + beat * 0.006;
        col.r += ca * sin(uv.y * 75.0 + t * 2.7) * beat * 0.45;
        col.b -= ca * sin(uv.y * 75.0 - t * 2.0) * beat * 0.45;
    }

    // Fine CRT scanlines
    col *= 0.91 + 0.09 * sin(uv.y * u.resolution.y * 1.57);

    // Film grain
    col += (h2(uv + fract(t * 8.7)) - 0.5) * 0.016;

    col = clamp(col * (0.83 + energy * 0.37), 0.0, 1.0);
    return float4(col, 1.0);
}
