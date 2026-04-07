// tech_diag_hud.metal — Technical Diagnostic / System Readout HUD
//
// Aesthetic: Pure black with bold yellow, electric blue, grey, red/green
// fill blocks and crisp white lines. Schematic/circuit art: human silhouette
// with overlaid measurement points, circuit-tree node graphs, radial angle
// gauges, bar charts, "HND / OFFL" large text blocks, and data tables.
// Dense with information, no gradients — flat fills and sharp borders only.
// Directly inspired by technical diagnostic art (image 2).
//
// colorPalette = 0  →  native colors (yellow/blue/white on black)
// colorPalette 1-32 →  full VKO1 cosine palette recoloring
//
// Uniforms used:
//   time         → animation, blinking, node pulsing
//   beatPhase    → blink and snap timing
//   beatStrength → circuit-node pulse, flash  ← PRIMARY BEAT DRIVER
//   energy       → overall brightness
//   reactivity   → beat coupling
//   complexity   → graph node density, bar count
//   speed        → animation speed
//   colorPalette → 0 = native, 1-32 = cosine palette recolor
//   jogValue     → manual horizontal scan

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

// ─── Recolor helper ───────────────────────────────────────────────────────────
float3 recolor(float3 native_col, float hue_seed, int pal) {
    if (pal == 0) return native_col;
    float lum = dot(native_col, float3(0.299, 0.587, 0.114));
    return get_palette_color(hue_seed + lum * 0.35, pal) * (0.15 + lum * 1.5);
}

// ─── Hash utilities ───────────────────────────────────────────────────────────
float h1(float  n) { return fract(sin(n) * 43758.5453); }
float h2(float2 p) { return fract(sin(dot(p, float2(127.1, 311.7))) * 43758.5453); }

// ─── Native diagnostic palette (image 2 exact hues) ──────────────────────────
float3 dYellow() { return float3(1.00, 0.95, 0.00); }  // bright yellow
float3 dBlue()   { return float3(0.05, 0.30, 1.00); }  // electric blue
float3 dWhite()  { return float3(1.00, 1.00, 1.00); }  // white
float3 dGrey()   { return float3(0.55, 0.55, 0.55); }  // mid grey
float3 dRed()    { return float3(0.90, 0.05, 0.05); }  // red fill block
float3 dGreen()  { return float3(0.05, 0.80, 0.05); }  // green fill block

// ─── Shape primitives ─────────────────────────────────────────────────────────
float fillRect(float2 uv, float x0, float y0, float x1, float y1) {
    return step(x0, uv.x)*step(uv.x, x1)*step(y0, uv.y)*step(uv.y, y1);
}
float borderRect(float2 uv, float x0, float y0, float x1, float y1, float th) {
    return fillRect(uv,x0,y0,x1,y1) - fillRect(uv,x0+th,y0+th,x1-th,y1-th);
}
float fillCircle(float2 uv, float2 ctr, float r) {
    return step(length(uv - ctr), r);
}
float ringCircle(float2 uv, float2 ctr, float r, float th) {
    float d = length(uv - ctr);
    return step(r-th, d)*step(d, r);
}
float bracketCorners(float2 uv, float x0, float y0, float x1, float y1,
                     float arm, float th) {
    float m = 0.0;
    m += fillRect(uv,x0,y0,x0+arm,y0+th);
    m += fillRect(uv,x0,y0,x0+th,y0+arm);
    m += fillRect(uv,x1-arm,y0,x1,y0+th);
    m += fillRect(uv,x1-th,y0,x1,y0+arm);
    m += fillRect(uv,x0,y1-th,x0+arm,y1);
    m += fillRect(uv,x0,y1-arm,x0+th,y1);
    m += fillRect(uv,x1-arm,y1-th,x1,y1);
    m += fillRect(uv,x1-th,y1-arm,x1,y1);
    return clamp(m, 0.0, 1.0);
}

// ─── Thin line (horizontal) ───────────────────────────────────────────────────
float hLine(float2 uv, float y, float x0, float x1, float th) {
    return fillRect(uv, x0, y-th*0.5, x1, y+th*0.5);
}

// ─── Thin line (vertical) ─────────────────────────────────────────────────────
float vLine(float2 uv, float x, float y0, float y1, float th) {
    return fillRect(uv, x-th*0.5, y0, x+th*0.5, y1);
}

// ─── Circle node with ring ────────────────────────────────────────────────────
float3 circleNode(float2 uv, float2 ctr, float r, float beat, float3 inner_c,
                  float3 ring_c) {
    float3 col = float3(0.0);
    float pulse = 1.0 + beat * 0.12;
    col += inner_c * fillCircle(uv, ctr, r * pulse);
    col += ring_c  * ringCircle(uv, ctr, r * pulse + 0.007, 0.004);
    return col;
}

// ─── Node-graph tree (branch lines + circle nodes) ───────────────────────────
// jogValue → rotates the entire tree layout, like manually turning the circuit diagram
float3 draw_node_tree(float2 uv, float cx, float cy, float scale,
                      float t, float beat, float jogValue, float3 line_c, float3 node_c,
                      float3 root_c, int pal) {
    float3 col = float3(0.0);
    float th  = 0.003;
    float nr  = 0.018 * (1.0 + beat * 0.15);
    float jRot = jogValue * 1.5708; // quarter-turn per full jog sweep
    float cosJ = cos(jRot), sinJ = sin(jRot);

    // Root node
    col += recolor(root_c, 0.0, pal) * fillCircle(uv, float2(cx, cy), nr*1.4);
    col += recolor(line_c, 0.1, pal) * ringCircle(uv, float2(cx, cy), nr*1.4+0.007, 0.003);

    // Left branch — rotate offsets by jog angle
    float2 lRaw  = float2(-scale*0.14, 0.0);
    float2 l2Raw = float2(-scale*0.14, -scale*0.12);
    float2 llRaw = float2(-scale*0.14, -scale*0.21);
    float2 lPos  = float2(cx + lRaw.x*cosJ  - lRaw.y*sinJ,  cy + lRaw.x*sinJ  + lRaw.y*cosJ);
    float2 lPos2 = float2(cx + l2Raw.x*cosJ - l2Raw.y*sinJ, cy + l2Raw.x*sinJ + l2Raw.y*cosJ);
    float2 llPos = float2(cx + llRaw.x*cosJ - llRaw.y*sinJ, cy + llRaw.x*sinJ + llRaw.y*cosJ);
    col += recolor(line_c, 0.1, pal) * hLine(uv, lPos.y, lPos.x, cx, th);
    col += recolor(line_c, 0.1, pal) * vLine(uv, lPos.x, lPos.y, lPos2.y, th);
    col += recolor(node_c, 0.05, pal) * fillCircle(uv, lPos2, nr);
    col += recolor(line_c, 0.1, pal) * ringCircle(uv, lPos2, nr+0.006, 0.003);
    col += recolor(line_c, 0.1, pal) * vLine(uv, lPos2.x, lPos2.y, llPos.y, th);
    col += recolor(node_c, 0.05, pal) * fillCircle(uv, llPos, nr*0.85);

    // Right branch
    float2 rRaw  = float2(scale*0.14, 0.0);
    float2 r2Raw = float2(scale*0.14, -scale*0.12);
    float2 rlRaw = float2(scale*0.07, -scale*0.20);
    float2 rrRaw = float2(scale*0.21, -scale*0.20);
    float2 rPos  = float2(cx + rRaw.x*cosJ  - rRaw.y*sinJ,  cy + rRaw.x*sinJ  + rRaw.y*cosJ);
    float2 rPos2 = float2(cx + r2Raw.x*cosJ - r2Raw.y*sinJ, cy + r2Raw.x*sinJ + r2Raw.y*cosJ);
    float2 rlPos = float2(cx + rlRaw.x*cosJ - rlRaw.y*sinJ, cy + rlRaw.x*sinJ + rlRaw.y*cosJ);
    float2 rrPos = float2(cx + rrRaw.x*cosJ - rrRaw.y*sinJ, cy + rrRaw.x*sinJ + rrRaw.y*cosJ);
    col += recolor(line_c, 0.1, pal) * hLine(uv, rPos.y, cx, rPos.x, th);
    col += recolor(line_c, 0.1, pal) * vLine(uv, rPos.x, rPos.y, rPos2.y, th);
    col += recolor(node_c, 0.05, pal) * fillCircle(uv, rPos2, nr);
    col += recolor(line_c, 0.1, pal) * ringCircle(uv, rPos2, nr+0.006, 0.003);
    col += recolor(line_c, 0.1, pal) * hLine(uv, rPos2.y, rPos2.x, rlPos.x, th);
    col += recolor(line_c, 0.1, pal) * vLine(uv, rlPos.x, rPos2.y, rlPos.y, th);
    col += recolor(node_c, 0.05, pal) * fillCircle(uv, rlPos, nr*0.8);
    col += recolor(line_c, 0.1, pal) * hLine(uv, rPos2.y, rPos2.x, rrPos.x, th);
    col += recolor(line_c, 0.1, pal) * vLine(uv, rrPos.x, rPos2.y, rrPos.y, th);
    col += recolor(node_c, 0.05, pal) * fillCircle(uv, rrPos, nr*0.8);

    return col;
}

// ─── Horizontal bar chart ─────────────────────────────────────────────────────
// jogValue → scrubs the fill amount seed, wheel manually drives bar lengths
float3 draw_h_bar_chart(float2 uv, float x0, float y0, float pw, float bh,
                        int cnt, float t, float beat, float jogValue, int pal) {
    float3 col = float3(0.0);
    float gap  = bh * 2.1;
    for (int i = 0; i < cnt; i++) {
        float fi   = float(i);
        float by   = y0 + fi * gap;
        float fill = clamp(0.15 + h1(fi*5.3 + floor(t*0.35 + jogValue*2.0))*0.85, 0.0, 1.0);
        float3 c;
        if (i % 3 == 0)      c = recolor(dYellow(), fi*0.11,     pal);
        else if (i % 3 == 1) c = recolor(dBlue(),   fi*0.11+0.2, pal);
        else                  c = recolor(dGrey(),   fi*0.11+0.4, pal);
        col += c * 0.08 * fillRect(uv, x0, by, x0+pw, by+bh);
        col += c * fillRect(uv, x0, by, x0+pw*fill, by+bh);
    }
    return col;
}

// ─── Oval / ellipse body (human silhouette approximation) ─────────────────────
float ellipseRing(float2 uv, float2 ctr, float rx, float ry, float th) {
    float2 d  = (uv - ctr) / float2(rx, ry);
    float  ld = length(d);
    float  scale_th = th / min(rx, ry);
    return step(1.0-scale_th, ld)*step(ld, 1.0);
}

// ─── Human figure (left panel schematic) ─────────────────────────────────────
// jogValue → shifts the measurement cross phase, like scanning through calibration points
float3 draw_figure(float2 uv, float cx, float cy, float scale,
                   float t, float beat, float jogValue, int pal) {
    float3 col    = float3(0.0);
    float3 lc     = recolor(dWhite(), 0.0, pal);  // outline color
    float3 yc     = recolor(dYellow(), 0.0, pal); // measurement point
    float  th     = 0.003;
    float  pulse  = 1.0 + beat * 0.08;

    // Head (oval)
    float2 headCtr = float2(cx, cy + scale*0.38);
    col += lc * ellipseRing(uv, headCtr, scale*0.075, scale*0.092, 0.006);
    // Head measurement cross
    col += yc * hLine(uv, headCtr.y, headCtr.x-scale*0.04, headCtr.x+scale*0.04, th);
    col += yc * vLine(uv, headCtr.x, headCtr.y-scale*0.05, headCtr.y+scale*0.05, th);

    // Face red rect
    float3 rc = recolor(dRed(), 0.0, pal);
    col += rc * fillRect(uv, cx-scale*0.055, cy+scale*0.30, cx+scale*0.055, cy+scale*0.37);

    // Shoulder line
    col += lc * hLine(uv, cy+scale*0.27, cx-scale*0.14, cx+scale*0.14, th);
    col += lc * vLine(uv, cx-scale*0.14, cy+scale*0.10, cy+scale*0.27, th);
    col += lc * vLine(uv, cx+scale*0.14, cy+scale*0.10, cy+scale*0.27, th);

    // Torso
    col += lc * borderRect(uv, cx-scale*0.12, cy+scale*0.05, cx+scale*0.12, cy+scale*0.27, th);

    // Waist / hip
    col += lc * hLine(uv, cy, cx-scale*0.10, cx+scale*0.10, th);

    // Legs
    col += lc * vLine(uv, cx-scale*0.06, cy-scale*0.35, cy, th);
    col += lc * vLine(uv, cx+scale*0.06, cy-scale*0.35, cy, th);
    col += lc * hLine(uv, cy-scale*0.35, cx-scale*0.10, cx-scale*0.06, th);
    col += lc * hLine(uv, cy-scale*0.35, cx+scale*0.06, cx+scale*0.10, th);

    // Measurement dots (yellow circles on joints)
    // jogValue selects which joint is the active scan target (enlarged + bright)
    float2 joints[5] = {
        float2(cx, cy+scale*0.27),
        float2(cx-scale*0.14, cy+scale*0.27),
        float2(cx+scale*0.14, cy+scale*0.27),
        float2(cx, cy),
        float2(cx, cy+scale*0.18)
    };
    float activeJoint = fract(jogValue * 0.5 + 0.001) * 5.0; // jog cycles through joints
    for (int i = 0; i < 5; i++) {
        float isActive = smoothstep(1.0, 0.0, abs(float(i) - activeJoint));
        float r = 0.010 * pulse * (1.0 + isActive * 0.8);
        col += mix(yc, recolor(dWhite(), 0.0, pal), isActive) * fillCircle(uv, joints[i], r);
        col += lc * ringCircle(uv, joints[i], r + 0.003, 0.003);
    }

    return col;
}

// ─── Radial angle gauge (0/90/180/270 marks) ─────────────────────────────────
float3 draw_angle_gauge(float2 uv, float2 ctr, float r, float t,
                        float beat, float jogValue, int pal) {
    float3 col = float3(0.0);
    float3 yc  = recolor(dYellow(), 0.0, pal);
    float3 wc  = recolor(dWhite(), 0.0, pal);
    float  th  = 0.003;

    // Outer ring
    col += wc * ringCircle(uv, ctr, r, 0.004);

    // Tick marks at 0/90/180/270
    for (int i = 0; i < 4; i++) {
        float angle = float(i) * 1.5708; // pi/2 increments
        float2 tickOuter = ctr + float2(cos(angle), sin(angle)) * r;
        float2 tickInner = ctr + float2(cos(angle), sin(angle)) * (r - 0.030);
        // Approximate thin line as stretched circle
        float2 midPt = (tickOuter + tickInner) * 0.5;
        col += wc * fillCircle(uv, midPt, 0.007);
    }

    // Rotating needle — animated and beat-reactive
    float needleAngle = t * 0.4 + jogValue * 3.14;
    float2 needleTip = ctr + float2(cos(needleAngle), sin(needleAngle)) * r * 0.85;
    col += yc * fillCircle(uv, (needleTip + ctr) * 0.5, 0.009 + beat * 0.006);

    // Static pointer line (d.1 / d.2 visual)
    float2 p1 = ctr + float2(cos(0.0), sin(0.0)) * r * 0.8;
    float2 p2 = ctr + float2(cos(0.52), sin(0.52)) * r * 0.8;
    col += yc * fillCircle(uv, (p1 + ctr)*0.5, 0.007);
    col += yc * fillCircle(uv, (p2 + ctr)*0.5, 0.007);

    // Center dot
    col += yc * fillCircle(uv, ctr, 0.012 * (1.0 + beat * 0.2));

    return col;
}

// ─── Diamond / rhombus grid (circuit art center-bottom) ───────────────────────
// jogValue → rotates each diamond around its own center
float3 draw_diamond_grid(float2 uv, float2 ctr, float scale,
                         float t, float beat, float jogValue, int pal) {
    float3 col = float3(0.0);
    float3 yc  = recolor(dYellow(), 0.0, pal);
    float3 bc  = recolor(dBlue(), 0.2, pal);
    float3 wc  = recolor(dWhite(), 0.0, pal);
    // jog rotates all diamonds — 45-degree turn = full square, so pi/4 range feels right
    float jAngle = jogValue * 0.7854 + 0.7854; // default 45deg + jog offset
    float cosA = cos(jAngle), sinA = sin(jAngle);

    for (int row = 0; row < 3; row++) {
        for (int col_i = 0; col_i < 3; col_i++) {
            float2 dc = ctr + float2((float(col_i)-1.0)*scale*0.14,
                                     (float(row)-1.0)*scale*0.12);
            float2 dp  = uv - dc;
            // Rotate dp by jAngle before taking Chebyshev distance
            float2 rot = float2(dp.x*cosA - dp.y*sinA, dp.x*sinA + dp.y*cosA);
            float dDist = max(abs(rot.x), abs(rot.y));
            float outerR = scale * 0.055;
            float innerR = outerR - scale * 0.010;
            float isCenter = step(abs(float(row)-1.0), 0.1) * step(abs(float(col_i)-1.0), 0.1);
            float3 fillC = mix(yc, bc, float(col_i) / 2.0);
            if (isCenter > 0.5) fillC = wc;
            col += fillC * (step(dDist, outerR) - step(dDist, innerR));
            if (isCenter > 0.5)
                col += wc * step(dDist, outerR * 0.3) * (1.0 + beat * 0.3);
        }
    }
    return col;
}

// ─────────────────────────────────────────────────────────────────────────────
fragment float4 tech_diag_hud(
    VertexOut in [[stage_in]],
    constant GeneratorUniforms &u [[buffer(0)]]
) {
    float2 uv    = in.uv;
    float  t     = u.time * u.speed;
    float  beat  = u.beatStrength * u.reactivity;
    float  energy= u.energy;
    int    pal   = u.colorPalette;
    float  th    = 0.003; // default line thickness

    float3 col = float3(0.0);

    // ── Convenience color aliases ─────────────────────────────────────────
    float3 yc  = recolor(dYellow(), 0.0, pal);
    float3 bc  = recolor(dBlue(),   0.2, pal);
    float3 wc  = recolor(dWhite(),  0.0, pal);
    float3 rc  = recolor(dRed(),    0.0, pal);
    float3 gnc = recolor(dGreen(),  0.5, pal);

    // ══════════════════════════════════════════════════════════════════════
    //  TOP-LEFT: oval brain/circuit schematic with ring nodes
    // ══════════════════════════════════════════════════════════════════════
    {
        float2 ctr = float2(0.135, 0.810);
        float rx = 0.120, ry = 0.088;
        // Main oval outline
        col += yc * ellipseRing(uv, ctr, rx, ry, 0.008);
        // Inner oval
        col += yc * ellipseRing(uv, ctr, rx*0.62, ry*0.62, 0.005);
        // Horizontal grid lines inside oval
        for (int i = 0; i < 4; i++) {
            float gy = ctr.y - ry*0.55 + float(i)*(ry*1.1/3.0);
            float halfW = sqrt(max(0.0, 1.0 - pow((gy-ctr.y)/ry, 2.0))) * rx * 0.9;
            col += yc * 0.5 * hLine(uv, gy, ctr.x-halfW, ctr.x+halfW, th*0.7);
        }
        // Circle nodes on oval rim (outer, 6 positions)
        for (int i = 0; i < 6; i++) {
            float angle = float(i) * 1.0472; // 60-degree steps
            float2 nc  = ctr + float2(cos(angle)*rx*1.02, sin(angle)*ry*1.02);
            float3 fillC = (i < 3) ? bc : yc;
            fillC = recolor(fillC, float(i)*0.15, pal);
            col += fillC * fillCircle(uv, nc, 0.016*(1.0+beat*0.12));
            col += wc * ringCircle(uv, nc, 0.020, 0.003);
        }
        // Blue fill circles on inner ring
        float2 innerNodes[3] = {
            float2(ctr.x-rx*0.35, ctr.y+ry*0.25),
            float2(ctr.x,         ctr.y+ry*0.10),
            float2(ctr.x+rx*0.35, ctr.y-ry*0.15)
        };
        for (int i = 0; i < 3; i++) {
            col += bc * fillCircle(uv, innerNodes[i], 0.022*(1.0+beat*0.10));
        }
        // Outer bracket
        col += yc * bracketCorners(uv, ctr.x-rx-0.015, ctr.y-ry-0.018,
                                   ctr.x+rx+0.015, ctr.y+ry+0.018, 0.020, th);
    }

    // ══════════════════════════════════════════════════════════════════════
    //  TOP-CENTER: HND large label + numbered frequency blocks
    // ══════════════════════════════════════════════════════════════════════
    {
        // "HND" — rendered as thick filled rect blocks (bold text simulation)
        float px = 0.300, py = 0.860;
        // H
        col += yc * fillRect(uv, px+0.000, py, px+0.012, py+0.095);
        col += yc * fillRect(uv, px+0.000, py+0.040, px+0.045, py+0.055);
        col += yc * fillRect(uv, px+0.033, py, px+0.045, py+0.095);
        // N
        col += yc * fillRect(uv, px+0.055, py, px+0.067, py+0.095);
        col += yc * fillRect(uv, px+0.055, py+0.060, px+0.095, py+0.095);
        col += yc * fillRect(uv, px+0.083, py, px+0.095, py+0.095);
        // D
        col += yc * fillRect(uv, px+0.105, py, px+0.117, py+0.095);
        col += yc * fillRect(uv, px+0.105, py+0.083, px+0.148, py+0.095);
        col += yc * fillRect(uv, px+0.105, py, px+0.148, py+0.012);
        col += yc * fillRect(uv, px+0.136, py+0.012, px+0.148, py+0.083);

        // Frequency column blocks (1f-5f) — yellow fills of varying height
        float bx = 0.470, by_base = 0.870;
        float heights[5] = { 0.045, 0.095, 0.075, 0.060, 0.035 };
        for (int i = 0; i < 5; i++) {
            float bpx = bx + float(i) * 0.030;
            col += yc * fillRect(uv, bpx, by_base, bpx+0.020, by_base+heights[i]);
            // Blue dot at top of each bar
            float3 dotC = recolor(dBlue(), float(i)*0.13+0.2, pal);
            col += dotC * fillCircle(uv, float2(bpx+0.010, by_base+heights[i]+0.012), 0.010);
        }
    }

    // ══════════════════════════════════════════════════════════════════════
    //  TOP-RIGHT: large "08" number + radial angle gauge
    // ══════════════════════════════════════════════════════════════════════
    {
        float px = 0.790, py = 0.860;
        // "0" — border ring
        col += yc * borderRect(uv, px, py, px+0.052, py+0.090, 0.012);
        // "8" — two stacked border rings
        col += yc * borderRect(uv, px+0.060, py, px+0.112, py+0.043, 0.010);
        col += yc * borderRect(uv, px+0.060, py+0.047, px+0.112, py+0.090, 0.010);

        // Radial gauge (right)
        col += draw_angle_gauge(uv, float2(0.930, 0.845), 0.048, t, beat, u.jogValue, pal);
    }

    // ══════════════════════════════════════════════════════════════════════
    //  LEFT-MID: human figure schematic
    // ══════════════════════════════════════════════════════════════════════
    {
        col += draw_figure(uv, 0.110, 0.530, 0.220, t, beat, u.jogValue, pal);
    }

    // ══════════════════════════════════════════════════════════════════════
    //  CENTER-MID: body scan diagram (frontal human + H P labels)
    // ══════════════════════════════════════════════════════════════════════
    {
        float cx = 0.500, cy = 0.640;
        float3 lc = recolor(dBlue(), 0.2, pal);

        // Body outline (simplified - head+torso+legs with blue stroke)
        // Head oval
        col += lc * ellipseRing(uv, float2(cx, cy+0.155), 0.038, 0.052, 0.005);
        // Torso rect
        col += lc * borderRect(uv, cx-0.040, cy-0.020, cx+0.040, cy+0.150, 0.004);
        // Legs
        col += lc * vLine(uv, cx-0.020, cy-0.170, cy-0.020, th);
        col += lc * vLine(uv, cx+0.020, cy-0.170, cy-0.020, th);
        col += lc * hLine(uv, cy-0.170, cx-0.040, cx-0.020, th);
        col += lc * hLine(uv, cy-0.170, cx+0.020, cx+0.040, th);
        // Arms
        col += lc * hLine(uv, cy+0.100, cx-0.085, cx-0.040, th);
        col += lc * hLine(uv, cy+0.100, cx+0.040, cx+0.085, th);

        // Center axis cross (yellow)
        col += yc * vLine(uv, cx, cy-0.015, cy+0.200, th*0.8);
        col += yc * fillCircle(uv, float2(cx, cy+0.080), 0.009 * (1.0+beat*0.15));

        // Measurement nodes
        float2 measPts[4] = {
            float2(cx, cy+0.155),
            float2(cx-0.040, cy+0.100),
            float2(cx+0.040, cy+0.100),
            float2(cx, cy-0.020)
        };
        for (int i = 0; i < 4; i++) {
            col += wc * fillCircle(uv, measPts[i], 0.008 * (1.0+beat*0.1));
            col += lc * ringCircle(uv, measPts[i], 0.012, 0.003);
        }

        // Border frame
        col += wc * bracketCorners(uv, cx-0.110, cy-0.195, cx+0.110, cy+0.220,
                                   0.020, th);
    }

    // ══════════════════════════════════════════════════════════════════════
    //  RIGHT-MID: node-tree graph
    // ══════════════════════════════════════════════════════════════════════
    {
        col += draw_node_tree(uv, 0.840, 0.690, 0.85, t, beat,
                              u.jogValue, yc, yc, wc, pal);
    }

    // ══════════════════════════════════════════════════════════════════════
    //  MID-LEFT: R.RGGG / G.BYY bar charts
    // ══════════════════════════════════════════════════════════════════════
    {
        float px = 0.010, py = 0.460;
        float3 colors3[3] = { rc, gnc, yc };
        for (int i = 0; i < 3; i++) {
            float fi = float(i);
            float by = py + fi * 0.035;
            float fill = clamp(0.2 + h1(fi*4.7+floor(t*0.4))*0.8, 0.0, 1.0);
            float3 c = recolor(colors3[i], fi*0.15, pal);
            col += c * 0.10 * fillRect(uv, px, by, px+0.190, by+0.022);
            col += c * fillRect(uv, px, by, px+0.190*fill, by+0.022);
        }
        // Labels as thin white bars
        for (int i = 0; i < 3; i++) {
            float ly = py + float(i)*0.035 + 0.004;
            col += wc * fillRect(uv, px+0.192, ly, px+0.210, ly+0.010);
        }
    }

    // ══════════════════════════════════════════════════════════════════════
    //  CENTER-LOWER-LEFT: H-node tree (ROOT / R+ / R- / L)
    // ══════════════════════════════════════════════════════════════════════
    {
        float cx = 0.175, cy = 0.285;
        col += draw_node_tree(uv, cx, cy, 0.9, t*0.7, beat, u.jogValue, wc, wc, wc, pal);
        // Additional node labels (small rect blocks)
        float3 lc2 = recolor(dWhite(), 0.0, pal);
        col += lc2 * fillRect(uv, cx-0.085, cy+0.075, cx-0.060, cy+0.088);
        col += lc2 * fillRect(uv, cx+0.065, cy+0.075, cx+0.090, cy+0.088);
    }

    // ══════════════════════════════════════════════════════════════════════
    //  CENTER-MID lower: X.A01–X.A04, Z.A01–Z.A04 bar chart list
    // ══════════════════════════════════════════════════════════════════════
    {
        col += draw_h_bar_chart(uv, 0.050, 0.060, 0.185, 0.018, 8, t, beat, u.jogValue, pal);
        // Left marker squares
        for (int i = 0; i < 8; i++) {
            float fi = float(i);
            float by = 0.060 + fi * 0.040;
            float3 mc2 = (i < 4) ? yc : bc;
            mc2 = recolor(mc2, fi*0.12, pal);
            col += mc2 * fillRect(uv, 0.010, by+0.001, 0.030, by+0.017);
        }
    }

    // ══════════════════════════════════════════════════════════════════════
    //  CENTER lower: diamond/rhombus circuit grid
    // ══════════════════════════════════════════════════════════════════════
    {
        col += draw_diamond_grid(uv, float2(0.500, 0.230), 0.90, t, beat, u.jogValue, pal);
    }

    // ══════════════════════════════════════════════════════════════════════
    //  RIGHT lower: column bar chart + node tree
    // ══════════════════════════════════════════════════════════════════════
    {
        float px = 0.625, py_base = 0.160;
        // Z.A01-Z.A03 style vertical bars
        for (int i = 0; i < 4; i++) {
            float fi  = float(i);
            float bx  = px + fi * 0.040;
            float bh  = 0.080 + h1(fi*6.3+floor(t*0.5))*0.100;
            bh *= 1.0 + beat*h1(fi*2.7)*0.3;
            float3 barC = recolor(dYellow(), fi*0.12, pal);
            col += barC * fillRect(uv, bx, py_base, bx+0.025, py_base+bh);
            // Blue segment at bottom
            float3 bBlue = recolor(dBlue(), fi*0.12+0.2, pal);
            col += bBlue * fillRect(uv, bx, py_base, bx+0.025, py_base+bh*0.35);
        }
        // Secondary node tree (right lower)
        col += draw_node_tree(uv, 0.820, 0.250, 0.65, t*0.9, beat, u.jogValue, gnc, gnc, wc, pal);
    }

    // ══════════════════════════════════════════════════════════════════════
    //  BOTTOM-RIGHT: OFFL block (yellow label) + colored fill panels
    // ══════════════════════════════════════════════════════════════════════
    {
        // Red block (upper right corner panel)
        float3 fillRed = recolor(dRed(), 0.0, pal);
        col += fillRed * fillRect(uv, 0.760, 0.530, 0.995, 0.720);
        // White T-shape on red
        float3 wc2 = recolor(dWhite(), 0.0, pal);
        col += wc2 * fillRect(uv, 0.815, 0.610, 0.940, 0.640);
        col += wc2 * fillRect(uv, 0.855, 0.565, 0.900, 0.705);
        col -= wc2 * fillRect(uv, 0.862, 0.572, 0.893, 0.698); // cutout

        // Green block (middle right corner)
        float3 fillGreen = recolor(dGreen(), 0.5, pal);
        col += fillGreen * fillRect(uv, 0.760, 0.315, 0.995, 0.525);
        // Small node graph on green
        col += draw_node_tree(uv, 0.878, 0.418, 0.55, t*1.1, beat,
                              u.jogValue, gnc*0.4, gnc*0.5, wc, pal);

        // OFFL yellow bottom-right block
        float3 fillYellow = recolor(dYellow(), 0.0, pal);
        col += fillYellow * fillRect(uv, 0.760, 0.040, 0.995, 0.310);
        // "OFFL" text blocks on yellow (dark)
        float3 darkC = float3(0.05, 0.04, 0.02);
        // O
        col += darkC * borderRect(uv, 0.775, 0.195, 0.820, 0.285, 0.014);
        // F (two bars)
        col += darkC * fillRect(uv, 0.832, 0.195, 0.845, 0.285);
        col += darkC * fillRect(uv, 0.832, 0.243, 0.866, 0.255);
        col += darkC * fillRect(uv, 0.832, 0.273, 0.858, 0.285);
        // F
        col += darkC * fillRect(uv, 0.876, 0.195, 0.889, 0.285);
        col += darkC * fillRect(uv, 0.876, 0.243, 0.910, 0.255);
        col += darkC * fillRect(uv, 0.876, 0.273, 0.902, 0.285);
        // L
        col += darkC * fillRect(uv, 0.920, 0.195, 0.933, 0.285);
        col += darkC * fillRect(uv, 0.920, 0.195, 0.955, 0.207);

        // Bracket corners on OFFL block
        col += wc2 * bracketCorners(uv, 0.763, 0.044, 0.992, 0.308, 0.020, th);
    }

    // ══════════════════════════════════════════════════════════════════════
    //  GLOBAL SCAN SWEEP + FX
    // ══════════════════════════════════════════════════════════════════════

    // Slow vertical scan sweep
    {
        float scanY = fract(t * 0.18 + u.jogValue * 0.4);
        float beam  = exp(-abs(uv.y - scanY) * 50.0) * (0.04 + beat * 0.09);
        col += recolor(dYellow(), 0.0, pal) * beam;
    }

    // Beat flash
    {
        float flash = max(0.0, beat - 0.78) * 3.5 * step(u.beatPhase, 0.07);
        col = mix(col, wc, flash * 0.16);
    }

    // Chromatic aberration
    {
        float ca = 0.0015 + beat * 0.007;
        col.r += ca * sin(uv.y * 70.0 + t * 2.8) * beat * 0.5;
        col.b -= ca * sin(uv.y * 70.0 - t * 2.1) * beat * 0.5;
    }

    // Fine scanlines
    col *= 0.90 + 0.10 * sin(uv.y * u.resolution.y * 1.57);

    // Film grain
    col += (h2(uv + fract(t * 9.3)) - 0.5) * 0.016;

    col = clamp(col * (0.83 + energy * 0.35), 0.0, 1.0);
    return float4(col, 1.0);
}
