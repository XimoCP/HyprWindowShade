# Community border effects (Umbriel collection)

Adapted ports of the Umbriel community border-collection shaders, ready to load
with HyprWindowShade's border-shader dispatchers.

- Source: the Umbriel community shader collection (`border/` presets), MIT
  licensed by their respective authors (see the author table below and the
  upstream collection's `LICENSES/` directory).
- Each file is the upstream shader plus our port fixes, and exactly two
  HyprWindowShade directives prepended after `#version`:
  - `// @border <px>` — band width the effect paints; the plugin applies
    `general:border_size` to this on activation and restores the config value
    on clear.
  - `// @padding <px>` — the preset's declared padding (from its
    `effect.toml`), extra transparent space beyond the band.
- Excluded: `kzzzt-ring` and `spectrum` (they need a live audio feed this
  plugin does not provide).
- `dual-orbit` keeps its author-designed geometry (`@border 3`, `@padding 14`)
  verified live; the rest use a 6 px band.

Load with:

```
hyprctl dispatch 'function() hl.plugin.HyprWindowShade.activebordershader("<path>/effects/heartbeat.glsl") end'
```

Clear with `activebordershader("clear")` wrapped the same way (restores the
hve-owned config).

Calling the plugin action raw (`hyprctl dispatch 'hl.plugin...("...")'`) still
works, but Hyprland 0.57's lua config wraps every `hyprctl dispatch` into
`hl.dispatch(...)` (`src/ipc/s1/Commands.cpp:1338`), which only accepts a lua
function or dispatcher object — the action runs, its return value fails the
check, and Hyprland raises an "expected a dispatcher" notification every time.
Wrapping in `function() ... end` passes the type check and is silent.

| Effect | Author | License |
| --- | --- | --- |
| accent-pulse | Noctalia | MIT |
| arcane-hextech-filament | Barrulus | MIT |
| beach-surf | Barrulus | MIT |
| cartoon-chase | Barrulus | MIT |
| diya-lights | Barrulus | MIT |
| dual-orbit | neonvoidx | MIT |
| faerie-magic | Barrulus | MIT |
| flowering-vine | Barrulus | MIT |
| flowing-water | Barrulus | MIT |
| fractal-flow | Barrulus | MIT |
| fuse | Barrulus | MIT |
| ghostly-tear-border | Barrulus | MIT |
| heartbeat | WinterMyst | MIT |
| lightning | Barrulus | MIT |
| neon-bleed | Barrulus | MIT |
| paper | Barrulus | MIT |
| pink-ribbon | Barrulus | MIT |
| portal-lava | Barrulus | MIT |
| pulse | Barrulus | MIT |
| rainbow | Barrulus | MIT |
| sentient-runner | Barrulus | MIT |
| sentient-spark | Barrulus | MIT |
| somethings-watching | Barrulus | MIT |
