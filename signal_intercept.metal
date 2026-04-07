// signal_intercept.metal — Radio / Satellite Intercept Terminal
//
// Aesthetic: Cold-war signals intelligence station on pure black.
// Rotating radar sweeps, frequency spectrum columns, waveform decoders,
// crosshair targeting reticles, transmission burst blocks, antenna
// schematics, bearing readouts. Dense, flat, no gradients.
// Native palette: orange, acid-green, white, red on black.
//
// colorPalette = 0  →  native signal-terminal colors
// colorPalette 1-32 →  full VKO1 cosine palette recoloring
//
// Uniforms used:
//   time         → sweep rotation, signal animation
//   beatPhase    → burst timing
//   beatStrength → transmission spike intensity  ← PRIMARY BEAT DRIVER
//   energy       → overall brightness / signal strength
//   reactivity   → beat coupling
//   complexity   → spectrum density, grid detail
//   speed        → sweep and scroll rate
//   colorPalette → 0 = native, 1-32 = cosine recolor
//   jogValue     → manual bearing/azimuth control

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
float3 sOrange() { return float3(1.00, 0.50, 0.00); }
float3 sGreen()  { return float3(0.10, 1.00, 0.20); }
float3 sWhite()  { return float3(1.00, 1.00, 1.00); }
float3 sRed()    { return float3(1.00, 0.05, 0.05); }
float3 sCyan()   { return float3(0.00, 0.85, 1.00); }
float3 sAmber()  { return float3(1.00, 0.75, 0.00); }

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

// ─── RADAR SCOPE ─────────────────────────────────────────────────────────────
// Full rotating radar sweep with contact blips and range rings
// jogValue → controls bearing offset (manual azimuth)
float3 draw_radar(float2 uv, float2 ctr, float r, float t,
                  float beat, float jogValue, int pal) {
    float3 col = float3(0.0);
    float2 d   = uv - ctr;
    float  dist = length(d);
    if (dist > r + 0.005) return col;

    float3 gc = recolor(sGreen(), 0.3, pal);
    float3 oc = recolor(sOrange(), 0.1, pal);
    float3 wc = recolor(sWhite(), 0.0, pal);

    // Range rings (4 concentric)
    for (int i = 1; i <= 4; i++) {
        float rr = r * float(i) / 4.0;
        col += gc * 0.25 * ringCircle(uv, ctr, rr, 0.0025);
    }

    // Cross-hair lines
    col += gc * 0.20 * hLine(uv, ctr.y, ctr.x-r, ctr.x+r, 0.0018);
    col += gc * 0.20 * vLine(uv, ctr.x, ctr.y-r, ctr.y+r, 0.0018);

    // Outer ring solid border
    col += gc * ringCircle(uv, ctr, r, 0.004);

    // Sweep arm — rotates with time + jogValue controls azimuth
    float sweepAngle = t * 1.2 + jogValue * 6.2831;
    float2 sweepDir = float2(cos(sweepAngle), sin(sweepAngle));
    float sweepDot  = dot(normalize(d + float2(0.00001)), sweepDir);

    // Sweep trail — fades in behind the arm
    float angleDiff = fract((atan2(d.y, d.x) - sweepAngle) / 6.2831 + 1.0);
    float trail = smoothstep(0.0, 0.18, angleDiff) * step(dist, r);
    col += gc * trail * 0.35 * smoothstep(0.0, 0.02, dist);

    // Sweep arm bright line
    float armWidth = 0.025;
    float armMask  = smoothstep(armWidth, 0.0, abs(1.0 - sweepDot)) * step(0.02, dist) * step(dist, r);
    col += gc * armMask * (0.9 + beat * 0.4);

    // Contact blips — hash-placed, brighten as sweep passes
    for (int i = 0; i < 8; i++) {
        float fi     = float(i);
        float bAngle = h1(fi * 7.3) * 6.2831;
        float bDist  = (0.25 + h1(fi * 3.1) * 0.65) * r;
        float2 bPos  = ctr + float2(cos(bAngle), sin(bAngle)) * bDist;
        float bDiff  = fract((bAngle - sweepAngle) / 6.2831 + 1.0);
        float bBright = exp(-bDiff * 8.0) * (0.5 + beat * h1(fi) * 0.5);
        float3 bc2    = (i % 3 == 0) ? oc : gc;
        bc2           = recolor(bc2, fi * 0.12, pal);
        col          += bc2 * fillCircle(uv, bPos, 0.008 * (1.0 + bBright)) * bBright;
        col          += bc2 * ringCircle(uv, bPos, 0.013, 0.003) * bBright * 0.6;
    }

    return col;
}

// ─── FREQUENCY SPECTRUM ──────────────────────────────────────────────────────
// Vertical bar spectrum analyzer, jogValue scrubs frequency display offset
float3 draw_spectrum(float2 uv, float x0, float baseY, float pw, float ph,
                     int cnt, float t, float beat, float jogValue, int pal) {
    float3 col  = float3(0.0);
    float  slot = pw / float(cnt);
    float  bw   = slot * 0.72;
    for (int i = 0; i < cnt; i++) {
        float fi  = float(i);
        float cx  = x0 + (fi + 0.5) * slot;
        // Simulate frequency envelope with multiple harmonics + jog offset
        float freq = (fi + 0.5) / float(cnt);
        float env  = exp(-abs(freq - 0.3) * 4.0) + exp(-abs(freq - 0.7) * 6.0) * 0.6;
        float noise = h1(fi * 5.3 + floor(t * 1.2 + jogValue * 3.0));
        float bh   = ph * clamp(env * (0.3 + noise * 0.7) * (1.0 + beat * 0.5), 0.0, 1.0);
        // Color: orange peak, green body
        float3 topC  = recolor(sOrange(), fi * 0.08 + 0.0, pal);
        float3 bodyC = recolor(sGreen(),  fi * 0.08 + 0.3, pal);
        float3 c     = mix(bodyC, topC, smoothstep(bh * 0.7, bh, bh));
        col += c * fillRect(uv, cx-bw*0.5, baseY-bh, cx+bw*0.5, baseY);
        // Peak hold line
        float peakH = ph * clamp(env * 0.9, 0.0, 1.0);
        col += recolor(sWhite(), fi * 0.05, pal)
             * fillRect(uv, cx-bw*0.5, baseY-peakH-0.005, cx+bw*0.5, baseY-peakH);
    }
    return col;
}

// ─── WAVEFORM DECODER ─────────────────────────────────────────────────────────
// Oscilloscope-style signal with AM/FM modulation, jog scrubs phase
float3 draw_decoder(float2 uv, float x0, float y0, float pw, float ph,
                    float t, float beat, float energy, float jogValue, int pal) {
    float3 col = float3(0.0);
    if (uv.x < x0 || uv.x > x0+pw || uv.y < y0 || uv.y > y0+ph) return col;
    float lx   = (uv.x - x0) / pw;
    float ly   = (uv.y - y0) / ph;
    float jPh  = jogValue * 6.2831;
    // Carrier + modulation
    float carrier  = sin(lx * 32.0 + t * 4.1 + jPh);
    float mod      = 0.5 + 0.5 * sin(lx * 5.0 + t * 1.3 + jPh * 0.3);
    float signal   = carrier * mod * (0.35 + energy * 0.15)
                   + sin(lx * 8.0 - t * 2.2 + jPh * 0.5) * 0.10;
    float wave = 0.5 + signal * (1.0 + beat * 0.4);
    float dist = abs(ly - wave);
    float3 wc  = recolor(sCyan(), 0.2, pal);
    float3 ac  = recolor(sAmber(), 0.1, pal);
    col += wc * smoothstep(0.040, 0.0, dist) * 1.8;
    col += ac * smoothstep(0.120, 0.0, dist) * 0.25;
    return col;
}

// ─── TRANSMISSION BURST TILES ─────────────────────────────────────────────────
// Grid of flashing signal blocks, jog shifts which band is active
float3 draw_burst_tiles(float2 uv, float x0, float y0, float x1, float y1,
                        float t, float beat, float jogValue, int pal) {
    float3 col = float3(0.0);
    if (uv.x < x0 || uv.x > x1 || uv.y < y0 || uv.y > y1) return col;
    float cw = (x1-x0) / 12.0, ch = (y1-y0) / 4.0;
    float2 cell = floor((uv - float2(x0,y0)) / float2(cw,ch));
    float  seed = h2(cell + float2(floor(t * 1.8 + jogValue * 4.0), 0.0));
    float  on   = step(0.42, seed);
    // Morse-code-like: short or long blocks
    float3 c;
    int ci = int(seed * 5.9) % 3;
    if      (ci == 0) c = recolor(sOrange(), seed * 0.4,       pal);
    else if (ci == 1) c = recolor(sGreen(),  seed * 0.4 + 0.3, pal);
    else              c = recolor(sWhite(),   seed * 0.4 + 0.6, pal);
    return c * on * (0.7 + beat * 0.3);
}

// ─── ANTENNA SCHEMATIC ───────────────────────────────────────────────────────
// Stylized parabolic dish + mast line diagram
float3 draw_antenna(float2 uv, float cx, float cy, float scale,
                    float t, float beat, int pal) {
    float3 col = float3(0.0);
    float3 wc  = recolor(sWhite(), 0.0, pal);
    float3 oc  = recolor(sOrange(), 0.1, pal);
    float  th  = 0.003;

    // Mast (vertical)
    col += wc * vLine(uv, cx, cy - scale*0.40, cy + scale*0.05, th);

    // Dish arms (3 angled lines from mast top)
    float2 mast_top = float2(cx, cy - scale*0.40);
    float angles[3] = { -0.6, 0.0, 0.6 };
    for (int i = 0; i < 3; i++) {
        float a   = angles[i];
        float len = scale * (0.18 + float(i) * 0.04);
        float2 tip = mast_top + float2(sin(a) * len, -cos(a) * len * 0.5);
        // Approximate line as thin rect between mast_top and tip
        float2 mid = (mast_top + tip) * 0.5;
        float2 dir = normalize(tip - mast_top);
        float  len2 = length(tip - mast_top);
        float2 perp = float2(-dir.y, dir.x);
        float2 p    = uv - mid;
        float  proj = dot(p, dir);
        float  side = dot(p, perp);
        float  mask = step(-len2*0.5, proj) * step(proj, len2*0.5)
                    * step(-th, side) * step(side, th);
        col += wc * mask;
    }

    // Base crossbar
    col += wc * hLine(uv, cy + scale*0.05, cx - scale*0.10, cx + scale*0.10, th);

    // Signal rings emanating from top — pulse on beat
    for (int i = 1; i <= 3; i++) {
        float fi   = float(i);
        float rr   = scale * fi * 0.07 * (1.0 + beat * 0.15);
        float fade = (1.0 - fi * 0.25) * (0.5 + beat * 0.5);
        col += recolor(sOrange(), fi * 0.1, pal) * ringCircle(uv, mast_top, rr, 0.003) * fade;
    }

    return col;
}

// ─── BEARING READOUT (azimuth arc + tick marks) ───────────────────────────────
// jogValue directly controls the pointer position
float3 draw_bearing(float2 uv, float2 ctr, float r,
                    float t, float beat, float jogValue, int pal) {
    float3 col = float3(0.0);
    float3 wc  = recolor(sWhite(), 0.0, pal);
    float3 oc  = recolor(sOrange(), 0.1, pal);
    float3 gc  = recolor(sGreen(), 0.3, pal);

    // Outer arc (270-degree arc — open at bottom)
    float2 d = uv - ctr;
    float dist = length(d);
    float angle = atan2(d.y, d.x);
    float normAngle = fract(angle / 6.2831 + 1.0);
    float inArc = step(dist, r) * step(r - 0.006, dist) * step(normAngle, 0.875);
    col += wc * inArc;

    // Tick marks every 30 degrees
    for (int i = 0; i < 12; i++) {
        float tickAngle = float(i) * 0.5236; // 30 deg in radians
        float2 inner   = ctr + float2(cos(tickAngle), sin(tickAngle)) * (r - 0.020);
        float2 outer2  = ctr + float2(cos(tickAngle), sin(tickAngle)) * r;
        float2 mid     = (inner + outer2) * 0.5;
        float isMain   = step(fract(float(i) / 3.0), 0.01);
        col += wc * fillCircle(uv, mid, 0.005 + isMain * 0.003);
    }

    // Pointer — jog directly controls bearing angle
    float pAngle  = jogValue * 6.2831 - 1.5708; // jog full sweep
    float2 pTip   = ctr + float2(cos(pAngle), sin(pAngle)) * r * 0.82;
    float2 pMid   = (pTip + ctr) * 0.5;
    col += oc * fillCircle(uv, pMid, 0.010 + beat * 0.006);
    col += oc * fillCircle(uv, pTip, 0.008);
    col += oc * fillCircle(uv, ctr,  0.013 * (1.0 + beat * 0.2));
    col += wc * ringCircle(uv, ctr, 0.017, 0.003);

    return col;
}

// ─── SCROLLING DATA LINES ─────────────────────────────────────────────────────
// Simulated text/hex dump lines scrolling upward, jog offsets scroll
float3 draw_data_scroll(float2 uv, float x0, float y0, float pw, float ph,
                        float t, float jogValue, int pal) {
    float3 col = float3(0.0);
    if (uv.x < x0 || uv.x > x0+pw || uv.y < y0 || uv.y > y0+ph) return col;
    float  lineH = ph / 10.0;
    float  scroll = fract(t * 0.3 + jogValue * 0.5);
    float  ly     = fract((uv.y - y0) / ph + scroll) * 10.0;
    float  row    = floor(ly);
    float  rowF   = fract(ly);
    // Each row is a series of word-width blocks
    float3 c = recolor(sGreen(), row * 0.07 + 0.3, pal);
    float  seed = h1(row * 13.7 + floor(t * 0.5));
    float  xCurs = 0.0;
    for (int w = 0; w < 8; w++) {
        float ww = 0.04 + h1(row * 3.1 + float(w)) * 0.10;
        float gap = 0.012;
        float inX = step(x0 + xCurs, uv.x) * step(uv.x, x0 + xCurs + ww)
                  * step(0.10, rowF) * step(rowF, 0.80);
        col += c * inX * 0.85;
        xCurs += ww + gap;
        if (xCurs > pw) break;
    }
    return col;
}

// ─────────────────────────────────────────────────────────────────────────────
fragment float4 signal_intercept(
    VertexOut in [[stage_in]],
    constant GeneratorUniforms &u [[buffer(0)]]
) {
    float2 uv    = in.uv;
    float  t     = u.time * u.speed;
    float  beat  = u.beatStrength * u.reactivity;
    float  energy= u.energy;
    int    pal   = u.colorPalette;
    float  jog   = u.jogValue;

    float3 col = float3(0.0);  // pure black base

    float3 wc  = recolor(sWhite(),  0.0, pal);
    float3 oc  = recolor(sOrange(), 0.1, pal);
    float3 gc  = recolor(sGreen(),  0.3, pal);
    float3 rc  = recolor(sRed(),    0.0, pal);
    float3 ac  = recolor(sAmber(),  0.15, pal);
    float  th  = 0.003;

    // ══════════════════════════════════════════════════════════════════════
    //  TOP-LEFT: MAIN RADAR SCOPE
    // ══════════════════════════════════════════════════════════════════════
    {
        float2 ctr = float2(0.195, 0.720);
        float  r   = 0.175;
        col += draw_radar(uv, ctr, r, t, beat, jog, pal);
        // Radar label strip at top
        col += wc * fillRect(uv, ctr.x-r-0.005, ctr.y+r+0.008,
                             ctr.x+r+0.005, ctr.y+r+0.018);
        col += oc * fillRect(uv, ctr.x-r+0.020, ctr.y+r+0.010,
                             ctr.x-r+0.090, ctr.y+r+0.016);
    }

    // ══════════════════════════════════════════════════════════════════════
    //  TOP-RIGHT: FREQUENCY SPECTRUM ANALYZER
    // ══════════════════════════════════════════════════════════════════════
    {
        float px = 0.415, py = 0.760, pw = 0.570, ph = 0.200;
        col += wc * bracketCorners(uv, px, py, px+pw, py+ph, 0.022, th);
        col += draw_spectrum(uv, px+0.010, py+ph-0.008, pw-0.020, ph-0.025,
                             int(8.0 + u.complexity * 24.0), t, beat, jog, pal);
        // FREQ label
        col += oc * fillRect(uv, px+0.010, py+ph-0.022, px+0.080, py+ph-0.014);
    }

    // ══════════════════════════════════════════════════════════════════════
    //  MID-LEFT: SECONDARY RADAR (smaller, bearing gauge)
    // ══════════════════════════════════════════════════════════════════════
    {
        float2 ctr = float2(0.100, 0.395);
        float  r   = 0.085;
        col += draw_radar(uv, ctr, r, t * 1.7, beat, jog * 0.5, pal);
    }

    // ══════════════════════════════════════════════════════════════════════
    //  MID-CENTER: WAVEFORM DECODER
    // ══════════════════════════════════════════════════════════════════════
    {
        float px = 0.210, py = 0.480, pw = 0.380, ph = 0.095;
        col += wc * borderRect(uv, px, py, px+pw, py+ph, th);
        col += draw_decoder(uv, px+0.004, py+0.006, pw-0.008, ph-0.012,
                            t, beat, energy, jog, pal);
        // SIGNAL label top-right
        col += gc * fillRect(uv, px+pw-0.090, py+ph-0.022,
                             px+pw-0.010, py+ph-0.014);
    }

    // ══════════════════════════════════════════════════════════════════════
    //  MID-CENTER lower: second waveform (different frequency)
    // ══════════════════════════════════════════════════════════════════════
    {
        float px = 0.210, py = 0.368, pw = 0.380, ph = 0.095;
        col += wc * borderRect(uv, px, py, px+pw, py+ph, th);
        col += draw_decoder(uv, px+0.004, py+0.006, pw-0.008, ph-0.012,
                            t * 1.4, beat, energy, jog * 0.7, pal);
    }

    // ══════════════════════════════════════════════════════════════════════
    //  MID-RIGHT: BEARING READOUT GAUGE
    // ══════════════════════════════════════════════════════════════════════
    {
        float2 ctr = float2(0.870, 0.490);
        float  r   = 0.082;
        col += draw_bearing(uv, ctr, r, t, beat, jog, pal);
        // AZ / EL labels
        col += wc * fillRect(uv, ctr.x-0.040, ctr.y+r+0.012,
                             ctr.x+0.040, ctr.y+r+0.020);
    }

    // ══════════════════════════════════════════════════════════════════════
    //  UPPER-RIGHT: TRANSMISSION BURST TILES
    // ══════════════════════════════════════════════════════════════════════
    {
        float px = 0.415, py = 0.575, pw = 0.570, ph = 0.162;
        col += wc * bracketCorners(uv, px, py, px+pw, py+ph, 0.018, th);
        col += draw_burst_tiles(uv, px+0.006, py+0.006,
                               px+pw-0.006, py+ph-0.006, t, beat, jog, pal);
        // XMIT label
        col += oc * fillRect(uv, px+0.010, py+0.006, px+0.060, py+0.014);
    }

    // ══════════════════════════════════════════════════════════════════════
    //  LEFT-MID: ANTENNA SCHEMATIC
    // ══════════════════════════════════════════════════════════════════════
    {
        col += draw_antenna(uv, 0.100, 0.590, 0.130, t, beat, pal);
    }

    // ══════════════════════════════════════════════════════════════════════
    //  LOWER-LEFT: SCROLLING DATA DUMP
    // ══════════════════════════════════════════════════════════════════════
    {
        float px = 0.010, py = 0.030, pw = 0.195, ph = 0.310;
        col += wc * borderRect(uv, px, py, px+pw, py+ph, th);
        col += draw_data_scroll(uv, px+0.006, py+0.006, pw-0.012, ph-0.012,
                               t, jog, pal);
        // DATA label
        col += gc * fillRect(uv, px+0.008, py+ph-0.020, px+0.055, py+ph-0.012);
    }

    // ══════════════════════════════════════════════════════════════════════
    //  LOWER-CENTER: STATUS BARS (signal strength per channel)
    // ══════════════════════════════════════════════════════════════════════
    {
        float px = 0.210, py = 0.030, pw = 0.200, ph = 0.310;
        col += wc * borderRect(uv, px, py, px+pw, py+ph, th);
        float bh = 0.022, gap = 0.032;
        for (int i = 0; i < 8; i++) {
            float fi   = float(i);
            float by   = py + 0.018 + fi * gap;
            float fill = clamp(0.1 + h1(fi*5.3 + floor(t*0.5 + jog*2.0))*0.9, 0.0, 1.0);
            float3 c   = (fill > 0.75) ? rc : (fill > 0.45 ? oc : gc);
            c          = recolor(c, fi * 0.11, pal);
            col       += c * 0.10 * fillRect(uv, px+0.010, by, px+pw-0.010, by+bh);
            col       += c        * fillRect(uv, px+0.010, by, px+0.010+(pw-0.020)*fill, by+bh);
            // Channel label dot
            col += wc * fillCircle(uv, float2(px+pw-0.015, by+bh*0.5), 0.005);
        }
    }

    // ══════════════════════════════════════════════════════════════════════
    //  LOWER-RIGHT: CROSSHAIR TARGETING RETICLE
    // ══════════════════════════════════════════════════════════════════════
    {
        float2 ctr = float2(0.820, 0.165);
        float  r   = 0.130;
        float3 lc  = recolor(sGreen(), 0.3, pal);
        float3 oc2 = recolor(sOrange(), 0.1, pal);

        // Outer square bracket frame
        col += lc * bracketCorners(uv, ctr.x-r, ctr.y-r*0.75,
                                   ctr.x+r, ctr.y+r*0.75, 0.025, th);
        // Inner crosshair rings
        col += lc * ringCircle(uv, ctr, r * 0.55, 0.004);
        col += lc * ringCircle(uv, ctr, r * 0.28, 0.003);
        // Cross lines
        col += lc * hLine(uv, ctr.y, ctr.x - r*0.9, ctr.x - r*0.30, th);
        col += lc * hLine(uv, ctr.y, ctr.x + r*0.30, ctr.x + r*0.9, th);
        col += lc * vLine(uv, ctr.x, ctr.y - r*0.65, ctr.y - r*0.22, th);
        col += lc * vLine(uv, ctr.x, ctr.y + r*0.22, ctr.y + r*0.65, th);
        // Center dot — pulses on beat
        col += oc2 * fillCircle(uv, ctr, 0.012 * (1.0 + beat * 0.4));
        col += lc  * ringCircle(uv, ctr, 0.018, 0.003);
        // Corner tick numerals (small blocks)
        col += wc * fillRect(uv, ctr.x+r*0.60, ctr.y-r*0.72,
                             ctr.x+r*0.90, ctr.y-r*0.62);
    }

    // ══════════════════════════════════════════════════════════════════════
    //  RIGHT STRIP: vertical signal-strength meter + lock indicator
    // ══════════════════════════════════════════════════════════════════════
    {
        float px = 0.620, py = 0.030, pw = 0.070, ph = 0.310;
        col += wc * borderRect(uv, px, py, px+pw, py+ph, th);
        // 12-segment VU-style vertical meter
        int segs = 12;
        for (int i = 0; i < segs; i++) {
            float fi    = float(i) / float(segs);
            float by    = py + 0.010 + float(i) * (ph - 0.020) / float(segs);
            float level = clamp(0.3 + energy * 0.7 + beat * 0.3, 0.0, 1.0);
            float lit   = step(fi, level);
            float3 sc   = (fi > 0.75) ? rc : (fi > 0.5 ? oc : gc);
            sc          = recolor(sc, fi * 0.25, pal);
            col        += sc * lit * fillRect(uv, px+0.008, by, px+pw-0.008, by+0.018);
            col        += sc * 0.08 * (1.0-lit) * fillRect(uv, px+0.008, by, px+pw-0.008, by+0.018);
        }
        // LOCK indicator (flashes on strong beat)
        float lockOn = step(0.7, beat) * step(0.5, h1(floor(t * 2.0)));
        float3 lockC = mix(wc, oc, lockOn);
        col += lockC * fillRect(uv, px+0.010, py+0.010, px+pw-0.010, py+0.030);
    }

    // ══════════════════════════════════════════════════════════════════════
    //  GLOBAL FX
    // ══════════════════════════════════════════════════════════════════════

    // Horizontal scan sweep
    {
        float scanY = fract(t * 0.16 + jog * 0.4);
        float beam  = exp(-abs(uv.y - scanY) * 65.0) * (0.04 + beat * 0.09);
        col += gc * beam;
    }

    // Beat flash
    {
        float flash = max(0.0, beat - 0.80) * 4.0 * step(u.beatPhase, 0.06);
        col = mix(col, wc, flash * 0.18);
    }

    // Chromatic aberration on beat
    {
        float ca = 0.0015 + beat * 0.007;
        col.r += ca * sin(uv.y * 85.0 + t * 3.0) * beat * 0.5;
        col.b -= ca * sin(uv.y * 85.0 - t * 2.2) * beat * 0.5;
    }

    // Fine CRT scanlines
    col *= 0.90 + 0.10 * sin(uv.y * u.resolution.y * 1.57);

    // Film grain
    col += (h2(uv + fract(t * 10.1)) - 0.5) * 0.018;

    col = clamp(col * (0.82 + energy * 0.38), 0.0, 1.0);
    return float4(col, 1.0);
}
