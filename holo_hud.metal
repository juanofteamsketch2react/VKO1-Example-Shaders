// holo_hud.metal — Sci-fi holographic blueprint HUD
//
// Aesthetic: Dark military-tech, deep blue/cyan/green hologram
// on near-black. Wireframe human silhouette left panel,
// central tactical display with rotating target reticle and
// hex/grid overlays, right panel component readouts.
// Everything scan-lines, glitches, and breathes with audio.
//
// Uniforms used:
//   time         → animation driver
//   beatPhase    → scan sweep timing
//   beatStrength → glitch intensity, brightness spikes
//   energy       → overall glow level
//   reactivity   → beat coupling strength
//   complexity   → grid/hex density, readout detail
//   speed        → scan line and sweep speed
//   colorPalette → tint shift
//   jogValue     → manual reticle rotation

#include <metal_stdlib>
using namespace metal;

// ─────────────────────────────────────────────
//  PALETTE  (same block as previous shaders)
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
    return fract(sin(dot(p, float2(127.1,311.7))) * 43758.5453);
}
float hash1(float n) { return fract(sin(n) * 43758.5453); }

// GLSL-style mod (floored modulo) — Metal only has fmod (truncated)
float modf_glsl(float x, float y) {
    return x - y * floor(x / y);
}

float snoise(float2 p) {
    float2 i = floor(p), f = fract(p);
    f = f*f*(3.0-2.0*f);
    return mix(mix(hash(i),hash(i+float2(1,0)),f.x),
               mix(hash(i+float2(0,1)),hash(i+float2(1,1)),f.x),f.y);
}

// Rotate 2D
float2 rot2(float2 p, float a) {
    float s = sin(a), c = cos(a);
    return float2(p.x*c - p.y*s, p.x*s + p.y*c);
}

// SDF primitives (for panel shapes)
float sdBox(float2 p, float2 b) {
    float2 d = abs(p) - b;
    return length(max(d, 0.0)) + min(max(d.x,d.y), 0.0);
}

// Thin glowing line from signed dist
float glowLine(float d, float w, float bloom) {
    return smoothstep(w, 0.0, abs(d)) + exp(-abs(d)/bloom)*0.5;
}

// ─────────────────────────────────────────────
//  HOLOGRAM BASE COLOR  — deep teal/blue-cyan
// ─────────────────────────────────────────────

float3 holoColor(float t, int pal, float accent) {
    // Bias toward cyan/blue regardless of palette, with palette as tint
    float3 base = float3(0.05, 0.55, 0.85);
    float3 green = float3(0.1, 0.9, 0.4);
    float3 palCol = get_palette_color(t, pal);
    return mix(mix(base, green, accent), palCol, 0.25);
}

// ─────────────────────────────────────────────
//  BACKGROUND — dot-matrix grid + ambient fog
// ─────────────────────────────────────────────

float3 draw_background(float2 uv, float t, float beat, int pal) {
    // Deep black base
    float3 col = float3(0.0, 0.005, 0.015);

    // Fine dot matrix — every intersection of a blueprint grid
    float gridSize = 0.025;
    float2 g = fract(uv / gridSize) - 0.5;
    float dot = smoothstep(0.08, 0.0, length(g));
    float3 dotColor = holoColor(0.5, pal, 0.0) * 0.18;
    col += dotColor * dot;

    // Subtle large grid lines
    float gx = smoothstep(0.008, 0.0, abs(fract(uv.x / 0.1) - 0.5) - 0.49);
    float gy = smoothstep(0.008, 0.0, abs(fract(uv.y / 0.1) - 0.5) - 0.49);
    col += holoColor(0.4, pal, 0.0) * (gx + gy) * 0.06;

    // Ambient holo fog — denser in center
    float fog = exp(-length(uv - 0.5) * 3.5) * 0.04;
    col += holoColor(0.6, pal, 0.1) * fog * (1.0 + beat * 0.8);

    return col;
}

// ─────────────────────────────────────────────
//  PANEL BORDERS — rectangular HUD frames
// ─────────────────────────────────────────────

float3 draw_panels(float2 uv, float t, float beat, float beatPhase, int pal) {
    float3 col = float3(0.0);
    float3 pc  = holoColor(0.55 + beatPhase * 0.05, pal, 0.0);
    float  pw  = 0.0015;                   // line width
    float  pb  = 0.006 + beat * 0.004;    // bloom radius

    // LEFT PANEL  — human figure frame
    float2 lpCenter = float2(0.18, 0.5);
    float2 lpHalf   = float2(0.13, 0.42);
    float2 lpUV     = uv - lpCenter;
    float  lpD      = sdBox(lpUV, lpHalf);
    col += pc * glowLine(lpD, pw, pb) * 0.7;

    // Corner tick marks — top-left
    float2 tlc = lpCenter - lpHalf;
    col += pc * glowLine(uv.x - tlc.x, pw*0.5, pb*0.5)
              * step(tlc.y, uv.y) * step(uv.y, tlc.y + 0.03) * 0.9;
    col += pc * glowLine(uv.y - tlc.y, pw*0.5, pb*0.5)
              * step(tlc.x, uv.x) * step(uv.x, tlc.x + 0.03) * 0.9;
    // top-right
    float2 trc = float2(lpCenter.x + lpHalf.x, lpCenter.y - lpHalf.y);
    col += pc * glowLine(uv.x - trc.x, pw*0.5, pb*0.5)
              * step(trc.y, uv.y) * step(uv.y, trc.y + 0.03) * 0.9;
    // bottom-left
    float2 blc = float2(lpCenter.x - lpHalf.x, lpCenter.y + lpHalf.y);
    col += pc * glowLine(uv.y - blc.y, pw*0.5, pb*0.5)
              * step(blc.x, uv.x) * step(uv.x, blc.x + 0.03) * 0.9;

    // CENTER PANEL — main tactical display
    float2 cpCenter = float2(0.5, 0.46);
    float2 cpHalf   = float2(0.19, 0.38);
    float2 cpUV     = uv - cpCenter;
    float  cpD      = sdBox(cpUV, cpHalf);
    col += pc * glowLine(cpD, pw, pb) * 0.9;
    // Inner inset line
    col += pc * glowLine(sdBox(cpUV, cpHalf - 0.008), pw*0.5, pb*0.3) * 0.3;

    // Center panel bottom label bar separator
    float labelY = cpCenter.y + cpHalf.y - 0.12;
    float labelLine = glowLine(uv.y - labelY, pw, pb*0.5);
    float inCpX = step(cpCenter.x - cpHalf.x, uv.x) * step(uv.x, cpCenter.x + cpHalf.x);
    col += pc * labelLine * inCpX * 0.7;

    // RIGHT PANELS — component readouts (3 stacked)
    float2 rpCenter = float2(0.82, 0.5);
    float rpW = 0.12, rpH = 0.11;
    for (int r = 0; r < 3; r++) {
        float ry = 0.22 + float(r) * 0.27;
        float2 rpC = float2(rpCenter.x, ry);
        float  rpD = sdBox(uv - rpC, float2(rpW, rpH));
        col += pc * glowLine(rpD, pw, pb) * 0.65;
        // Inner readout lines
        for (int l = 1; l < 4; l++) {
            float lineY = ry - rpH + float(l) * (rpH * 2.0 / 4.0);
            float inRpX = step(rpC.x - rpW, uv.x) * step(uv.x, rpC.x + rpW);
            col += pc * glowLine(uv.y - lineY, pw*0.4, pb*0.3) * inRpX * 0.25;
        }
    }

    return col;
}

// ─────────────────────────────────────────────
//  WIREFRAME HUMAN FIGURE  (left panel)
// ─────────────────────────────────────────────

float3 draw_figure(float2 uv, float t, float beat, float beatPhase, int pal) {
    float3 col   = float3(0.0);
    float3 fc    = holoColor(0.5 + beatPhase * 0.08, pal, 0.05);
    float3 accent = float3(0.1, 1.0, 0.4);  // green accent hotspots

    // Figure is centered in the left panel
    float2 fc2  = float2(0.18, 0.50);
    float2 p    = uv - fc2;

    // Breathing scale pulse
    float breathe = 1.0 + sin(t * 0.7) * 0.012 + beat * 0.02;
    p /= breathe;

    // ── HEAD ──
    float2 headC  = float2(0.0, -0.28);
    float  headR  = 0.045;
    float  headD  = length(p - headC) - headR;
    col += fc * glowLine(headD, 0.002, 0.008) * 0.9;

    // Head inner grid (visor lines)
    float2 hp    = p - headC;
    float inHead = smoothstep(headR + 0.002, headR, length(hp));
    float hGridH = smoothstep(0.003, 0.0, abs(fract(hp.y / 0.018 + 0.5) - 0.5) - 0.48);
    float hGridV = smoothstep(0.003, 0.0, abs(fract(hp.x / 0.018 + 0.5) - 0.5) - 0.48);
    col += fc * (hGridH + hGridV) * inHead * 0.35;

    // ── NECK ──
    float neckTop = -0.235, neckBot = -0.21;
    float neckW   = 0.018;
    float nEdgeL  = glowLine(p.x + neckW, 0.001, 0.004) * step(neckTop, p.y)*step(p.y, neckBot);
    float nEdgeR  = glowLine(p.x - neckW, 0.001, 0.004) * step(neckTop, p.y)*step(p.y, neckBot);
    col += fc * (nEdgeL + nEdgeR) * 0.7;

    // ── TORSO ──
    float2 torsoC = float2(0.0, 0.0);
    float2 torsoH = float2(0.065, 0.115);
    float  torsoD = sdBox(p - torsoC, torsoH);
    col += fc * glowLine(torsoD, 0.0015, 0.007) * 0.85;

    // Torso internal structure lines (chest plates)
    float2 tp = p - torsoC;
    float inTorso = step(-torsoH.x, tp.x)*step(tp.x, torsoH.x)
                   *step(-torsoH.y, tp.y)*step(tp.y, torsoH.y);
    // Horizontal ribs
    for (int ri = 0; ri < 5; ri++) {
        float ry = -0.09 + float(ri) * 0.045;
        col += fc * glowLine(tp.y - ry, 0.001, 0.005) * inTorso * 0.3;
    }
    // Vertical sternum
    col += fc * glowLine(tp.x, 0.001, 0.004) * inTorso * 0.3;
    // Center hex accent
    float hexR  = 0.022;
    float hexD  = length(float2(abs(tp.x)*0.866 + tp.y*0.5, tp.y)) - hexR;
    col += accent * smoothstep(0.003, 0.0, abs(hexD)) * (0.6 + beat * 0.8);
    col += accent * exp(-max(0.0,hexD)*30.0) * 0.3 * (1.0 + beat);

    // ── SHOULDERS / UPPER ARMS ──
    for (int side = 0; side < 2; side++) {
        float sx = (side == 0) ? -1.0 : 1.0;

        // Shoulder box
        float2 shC = float2(sx * 0.092, -0.085);
        float2 shH = float2(0.028, 0.035);
        float shD = sdBox(p - shC, shH);
        col += fc * glowLine(shD, 0.0015, 0.006) * 0.75;

        // Upper arm
        float2 uaC = float2(sx * 0.105, 0.01);
        float2 uaH = float2(0.02, 0.07);
        float uaD = sdBox(p - uaC, uaH);
        col += fc * glowLine(uaD, 0.0015, 0.006) * 0.7;

        // Elbow joint circle
        float2 ejC = float2(sx * 0.105, 0.085);
        float ejD = length(p - ejC) - 0.018;
        col += fc * glowLine(ejD, 0.0015, 0.006) * 0.7;

        // Forearm
        float2 faC = float2(sx * 0.108, 0.165);
        float2 faH = float2(0.017, 0.065);
        float faD = sdBox(p - faC, faH);
        col += fc * glowLine(faD, 0.0015, 0.006) * 0.65;

        // Wrist accent dot
        float2 wrist = float2(sx * 0.108, 0.232);
        float wristD = length(p - wrist) - 0.01;
        col += accent * smoothstep(0.002, 0.0, abs(wristD)) * 0.7;
    }

    // ── PELVIS ──
    float2 pelC = float2(0.0, 0.135);
    float2 pelH = float2(0.058, 0.025);
    float pelD = sdBox(p - pelC, pelH);
    col += fc * glowLine(pelD, 0.0015, 0.006) * 0.75;

    // ── LEGS ──
    for (int side = 0; side < 2; side++) {
        float sx = (side == 0) ? -1.0 : 1.0;

        // Upper leg
        float2 ulC = float2(sx * 0.035, 0.215);
        float2 ulH = float2(0.025, 0.075);
        float ulD = sdBox(p - ulC, ulH);
        col += fc * glowLine(ulD, 0.0015, 0.006) * 0.75;

        // Knee joint
        float2 knC = float2(sx * 0.035, 0.295);
        float knD = length(p - knC) - 0.022;
        col += fc * glowLine(knD, 0.0015, 0.006) * 0.7;

        // Lower leg
        float2 llC = float2(sx * 0.035, 0.37);
        float2 llH = float2(0.020, 0.065);
        float llD = sdBox(p - llC, llH);
        col += fc * glowLine(llD, 0.0015, 0.006) * 0.65;

        // Boot
        float2 btC = float2(sx * 0.04, 0.435);
        float2 btH = float2(0.030, 0.018);
        float btD = sdBox(p - btC, btH);
        col += fc * glowLine(btD, 0.0015, 0.006) * 0.6;
    }

    // ── SCAN BEAM sweeping vertically through figure ──
    float scanY  = fract(t * 0.4) * 0.9 - 0.45;
    float scanW  = 0.012 + beat * 0.01;
    float scanMask = step(-0.13, p.x) * step(p.x, 0.13)  // within figure width
                   * step(-0.46, p.y) * step(p.y, 0.46);
    float scanBeam = exp(-abs(p.y - scanY) / scanW) * scanMask;
    col += holoColor(0.6, pal, 0.3) * scanBeam * (0.5 + beat * 0.6);

    return col;
}

// ─────────────────────────────────────────────
//  CENTER TACTICAL DISPLAY
// ─────────────────────────────────────────────

float3 draw_tactical(float2 uv, float t, float beat, float beatPhase,
                     float energy, float complexity, float jogValue, int pal) {
    float3 col  = float3(0.0);
    float3 fc   = holoColor(0.52 + beatPhase * 0.06, pal, 0.05);
    float3 acc  = float3(0.1, 1.0, 0.4);

    float2 center = float2(0.5, 0.39);
    float2 p = uv - center;

    // ── ROTATING RETICLE RINGS ──
    float rotA  = t * 0.3 + jogValue * 6.283;
    float rotB  = -t * 0.5;
    float radius = length(p);

    // Outer ring
    col += fc * glowLine(radius - 0.14, 0.0015, 0.007) * 0.8;
    // Middle dashed ring — tick marks
    float dashRing = glowLine(radius - 0.10, 0.0012, 0.005);
    float dashAngle = fract(atan2(p.y, p.x) / 6.283185 * 16.0);
    dashRing *= step(0.15, dashAngle);   // gaps every 1/16th
    col += fc * dashRing * 0.6;
    // Inner ring — pulses with beat
    col += fc * glowLine(radius - (0.055 + beat * 0.015), 0.0015, 0.007) * (0.7 + beat * 0.5);

    // ── CROSSHAIR LINES (rotating) ──
    float2 rp = rot2(p, rotA);
    float hCross = glowLine(rp.y, 0.0012, 0.004) * step(0.0, rp.x);    // right half only
    float vCross = glowLine(rp.x, 0.0012, 0.004) * step(0.0, -rp.y);   // top half only
    col += fc * (hCross + vCross) * smoothstep(0.145, 0.06, radius) * 0.8;

    // Opposite quadrant — counter-rotating
    float2 rp2 = rot2(p, rotB);
    float hCross2 = glowLine(rp2.y, 0.0012, 0.004) * step(0.0, -rp2.x);
    float vCross2 = glowLine(rp2.x, 0.0012, 0.004) * step(0.0, rp2.y);
    col += fc * (hCross2 + vCross2) * smoothstep(0.145, 0.06, radius) * 0.6;

    // ── HEX GRID OVERLAY inside outer ring ──
    float inCircle = smoothstep(0.142, 0.135, radius);
    float2 hexUV = p * (8.0 + complexity * 4.0);
    float2 hg = hexUV;
    // Simple hex-ish approximation via two rotated grids
    float hex1 = abs(fract(hg.x * 0.866 - hg.y * 0.5) - 0.5);
    float hex2 = abs(fract(hg.y) - 0.5);
    float hex3 = abs(fract(hg.x * 0.866 + hg.y * 0.5) - 0.5);
    float hexGrid = smoothstep(0.06, 0.0, min(hex1, min(hex2, hex3)));
    col += fc * hexGrid * inCircle * 0.25;

    // Some hex cells lit up as "data blocks"
    float2 cellID = floor(p * 12.0);
    float cellH   = hash(cellID + floor(t * 0.5));
    float litCell = step(0.6, cellH) * inCircle;
    float2 cellUV = fract(p * 12.0) - 0.5;
    float cellBox = smoothstep(0.4, 0.35, max(abs(cellUV.x), abs(cellUV.y)));
    col += mix(fc, acc, step(0.85, cellH)) * cellBox * litCell * 0.35;

    // ── CENTER LOCK DIAMOND ──
    float diamond = abs(p.x) + abs(p.y);
    col += acc * glowLine(diamond - 0.025, 0.002, 0.008) * (0.8 + beat * 1.0);
    col += acc * exp(-diamond * 30.0) * 0.4 * (1.0 + beat * 0.8);

    // ── RANGE TICK MARKS around outer ring ──
    for (int ti = 0; ti < 24; ti++) {
        float ta = float(ti) / 24.0 * 6.283185 + rotA * 0.3;
        float2 tickDir = float2(cos(ta), sin(ta));
        float tickDot = dot(normalize(p + 0.0001), tickDir);
        float tickAng = acos(clamp(tickDot, -1.0, 1.0));
        float tickLen = (ti % 6 == 0) ? 0.018 : 0.009;
        float inTick  = smoothstep(0.006, 0.0, tickAng) * step(0.14 - tickLen, radius) * step(radius, 0.145);
        col += fc * inTick * 0.9;
    }

    // ── DATA READOUT BAR (bottom of center panel) ──
    float2 barCenter = float2(0.5, 0.755);
    float2 barUV     = uv - barCenter;
    float  inBar     = step(-0.185, barUV.x)*step(barUV.x, 0.185)
                      *step(-0.055, barUV.y)*step(barUV.y, 0.055);
    // Simulated text blocks — rows of thin rectangles
    for (int row = 0; row < 3; row++) {
        float rowY = -0.03 + float(row) * 0.028;
        float rowInY = step(rowY - 0.007, barUV.y) * step(barUV.y, rowY + 0.007);
        for (int col2 = 0; col2 < 8; col2++) {
            float cx    = -0.17 + float(col2) * 0.048;
            float cw    = 0.018 + hash1(float(col2 * 3 + row)) * 0.018;
            float inCol2 = step(cx, barUV.x) * step(barUV.x, cx + cw);
            float dataH = hash1(float(col2 + row * 7) + floor(t * 0.8));
            float active = step(0.3, dataH);
            float3 dataColor = mix(fc, acc, step(0.8, dataH));
            col += dataColor * inBar * rowInY * inCol2 * active * 0.5;
        }
    }

    // ── SWEEP SCAN — rotates around the circle ──
    float sweepAngle = fract(t * 0.25) * 6.283185;
    float sweepA     = atan2(p.y, p.x);
    float sweepDiff  = modf_glsl(sweepA - sweepAngle + 6.283185, 6.283185);
    float sweepBeam  = exp(-sweepDiff * 1.8) * smoothstep(0.145, 0.01, radius);
    col += holoColor(0.55, pal, 0.3) * sweepBeam * (0.4 + beat * 0.5);

    return col;
}

// ─────────────────────────────────────────────
//  RIGHT PANEL — component readout boxes
// ─────────────────────────────────────────────

float3 draw_readouts(float2 uv, float t, float beat, float beatPhase, int pal) {
    float3 col = float3(0.0);
    float3 fc  = holoColor(0.53, pal, 0.0);
    float3 acc = float3(0.1, 1.0, 0.4);

    float rpX = 0.82;
    float rpW = 0.10, rpH = 0.10;
    float yPositions[3] = {0.22, 0.49, 0.76};

    for (int r = 0; r < 3; r++) {
        float2 rc  = float2(rpX, yPositions[r]);
        float2 p   = uv - rc;
        float inBox = step(-rpW, p.x)*step(p.x, rpW)
                     *step(-rpH, p.y)*step(p.y, rpH);

        // Each box gets a different component shape

        if (r == 0) {
            // TOP BOX: rotating octagon / sensor ring
            float2 rp = rot2(p, t * 0.4);
            float octD = max(max(abs(rp.x), abs(rp.y)),
                             (abs(rp.x) + abs(rp.y)) * 0.707) - 0.055;
            col += fc * glowLine(octD, 0.0015, 0.006) * inBox;
            float innerD = max(max(abs(rp.x), abs(rp.y)),
                               (abs(rp.x) + abs(rp.y)) * 0.707) - 0.035;
            col += fc * glowLine(innerD, 0.001, 0.004) * inBox * 0.5;
            // Center dot
            col += acc * exp(-length(p)*50.0) * (0.8 + beat);
        }

        if (r == 1) {
            // MID BOX: bar graph / power readout
            int bars = 5;
            for (int b = 0; b < bars; b++) {
                float bx   = -0.07 + float(b) * 0.035;
                float bh   = 0.03 + hash1(float(b) + floor(t * 1.5)) * 0.06;
                bh *= (1.0 + beat * hash1(float(b)) * 0.5);
                float barM = step(bx, p.x)*step(p.x, bx+0.025)
                            *step(-bh, p.y)*step(p.y, 0.0);
                float3 barC = mix(fc, acc, float(b) / float(bars));
                col += barC * barM * inBox * 0.7;
                // Bar top glow
                col += barC * exp(-abs(p.y + bh)*40.0)
                            * step(bx, p.x)*step(p.x, bx+0.025) * inBox * 0.5;
            }
        }

        if (r == 2) {
            // BOTTOM BOX: two circular tank/canister shapes
            for (int c = 0; c < 2; c++) {
                float cx = (c == 0) ? -0.04 : 0.04;
                float2 cp = p - float2(cx, 0.0);
                // Outer oval
                float2 ovalP = cp / float2(0.028, 0.068);
                float  ovalD = length(ovalP) - 1.0;
                col += fc * glowLine(ovalD * 0.028, 0.0015, 0.006) * inBox;
                // Fill level — reacts to beat
                float fillH = 0.3 + hash1(float(c)) * 0.4 + beat * 0.15;
                float fillY = mix(0.068, -0.068, fillH);
                float fillM = step(-0.028, cp.x)*step(cp.x, 0.028)
                             *step(fillY, cp.y)*step(cp.y, 0.06);
                float inOval = smoothstep(1.02, 0.95, length(ovalP));
                col += mix(fc, acc, fillH) * fillM * inOval * 0.5;
                // Level line
                col += acc * glowLine(cp.y - fillY, 0.001, 0.005)
                           * step(-0.025, cp.x)*step(cp.x, 0.025) * inBox * 0.7;
            }
        }

        // Label bar at bottom of each readout box
        float labelY   = rpH - 0.025;
        float inLabelY = step(labelY - 0.015, p.y) * step(p.y, labelY + 0.001);
        // Dashed text simulation
        for (int seg = 0; seg < 6; seg++) {
            float sx2 = -0.08 + float(seg) * 0.03;
            float sw   = 0.018 * hash1(float(seg + r * 7));
            float inSeg = step(sx2, p.x)*step(p.x, sx2+sw);
            col += fc * inSeg * inLabelY * inBox * 0.4;
        }
    }

    return col;
}

// ─────────────────────────────────────────────
//  GLITCH EFFECT
// ─────────────────────────────────────────────

float2 glitch_uv(float2 uv, float t, float beat) {
    float2 g = uv;
    // Horizontal band glitch — triggers on high beat
    float glitchBand = hash1(floor(uv.y * 60.0 + t * 8.0));
    float glitchActive = step(1.0 - beat * 0.5, glitchBand);
    float glitchOffset = (hash1(floor(uv.y * 60.0 + t * 12.0)) - 0.5) * 0.03;
    g.x += glitchOffset * glitchActive * beat;
    // Rare full-row jump
    float bigGlitch = step(0.97, beat) * step(0.92, hash1(floor(t * 3.0)));
    g.y += (hash1(floor(t * 5.0)) - 0.5) * 0.01 * bigGlitch;
    return g;
}

// ─────────────────────────────────────────────
//  MAIN FRAGMENT
// ─────────────────────────────────────────────

fragment float4 holo_hud(
    VertexOut in [[stage_in]],
    constant GeneratorUniforms &u [[buffer(0)]]
) {
    float2 uv   = in.uv;
    float aspect = u.resolution.x / u.resolution.y;
    float2 cuv  = (uv - 0.5) * float2(aspect, 1.0);

    float t      = u.time * u.speed;
    float beat   = u.beatStrength * u.reactivity;
    float energy = u.energy;

    // ── Glitch UV distortion on beat ──
    float2 guv = glitch_uv(uv, t, beat);

    // ── Background ──
    float3 col = draw_background(guv, t, beat, u.colorPalette);

    // ── Panel borders ──
    col += draw_panels(guv, t, beat, u.beatPhase, u.colorPalette);

    // ── Wireframe figure ──
    col += draw_figure(guv, t, beat, u.beatPhase, u.colorPalette);

    // ── Center tactical display ──
    col += draw_tactical(guv, t, beat, u.beatPhase, energy,
                         u.complexity, u.jogValue, u.colorPalette);

    // ── Right readout panels ──
    col += draw_readouts(guv, t, beat, u.beatPhase, u.colorPalette);

    // ── Global horizontal scan line sweep ──
    float scanSpeed = u.speed * 0.6;
    float scanY = fract(u.time * scanSpeed);
    float scanBeam = exp(-abs(uv.y - scanY) * 35.0) * (0.12 + beat * 0.15);
    col += holoColor(0.55, u.colorPalette, 0.2) * scanBeam;

    // ── CRT scanline texture ──
    float crt = 0.82 + 0.18 * sin(uv.y * u.resolution.y * 1.5);
    col *= crt;

    // ── Phosphor flicker — subtle brightness variation ──
    float flicker = 0.95 + 0.05 * sin(u.time * 47.3) * sin(u.time * 31.7);
    col *= flicker;

    // ── Beat flash — white-teal bloom ──
    float3 flashColor = holoColor(u.beatPhase * 0.3 + 0.5, u.colorPalette, 0.2);
    col += flashColor * beat * beat * 0.5;

    // ── Chromatic aberration — RGB split, spikes on beat ──
    float caStr = 0.003 + beat * 0.012;
    float2 caDir = normalize(cuv + 0.0001) * caStr;
    float rShift = snoise((uv + caDir) * 120.0) * (0.004 + beat * 0.01);
    float bShift = snoise((uv - caDir) * 120.0) * (0.004 + beat * 0.01);
    col.r += rShift;
    col.b -= bShift;

    // ── Film grain ──
    col += (hash(uv + fract(t * 9.1)) - 0.5) * 0.025;

    // ── Vignette ──
    float vig = smoothstep(0.9, 0.35, length(cuv / float2(aspect, 1.0) * float2(1.0, 1.3)));
    col *= vig;

    // ── Hologram color grading — crush blacks, boost cyan ──
    float lum = dot(col, float3(0.299, 0.587, 0.114));
    col = mix(float3(lum) * 0.3, col, 1.4);  // slight desaturate → resaturate with holo bias
    col.b  *= 1.1;
    col.g  *= 1.05;
    col    *= (0.9 + energy * 0.3);
    col     = clamp(col, 0.0, 1.0);

    return float4(col, 1.0);
}
