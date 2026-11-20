#version 320 es
precision highp float;

in vec2 v_texcoord;
out vec4 fragColor;
uniform sampler2D tex;
uniform float time;
uniform vec2 surface_size;

#define umbriel_sample(uv) texture(tex, (uv))
// Theme palette: the same bridge the border pass uses, so the interior and
// the exterior half of a paired effect paint with the same colours.
uniform int umbriel_palette_count;
uniform vec4 umbriel_palette[4];
vec4 umbriel_palette_at(float t) {
    if (umbriel_palette_count <= 0) return vec4(0.07, 0.12, 0.19, 1.0);
    float span = float(umbriel_palette_count);
    float pos  = clamp(t, 0.0, 0.999) * span;
    float index = floor(pos);
    float next = index + 1.0;
    vec4 from = umbriel_palette[0];
    vec4 to = umbriel_palette[0];
    for (int i = 0; i < 4; i++) {
        if (float(i) >= span) break;
        if (float(i) == index) from = umbriel_palette[i];
        if (float(i) == next) to = umbriel_palette[i];
    }
    return mix(from, to, pos - index);
}
#define umbriel_time time
#define umbriel_size surface_size
#define umbriel_scale 1.0

// Adapted from shaders/beach-surf/overlay.glsl

// Theme colours affect artwork only; palette = false restores the original RGB.
// Keep the original shade and soften highlights without changing effect opacity.
vec3 theme_color(vec3 original, float position) {
    if (umbriel_palette_count <= 0) return original;
    float value = max(original.r, max(original.g, original.b));
    float white = min(original.r, min(original.g, original.b)) / max(value, 0.0001);
    return value * mix(umbriel_palette_at(position).rgb, vec3(1.0), white * 0.75);
}

vec4 tex2D_screen(vec2 uv) { return umbriel_sample(uv); }


vec2 surf_hash(vec2 p) {
    return fract(sin(vec2(dot(p, vec2(127.1, 311.7)),
        dot(p, vec2(269.5, 183.3)))) * 43758.5453);
}

float surf_noise(vec2 p) {
    vec2 i = floor(p), f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    return mix(mix(surf_hash(i).x, surf_hash(i + vec2(1.0, 0.0)).x, f.x),
        mix(surf_hash(i + vec2(0.0, 1.0)).x, surf_hash(i + 1.0).x, f.x), f.y);
}

// Distance between the two nearest moving cells makes fine, irregular bubble
// walls. Fixed loop bounds work on GLES2; callers cull non-edge pixels first.
float surf_bubbles(vec2 p, float t) {
    p += 0.22 * sin(p.yx * vec2(1.3, 1.6) + vec2(t * 0.8, -t * 0.6));
    vec2 cell = floor(p), local = fract(p);
    float nearest = 8.0, second = 8.0;
    for (int y = -1; y <= 1; ++y) {
        for (int x = -1; x <= 1; ++x) {
            vec2 offset = vec2(float(x), float(y));
            vec2 random = surf_hash(cell + offset);
            vec2 centre = 0.5 + 0.32 * sin(t * 0.7 + 6.2831853 * random);
            float d = length(offset + centre - local);
            second = min(second, max(nearest, d));
            nearest = min(nearest, d);
        }
    }
    return 1.0 - smoothstep(0.055, 0.17, second - nearest);
}

vec3 surf_water(float noise, float light) {
    vec3 color = mix(theme_color(vec3(0.018, 0.16, 0.22), 0.25), theme_color(vec3(0.055, 0.43, 0.48), 0.25), noise);
    return mix(color, theme_color(vec3(0.33, 0.68, 0.70), 0.25), clamp(light, 0.0, 0.65));
}

// Straight RGBA. d is signed logical-pixel distance: negative is inside.
vec4 surf_edge(vec2 p, float d, float t, float aa) {
    if (d < -24.0 || d > 32.0) return vec4(0.0);
    vec2 drift = vec2(t * 0.31, -t * 0.23);
    float n = surf_noise(p * 0.035 + drift);
    float fine = surf_noise(p * 0.14 - drift * 1.3);
    float extent = 16.0 + 10.0 * n;
    float envelope = smoothstep(-24.0, -7.0, d)
        * (1.0 - smoothstep(extent - 3.0, extent, d));
    // Successive crests wash inward. The two sides share a time and palette,
    // rather than restarting the motion at each corner.
    float phase = (d + t * 9.0 + n * 7.0) / 16.0;
    float crestDistance = abs(fract(phase) - 0.5) * 16.0;
    float crest = 1.0 - smoothstep(1.8, 5.2 + aa, crestDistance);
    float bubbles = surf_bubbles(p * 0.18 + vec2(t * 0.48, -t * 0.32), t);
    float lace = bubbles * smoothstep(0.30, 0.66, fine)
        * (0.35 + 0.65 * (1.0 - smoothstep(1.0, 6.0, crestDistance)));
    float foam = clamp(crest * (0.45 + 0.35 * fine + 0.20 * bubbles) + lace * 0.7, 0.0, 1.0);
    foam *= mix(0.50, 1.0, smoothstep(0.25, 0.65, n));
    float alpha = envelope * (0.25 + foam * 0.70);
    // The inner wash stays translucent; the outer breakers remain bright.
    alpha *= mix(0.50, 1.0, smoothstep(-12.0, 1.0, d));
    vec3 color = mix(surf_water(n, crest * 0.3), theme_color(vec3(0.88, 0.97, 0.94), 0.25), foam);
    return vec4(color, clamp(alpha, 0.0, 1.0));
}

uniform vec4 umbriel_border_radius;  // host-bound: the surface's real rounding (logical px)
#define SURF_CONTENT_RADIUS umbriel_border_radius.x
vec4 postprocess(vec3 coords) {
    vec4 source = tex2D_screen(coords.xy);
    vec2 size = umbriel_size / max(umbriel_scale, 0.01);
    vec2 p = coords.xy * size;
    float edge = min(min(p.x, p.y), min(size.x - p.x, size.y - p.y));
    if (edge >= 24.0) return source;
    float radius = min(SURF_CONTENT_RADIUS, min(size.x, size.y) * 0.5);
    vec2 q = abs(p - size * 0.5) - size * 0.5 + radius;
    float d = length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - radius;
    vec4 foam = surf_edge(p, d,
        umbriel_time, 0.65 / max(umbriel_scale, 0.01));
    return vec4(mix(source.rgb, foam.rgb * source.a, foam.a), source.a);
}

vec4 window(vec2 uv) { return postprocess(vec3(uv, 0.0)); }

void main() {
    fragColor = window(v_texcoord);
}
