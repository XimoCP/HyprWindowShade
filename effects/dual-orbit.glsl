#version 320 es
// dual-orbit — from the Umbriel community border collection (see NOTICE in this folder).
// Band width the effect paints (logical px). The plugin applies general:border_size
// to this on activation and restores the config value on clear.
// @border 3
// Umbriel's preset speed for this effect (effects.cpp: seconds * preset->speed
// feeds umbriel_time; dual-orbit ships speed = 6.0).
// @speed 6
// Extra transparent space the effect declares beyond the band (its preset padding).
// @padding 14
// A steady border with two palette-colored highlights orbiting clockwise.
// Follow the rounded client-hole contour so the highlights cross corners smoothly.
vec2 orbit_position(vec2 p, vec2 size, vec4 r) {
    const float quarter = 1.57079632679;
    float top = size.x - r.x - r.y;
    float rightStart = top + quarter * r.y;
    float bottomRightStart = rightStart + size.y - r.y - r.z;
    float bottomStart = bottomRightStart + quarter * r.z;
    float bottomLeftStart = bottomStart + size.x - r.z - r.w;
    float leftStart = bottomLeftStart + quarter * r.w;
    float topLeftStart = leftStart + size.y - r.w - r.x;
    float perimeter = topLeftStart + quarter * r.x;
    float along;

    // Each arc meets its neighboring straight sides at the same perimeter value.
    if (p.x >= size.x - r.y && p.y <= r.y) {
        along = top + r.y * atan(max(p.x - size.x + r.y, 0.0),
            max(r.y - p.y, 0.00001));
    } else if (p.x >= size.x - r.z && p.y >= size.y - r.z) {
        along = bottomRightStart + r.z * atan(max(p.y - size.y + r.z, 0.0),
            max(p.x - size.x + r.z, 0.00001));
    } else if (p.x <= r.w && p.y >= size.y - r.w) {
        along = bottomLeftStart + r.w * atan(max(r.w - p.x, 0.0),
            max(p.y - size.y + r.w, 0.00001));
    } else if (p.x <= r.x && p.y <= r.x) {
        along = topLeftStart + r.x * atan(max(r.x - p.y, 0.0),
            max(r.x - p.x, 0.00001));
    } else if (p.y <= 0.0) {
        along = clamp(p.x - r.x, 0.0, top);
    } else if (p.x >= size.x) {
        along = rightStart + clamp(p.y - r.y, 0.0, size.y - r.y - r.z);
    } else if (p.y >= size.y) {
        along = bottomStart + clamp(size.x - r.z - p.x, 0.0, size.x - r.z - r.w);
    } else {
        along = leftStart + clamp(size.y - r.w - p.y, 0.0, size.y - r.w - r.x);
    }
    return vec2(along, perimeter);
}

vec4 border(vec2 uv) {
    vec4 native = umbriel_sample(uv);
    float ring = native.a;
    float borderDistance = umbriel_border_distance(uv);
    if (borderDistance < 0.0) {
        return native;
    }

    vec2 size = umbriel_border_hole.zw * umbriel_size;
    vec2 p = (uv - umbriel_border_hole.xy) * umbriel_size;
    float maxRadius = 0.5 * min(size.x, size.y);
    vec4 radius = clamp(umbriel_border_radius, vec4(0.0), vec4(maxRadius));
    vec2 position = orbit_position(p, size, radius);
    float along = position.x;
    float perimeter = position.y;

    // umbriel_time already includes the preset's speed multiplier.
    // Orbit by FRACTION of a lap instead of px: mod(t*600, P) scatters the head
    // every frame while the layout animates the window size (focus inherited
    // after a close, splits moving) — it reads as a crazy-fast spin until the
    // box settles. A fraction stays continuous through a changing perimeter
    // and is identical at constant size.
    float head = fract(umbriel_time * 100.0 / perimeter) * perimeter;
    float separation = abs(along - head);
    float distanceToHead = min(separation, perimeter - separation);
    float distanceToOpposite = 0.5 * perimeter - distanceToHead;
    float orbitDistance = min(distanceToHead, distanceToOpposite);
    float orbitIntensity = exp(-0.5 * pow(orbitDistance / 48.0, 2.0));

    // Umbriel's first two palette stops are accent_primary and accent_secondary.
    vec3 borderColor = umbriel_palette_at(0.0).rgb;
    vec3 orbitColor = umbriel_palette_at(0.25).rgb;
    // The head keeps the accent colour at its own brightness: brightening it
    // (the original x1.25) pushes a saturated accent towards a pale lavender,
    // and against the steady ring it reads as a washed pink instead of a hue.
    vec3 highlight = orbitColor;
    vec3 color = mix(borderColor * 0.72, highlight, orbitIntensity);

    // Widen the orbit beyond the native ring, then fade it into a softer halo.
    // The halo stays tight on purpose: spread wide and translucent, it mixes the
    // head with the steady ring and the compositor clips the result, and the
    // accent colour then reads washed out instead of as its own hue.
    float band = orbitIntensity * (1.0 - ring) * 0.95
        * (1.0 - smoothstep(5.0, 8.0, borderDistance));
    float halo = orbitIntensity * (1.0 - ring) * 0.42 * exp(-borderDistance / 3.0);
    float orbitAlpha = max(band, halo);

    // The preset's padding enlarges the draw area and moves the client hole.
    // Derive the fade reach from that inset so effect.toml controls it.
    float inset = min(umbriel_border_hole.x * umbriel_size.x,
        umbriel_border_hole.y * umbriel_size.y);
    float fadeEnd = max(3.1, inset * 0.5 - 1.0);
    float borderHalo = (1.0 - ring) * (1.0 - orbitIntensity) * 0.12
        * (1.0 - smoothstep(3.0, fadeEnd, borderDistance));
    float outerAlpha = max(orbitAlpha, borderHalo);
    vec3 outerColor = mix(borderColor, highlight, orbitIntensity);
    return vec4(color * ring + outerColor * outerAlpha, ring + outerAlpha);
}
