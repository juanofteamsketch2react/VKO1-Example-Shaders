// system_crash_hud.metal — SYSTEM FAILURE glitch diagnostic HUD
//
// Aesthetic: Dense information panels on pure black. Neon magenta, cyan,
// lime-green, red, blue, white — pixel-sharp bars, status nodes, column
// charts, progress meters, bracket frames, and cascading "ERR / SYSTEM
// OFFLINE" glitch blocks. Everything snaps, jumps and tears with the beat.
// Directly inspired by corrupted-terminal / system-crash art (image 1).
//
// colorPalette = 0  →  native neon (matches reference image exactly)
// colorPalette 1-32 →  full VKO1 cosine palette recoloring
//
// Uniforms used:
//   time         → animation, flicker, bar updates
//   beatPhase    → snap timing for glitch panels
//   beatStrength → horizontal tear / glitch intensity  ← PRIMARY BEAT DRIVER
//   energy       → overall brightness
//   reactivity   → beat coupling strength
//   complexity   → panel density, bar count
//   speed        → scroll and animation rate
//   colorPalette → 0 = native neon, 1-32 = cosine palette recolor
//   jogValue     → manual horizontal phase shift

#include <metal_stdlib>
using namespace metal;

// ─── VKO1 cosine palette (33 presets) ────────────────────────────────────────
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

// ─── Recolor helper ───────────────────────────────────────────────────────────
// pal == 0  → keep native neon color exactly
// pal  > 0  → map native luminance through cosine palette hue
float3 recolor(float3 native_col, float hue_seed, int pal) {
    if (pal == 0) return native_col;
    float lum = dot(native_col, float3(0.299, 0.587, 0.114));
    return get_palette_color(hue_seed + lum * 0.35, pal) * (0.15 + lum * 1.5);
}

// ─── Hash utilities ───────────────────────────────────────────────────────────
float h1(float  n) { return fract(sin(n) * 43758.5453); }
float h2(float2 p) { return fract(sin(dot(p, float2(127.1, 311.7))) * 43758.5453); }

// ─── Native neon palette (image 1 exact hues) ────────────────────────────────
float3 nMagenta() { return float3(1.00, 0.05, 0.82); }
float3 nCyan()    { return float3(0.00, 0.95, 1.00); }
float3 nLime()    { return float3(0.50, 1.00, 0.00); }
float3 nBlue()    { return float3(0.05, 0.20, 1.00); }
float3 nRed()     { return float3(1.00, 0.05, 0.08); }
float3 nWhite()   { return float3(1.00, 1.00, 1.00); }
float3 nYellow()  { return float3(1.00, 0.92, 0.00); }

float3 neon(int idx) {
    switch (idx % 7) {
        case 0: return nMagenta();
        case 1: return nCyan();
        case 2: return nLime();
        case 3: return nBlue();
        case 4: return nRed();
        case 5: return nWhite();
        default: return nYellow();
    }
}

// ─── Glitch-displaced UV ──────────────────────────────────────────────────────
// jogValue → per-band horizontal tear + global frame nudge, like scrubbing
// a corrupted scanline buffer by hand.
float2 glitchUV(float2 uv, float t, float beat, float jogValue) {
    float band    = floor(uv.y * 60.0 + t * 4.5);
    float trigger = step(1.0 - beat * 0.72, h1(band * 0.41));
    float offset  = (h1(band + 17.3) - 0.5) * 0.058 * beat;
    uv.x         += offset * trigger;
    // Jog: deterministic per-band tear — each row shifts a different amount
    float jogBand  = floor(uv.y * 48.0);
    uv.x          += (h1(jogBand * 0.73) - 0.5) * 0.06 * jogValue;
    // Jog: global frame nudge so full-frame drifts with wheel position
    uv.x          += jogValue * 0.04;
    float bigJump  = step(0.96, beat) * step(0.92, h1(floor(t * 1.9)));
    uv.y          += (h1(floor(t * 6.7)) - 0.5) * 0.008 * bigJump;
    return uv;
}

// ─── Shape primitives ────────────────────────────────────────────────────────
float fillRect(float2 uv, float x0, float y0, float x1, float y1) {
    return step(x0, uv.x) * step(uv.x, x1) * step(y0, uv.y) * step(uv.y, y1);
}
float borderRect(float2 uv, float x0, float y0, float x1, float y1, float th) {
    float o = fillRect(uv, x0, y0, x1, y1);
    float i = fillRect(uv, x0+th, y0+th, x1-th, y1-th);
    return o - i;
}
float fillCircle(float2 uv, float2 ctr, float r) {
    return step(length(uv - ctr), r);
}
float ringCircle(float2 uv, float2 ctr, float r, float th) {
    float d = length(uv - ctr);
    return step(r - th, d) * step(d, r);
}
float bracketCorners(float2 uv, float x0, float y0, float x1, float y1,
                     float arm, float th) {
    float m = 0.0;
    m += fillRect(uv, x0,      y0,      x0+arm,  y0+th);
    m += fillRect(uv, x0,      y0,      x0+th,   y0+arm);
    m += fillRect(uv, x1-arm,  y0,      x1,      y0+th);
    m += fillRect(uv, x1-th,   y0,      x1,      y0+arm);
    m += fillRect(uv, x0,      y1-th,   x0+arm,  y1);
    m += fillRect(uv, x0,      y1-arm,  x0+th,   y1);
    m += fillRect(uv, x1-arm,  y1-th,   x1,      y1);
    m += fillRect(uv, x1-th,   y1-arm,  x1,      y1);
    return clamp(m, 0.0, 1.0);
}

// ─── Waveform ─────────────────────────────────────────────────────────────────
float3 draw_waveform(float2 uv, float x0, float y0, float pw, float ph,
                     float t, float beat, float energy, float jogValue, int pal) {
    float3 col = float3(0.0);
    if (uv.x < x0 || uv.x > x0+pw || uv.y < y0 || uv.y > y0+ph) return col;
    float lx = (uv.x - x0) / pw;
    float ly = (uv.y - y0) / ph;
    // jogValue scrubs the waveform phase — wheel left/right scrolls the signal
    float jPhase = jogValue * 6.2831;
    float wave = 0.5
        + sin(lx * 20.0 + t * 3.2 + jPhase) * 0.20 * (1.0 + beat * 0.5)
        + sin(lx *  7.3 - t * 1.8 + jPhase * 0.5) * 0.10
        + sin(lx * 38.0 + t * 5.7 + jPhase * 2.0) * 0.04 * energy;
    float dist = abs(ly - wave);
    float3 wc = recolor(nCyan(), 0.2, pal);
    col += wc * smoothstep(0.045, 0.0, dist) * 1.6;
    col += wc * smoothstep(0.14,  0.0, dist) * 0.3;
    return col;
}

// ─── Column bar chart ─────────────────────────────────────────────────────────
// jogValue → offsets the time seed so wheel scrubs bar heights manually
float3 draw_bar_chart(float2 uv, float x0, float baseY, float pw, float ph,
                      int cnt, float t, float beat, float jogValue, int pal) {
    float3 col = float3(0.0);
    float slot = pw / float(cnt);
    float bw   = slot * 0.68;
    for (int i = 0; i < cnt; i++) {
        float fi = float(i);
        float cx = x0 + (fi + 0.5) * slot;
        float bh = ph * (0.12 + h1(fi*7.3 + floor(t*0.7 + jogValue*2.0)) * 0.88);
        bh *= 1.0 + beat * h1(fi*3.1) * 0.4;
        float3 c = recolor(neon(i), fi*0.13, pal);
        float mask = fillRect(uv, cx-bw*0.5, baseY-bh, cx+bw*0.5, baseY);
        col += c * mask;
    }
    return col;
}

// ─── Horizontal progress bars ─────────────────────────────────────────────────
float3 draw_h_bars(float2 uv, float x0, float y0, float pw, float bh,
                   int cnt, float t, float beat, int pal) {
    float3 col = float3(0.0);
    float gap = bh * 2.0;
    for (int i = 0; i < cnt; i++) {
        float fi   = float(i);
        float by   = y0 + fi * gap;
        float fill = clamp(0.15 + h1(fi*5.3+floor(t*0.4))*0.85
                           + beat*0.1*h1(fi*2.7), 0.0, 1.0);
        float3 c   = recolor(neon(i), fi*0.11+0.1, pal);
        col += c * 0.09 * fillRect(uv, x0, by, x0+pw, by+bh);        // track
        col += c        * fillRect(uv, x0, by, x0+pw*fill, by+bh);    // fill
    }
    return col;
}

// ─── Status dots row ─────────────────────────────────────────────────────────
float3 draw_dots(float2 uv, float x0, float y0, int cnt,
                 float spacing, float r, float t, float beat, int pal) {
    float3 col = float3(0.0);
    for (int i = 0; i < cnt; i++) {
        float fi   = float(i);
        float3 c   = recolor(neon((i*3)%7), fi*0.17, pal);
        float pulse = 1.0 + beat * 0.45 * h1(fi*4.3);
        col += c * fillCircle(uv, float2(x0+fi*spacing, y0), r*pulse);
    }
    return col;
}

// ─── ERR glitch tile grid ─────────────────────────────────────────────────────
// jogValue → shifts which tile columns are active, like scrubbing through error states
float3 draw_err_tiles(float2 uv, float x0, float y0, float x1, float y1,
                      float t, float beat, float jogValue, int pal) {
    float3 col = float3(0.0);
    if (uv.x < x0 || uv.x > x1 || uv.y < y0 || uv.y > y1) return col;
    float cw = (x1-x0)/7.0, ch = (y1-y0)/6.0;
    float2 cell = floor((uv-float2(x0,y0))/float2(cw,ch));
    // jogValue scrolls the tile seed horizontally — wheel reveals different error patterns
    float  seed = h2(cell + float2(floor(t*1.1 + jogValue * 3.0), 0.0));
    float  on   = step(0.38, seed);
    float3 c    = recolor(neon(int(seed*6.9)), seed*0.45, pal);
    return c * on * (0.75 + beat*0.25);
}

// ─── Animated sweep pipes ─────────────────────────────────────────────────────
// jogValue → offsets the sweep phase so the wheel manually scrubs the fill position
float3 draw_pipes(float2 uv, float x0, float y0, float pw, float ph,
                  float t, float beat, float jogValue, int pal) {
    float3 col = float3(0.0);
    float th   = 0.0035;
    for (int i = 0; i < 6; i++) {
        float fi    = float(i);
        float ly    = y0 + (fi+0.5) * ph / 6.0;
        float maxLen = pw * (0.25 + h1(fi*3.9)*0.75);
        // jog offsets the sweep fract — turning the wheel scrubs all pipes
        float sweep  = fract(t*0.35 + fi*0.18 + jogValue * 0.5);
        float3 c     = recolor(neon(i), fi*0.14, pal);
        col += c * 0.18 * fillRect(uv, x0, ly-th, x0+maxLen, ly+th);
        col += c * fillRect(uv, x0, ly-th, x0+maxLen*sweep, ly+th);
    }
    return col;
}

// ─────────────────────────────────────────────────────────────────────────────
fragment float4 system_crash_hud(
    VertexOut in [[stage_in]],
    constant GeneratorUniforms &u [[buffer(0)]]
) {
    float2 uv    = in.uv;
    float  t     = u.time * u.speed;
    float  beat  = u.beatStrength * u.reactivity;
    float  energy= u.energy;
    int    pal   = u.colorPalette;

    float2 guv = glitchUV(uv, t, beat, u.jogValue);

    float3 col = float3(0.0);   // pure black base

    // ── TOP STATUS STRIP ──────────────────────────────────────────────────
    {
        float3 wc = recolor(nWhite(), 0.0, pal);
        float3 cc = recolor(nCyan(), 0.2, pal);
        float3 mc = recolor(nMagenta(), 0.0, pal);
        col += wc * fillRect(guv, 0.00, 0.972, 1.00, 0.980);
        col += cc * fillRect(guv, 0.04, 0.972, 0.24, 0.980);
        col += mc * fillRect(guv, 0.26, 0.972, 0.44, 0.980);
        col += cc * fillRect(guv, 0.05, 0.960, 0.19, 0.967);
        col += mc * fillRect(guv, 0.21, 0.960, 0.33, 0.967);
    }

    // ── TOP-LEFT: COLUMN CHART (TERMINAL) ────────────────────────────────
    {
        float px=0.010, py=0.730, pw=0.215, ph=0.225;
        float3 wc = recolor(nWhite(), 0.0, pal);
        col += wc * bracketCorners(guv, px, py, px+pw, py+ph, 0.022, 0.003);
        col += draw_bar_chart(guv, px+0.010, py+ph-0.010, pw-0.020, ph-0.040,
                              6, t, beat, u.jogValue, pal);
        // Small label text at top
        col += wc * fillRect(guv, px+0.010, py+ph-0.025, px+0.080, py+ph-0.019);
    }

    // ── TOP-CENTER: HUL BX labels + colored bar set ───────────────────────
    {
        float px=0.250, py=0.750, pw=0.180, ph=0.215;
        // Progress bars A1-A5
        col += draw_h_bars(guv, px, py+0.010, pw, 0.020, 5, t, beat, pal);
        // Side tick marks
        float3 lc = recolor(nLime(), 0.4, pal);
        for (int i = 0; i < 5; i++) {
            float ly = py+0.010 + float(i)*0.040;
            col += lc * fillRect(guv, px-0.014, ly+0.004, px-0.005, ly+0.012);
        }
    }

    // ── TOP-RIGHT: DEFRAG bar chart ───────────────────────────────────────
    {
        float px=0.715, py=0.740, pw=0.275, ph=0.235;
        float3 wc = recolor(nWhite(), 0.0, pal);
        col += wc * bracketCorners(guv, px, py, px+pw, py+ph, 0.020, 0.003);
        col += draw_bar_chart(guv, px+0.010, py+ph-0.010, pw-0.020, ph-0.050,
                              9, t*1.4, beat, u.jogValue, pal);
        col += wc * fillRect(guv, px+0.010, py+ph-0.030, px+0.100, py+ph-0.024);
    }

    // ── UPPER-LEFT SECOND ROW: three status circles ────────────────────────
    {
        float py = 0.615;
        col += draw_dots(guv, 0.055, py, 3, 0.090, 0.032, t, beat, pal);
        float3 lc = recolor(nWhite(), 0.0, pal);
        col += lc * fillRect(guv, 0.055, py-0.002, 0.230, py+0.002);
        // Login/password bar blocks below dots
        float3 bc = recolor(nWhite(), 0.0, pal);
        col += bc * fillRect(guv, 0.065, py-0.055, 0.220, py-0.047);
        col += bc * fillRect(guv, 0.065, py-0.082, 0.200, py-0.074);
    }

    // ── MID-LEFT: pipe / sweep connector lines ────────────────────────────
    {
        col += draw_pipes(guv, 0.010, 0.350, 0.220, 0.220, t, beat, u.jogValue, pal);
    }

    // ── MID-CENTER-LEFT: MVF terminal command bars ─────────────────────────
    {
        float px=0.240, py=0.420, pw=0.225, ph=0.285;
        float3 wc = recolor(nWhite(), 0.0, pal);
        col += wc * borderRect(guv, px, py, px+pw, py+ph, 0.003);
        // TERMINAL label at top
        col += wc * fillRect(guv, px+0.010, py+ph-0.028, px+0.080, py+ph-0.022);
        // 4 colored command bars
        float3 bColors[4] = { nMagenta(), nBlue(), nLime(), nCyan() };
        for (int i = 0; i < 4; i++) {
            float fi = float(i);
            float by = py + 0.040 + fi * 0.058;
            float bw = (0.075 + h1(fi*9.3)*0.110) * (1.0 + beat*0.12);
            float3 c = recolor(bColors[i], fi*0.12, pal);
            col += c * fillRect(guv, px+0.010, by, px+0.010+bw, by+0.025);
            float3 lc = recolor(nWhite(), 0.0, pal);
            col += lc * fillRect(guv, px+0.010, by+0.027, px+0.075, by+0.032);
        }
    }

    // ── MID-CENTER: waveform / oscilloscope ───────────────────────────────
    {
        float px=0.470, py=0.470, pw=0.225, ph=0.105;
        float3 wc = recolor(nWhite(), 0.0, pal);
        col += wc * borderRect(guv, px, py, px+pw, py+ph, 0.002);
        col += draw_waveform(guv, px+0.003, py+0.010, pw-0.006, ph-0.018,
                             t, beat, energy, u.jogValue, pal);
    }

    // ── MID-CENTER upper: stacked mixed color bars ─────────────────────────
    {
        float px=0.470, py=0.295, pw=0.240, ph=0.162;
        float3 cA = recolor(nMagenta(), 0.0, pal);
        float3 cB = recolor(nCyan(), 0.2, pal);
        float3 cC = recolor(nLime(), 0.4, pal);
        float3 cD = recolor(nBlue(), 0.6, pal);
        float3 rowColors[4] = { cA, cB, cC, cD };
        for (int i = 0; i < 4; i++) {
            float fi  = float(i);
            float by  = py + fi * 0.034;
            float bLen = pw * clamp(0.25 + h1(fi*5.9+floor(t*0.55))*0.75, 0.0, 1.0);
            col += rowColors[i] * fillRect(guv, px, by, px+bLen, by+0.024);
        }
        // White border
        float3 wc = recolor(nWhite(), 0.0, pal);
        col += wc * borderRect(guv, px, py, px+pw, py+ph, 0.002);
    }

    // ── MID-RIGHT: A1 2.0.x readout list ─────────────────────────────────
    {
        float px=0.720, py=0.395, pw=0.155, ph=0.268;
        float3 wc = recolor(nWhite(), 0.0, pal);
        col += wc * borderRect(guv, px, py, px+pw, py+ph, 0.002);
        float3 lc = recolor(nLime(), 0.4, pal);
        float3 dc = recolor(nMagenta(), 0.0, pal);
        for (int i = 0; i < 5; i++) {
            float fi = float(i);
            float ly = py + 0.028 + fi * 0.042;
            float bw = pw * (0.45 + h1(fi*7.3)*0.45);
            col += lc * fillRect(guv, px+0.010, ly, px+0.010+bw*0.55, ly+0.016);
            col += dc * fillCircle(guv, float2(px+0.010+bw*0.62, ly+0.008), 0.006);
        }
    }

    // ── BIG NUMBER "104" (center, mid) ────────────────────────────────────
    {
        float3 nc = recolor(nWhite(), 0.0, pal);
        float bx = 0.465, by = 0.620, bh = 0.085;
        // "1"
        col += nc * fillRect(guv, bx+0.000, by, bx+0.009, by+bh);
        // "0" (ring)
        col += nc * borderRect(guv, bx+0.016, by, bx+0.054, by+bh, 0.009);
        // "4"
        col += nc * fillRect(guv, bx+0.060, by+bh*0.40, bx+0.098, by+bh*0.50);
        col += nc * fillRect(guv, bx+0.060, by,         bx+0.070, by+bh);
        col += nc * fillRect(guv, bx+0.088, by,         bx+0.098, by+bh);
    }

    // ── LOWER-LEFT: SYSTEM OFFLINE frame + circle + colored blocks ────────
    {
        float px=0.010, py=0.035, pw=0.210, ph=0.265;
        float3 wc = recolor(nWhite(), 0.0, pal);
        col += wc * borderRect(guv, px, py, px+pw, py+ph, 0.003);
        // OFFLINE ring
        float2 ctr = float2(px+0.065, py+0.140);
        col += wc * ringCircle(guv, ctr, 0.048, 0.005);
        col += wc * ringCircle(guv, ctr, 0.055, 0.002);
        // Filled blocks (smiley face tiles in blue and red)
        float3 bc = recolor(nBlue(), 0.6, pal);
        float3 rc = recolor(nRed(), 0.0, pal);
        col += bc * fillRect(guv, px+0.100, py+0.055, px+0.100+0.045, py+0.200);
        col += rc * fillRect(guv, px+0.148, py+0.055, px+0.148+0.050, py+0.200);
        // Eyes / cross pattern in white
        float3 ewc = recolor(nWhite(), 0.0, pal);
        col += ewc * fillRect(guv, px+0.112, py+0.110, px+0.124, py+0.135);
        col += ewc * fillRect(guv, px+0.158, py+0.110, px+0.170, py+0.135);
        col += ewc * fillRect(guv, px+0.112, py+0.160, px+0.185, py+0.168);
    }

    // ── LOWER-CENTER: ERR glitch tile grid ───────────────────────────────
    {
        col += draw_err_tiles(guv, 0.470, 0.035, 0.710, 0.268, t, beat, u.jogValue, pal);
        // ERR label bars
        float3 ec = recolor(nRed(), 0.0, pal);
        col += ec * fillRect(guv, 0.480, 0.048, 0.575, 0.063);
        col += ec * fillRect(guv, 0.480, 0.095, 0.548, 0.110);
        col += ec * fillRect(guv, 0.560, 0.200, 0.630, 0.215);
    }

    // ── LOWER-RIGHT: cascading ERR staircase ─────────────────────────────
    {
        float px=0.720, py=0.035, pw=0.270, ph=0.350;
        float3 ec = recolor(nRed(), 0.0, pal);
        float3 mc = recolor(nMagenta(), 0.0, pal);
        col += ec * bracketCorners(guv, px, py, px+pw, py+ph, 0.024, 0.004);
        for (int i = 0; i < 6; i++) {
            float fi  = float(i);
            float bx  = px+0.010 + fi*0.018;
            float by  = py+0.070 + fi*0.038;
            float bw2 = pw*0.35 - fi*0.012;
            float3 c  = (i%2==0) ? ec : mc;
            col += c * fillRect(guv, bx, by, bx+bw2, by+0.026);
        }
        // Bottom ERR blocks
        col += ec * fillRect(guv, px+0.035, py+0.315, px+0.115, py+0.340);
        col += mc * fillRect(guv, px+0.135, py+0.285, px+0.215, py+0.308);
        col += ec * fillRect(guv, px+0.170, py+0.315, px+0.255, py+0.340);
    }

    // ── MID-LEFT upper: DIAG connector grid ───────────────────────────────
    {
        float px=0.470, py=0.582, pw=0.240, ph=0.095;
        float3 wc = recolor(nWhite(), 0.0, pal);
        col += wc * borderRect(guv, px, py, px+pw, py+ph, 0.002);
        // ACTIVE SCAN label
        float3 lc = recolor(nLime(), 0.4, pal);
        col += lc * fillRect(guv, px+0.010, py+0.010, px+0.090, py+0.018);
        // Diagonal connector lines (streaming)
        for (int i = 0; i < 5; i++) {
            float fi    = float(i);
            float lx    = px+0.010 + fi*(pw-0.020)/4.0;
            float sweep = fract(t*0.28 + fi*0.19);
            col += wc * 0.6 * fillRect(guv, lx, py+0.025, lx+0.003, py+0.025+ph*0.65*sweep);
        }
    }

    // ── RIGHT: stacked column readout (NET.HUB style) ────────────────────
    {
        float px=0.880, py=0.235, pw=0.110, ph=0.145;
        float3 wc = recolor(nWhite(), 0.0, pal);
        col += wc * borderRect(guv, px, py, px+pw, py+ph, 0.002);
        // Small arrow shapes
        float3 ac = recolor(nLime(), 0.4, pal);
        for (int i = 0; i < 3; i++) {
            float fi = float(i);
            float ay = py + 0.025 + fi * 0.040;
            col += ac * fillRect(guv, px+0.015, ay, px+0.030, ay+0.010);
            col += ac * fillRect(guv, px+0.025, ay-0.008, px+0.033, ay+0.018);
        }
        // Vertical bar graph
        col += draw_bar_chart(guv, px+0.040, py+ph-0.010, pw-0.050, ph-0.035,
                              4, t*1.2, beat, u.jogValue, pal);
    }

    // ── SCAN LINE SWEEP ────────────────────────────────────────────────────
    {
        float scanY = fract(t * 0.20 + u.jogValue * 0.5);
        float beam  = exp(-abs(guv.y - scanY) * 60.0) * (0.05 + beat * 0.10);
        float3 sc   = recolor(nCyan(), 0.2, pal);
        col += sc * beam;
    }

    // ── BEAT FLASH ────────────────────────────────────────────────────────
    {
        float flash = max(0.0, beat - 0.80) * 4.0 * step(u.beatPhase, 0.06);
        col = mix(col, recolor(nWhite(), 0.0, pal), flash * 0.20);
    }

    // ── CHROMATIC ABERRATION ──────────────────────────────────────────────
    {
        float ca = 0.0018 + beat * 0.008;
        col.r = col.r + ca * sin(guv.y * 90.0 + t * 3.1) * beat * 0.6;
        col.b = col.b - ca * sin(guv.y * 90.0 - t * 2.3) * beat * 0.6;
    }

    // ── CRT SCANLINES ─────────────────────────────────────────────────────
    col *= 0.87 + 0.13 * sin(guv.y * u.resolution.y * 1.57);

    // ── PIXEL GRID TEXTURE ────────────────────────────────────────────────
    {
        float2 pg = fract(guv * float2(u.resolution.x/2.0, u.resolution.y/2.0));
        col *= (pg.x > 0.07 && pg.y > 0.07) ? 1.0 : 0.82;
    }

    // ── FILM GRAIN ────────────────────────────────────────────────────────
    col += (h2(guv + fract(t * 11.7)) - 0.5) * 0.020;

    col = clamp(col * (0.82 + energy * 0.38), 0.0, 1.0);
    return float4(col, 1.0);
}
