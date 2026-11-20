# Paired window overlays (inner halves of the border effects)

Adapted ports of the Umbriel community collection's window overlays. Each one
is the **inner half** of a border effect from `../effects/`: the border pass
paints the ring outside the window, the window pass paints the same effect
over the window's content, and the two are driven by the same clock.

- Source: the Umbriel community shader collection (`window/` presets), MIT
  licensed by their respective authors (see the table below and the upstream
  collection's `LICENSES/` directory).
- Each file is the upstream shader plus our port fixes, and the palette
  uniforms (`umbriel_palette_count`, `umbriel_palette[4]`) plus the same
  `umbriel_palette_at()` the border pass uses — without them the plugin does
  not inject the palette and the interior paints in its own colour.
- `portal-lava` and `neon-bleed` keep their own colours: they paint a hue
  sweep that a four-stop palette cannot carry.

See `../docs/paired-effects.md` for how to load a pair and the rules that keep
the two halves in sync.

| Overlay | Author | Licence |
| --- | --- | --- |
| beach-surf-overlay | Barrulus | MIT |
| cartoon-chase-overlay | Barrulus | MIT |
| diya-glow-overlay | Barrulus | MIT |
| faerie-magic-overlay | Barrulus | MIT |
| flowering-vine-overlay | Barrulus | MIT |
| fractal-flow-overlay | Barrulus | MIT |
| ghostly-tear-overlay | Barrulus | MIT |
| neon-bleed-overlay | Barrulus | MIT |
| paper-overlay | Barrulus | MIT |
| pink-ribbon-overlay | Barrulus | MIT |
| portal-lava-overlay | Barrulus | MIT |
| rainbow-overlay | Barrulus | MIT |
| somethings-watching-overlay | Barrulus | MIT |
