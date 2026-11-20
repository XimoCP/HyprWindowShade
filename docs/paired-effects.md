# Paired effects: border shader + window overlay

Umbriel's border presets are **pairs**: a border effect painted on the ring
outside the window, plus a window overlay painted over its content, both
driven by the same clock. HyprWindowShade has both passes and this branch
carries the adapted collection.

```
effects/<name>.glsl            -> the outer half, loaded on the border pass
overlays/<name>-overlay.glsl    -> the inner half, loaded on the window pass
```

## Loading a pair

Both halves follow the focused window, so a pair teleports together when the
focus changes:

```lua
hl.plugin.HyprWindowShade.activebordershader("<path>/effects/flowering-vine.glsl")
hl.plugin.HyprWindowShade.activewindowshader("<path>/overlays/flowering-vine-overlay.glsl")
```

Clear either one with `"clear"`; it restores the user's `general:border_size`.

Under Hyprland 0.57's lua config, wrap `hyprctl dispatch` calls in a function
(`function() ... end`), otherwise every call raises an "expected a dispatcher"
notification even though the action ran.

## Rules for the inner half

These are the things that make the two halves agree. They are not optional:

- **Declare the palette.** The overlay must declare `umbriel_palette_count`
  and `umbriel_palette[4]` and use the same `umbriel_palette_at()` the border
  pass uses. If the overlay does not, the plugin never injects the palette and
  the inside paints in its own colour while the rim paints in the theme's.
- **Match `// @speed`.** The plugin premultiplies `umbriel_time` per shader, so
  an overlay without the border's `// @speed` runs its head at a different
  rate (measured: 2px offset with the same value, a visible drift without it).
- **Do not use the palette for a hue sweep.** An effect that sweeps colour
  across the rim (`neon-bleed`, `rainbow`) cannot carry the theme palette —
  four fixed stops do not carry a sweep — and using it pulled the two halves
  apart. `portal-lava` is untinted in both halves as well: its gradient is
  what gives it volume.
- **No hard-coded corner radius.** The window pass binds the host's real
  rounding (`umbriel_corner_radius`) and the border's hole radius
  (`umbriel_border_radius`), so the inner art follows the window's contour on
  any user's config.

## The pairs in this branch

| Border effect | Overlay |
|---|---|
| `beach-surf` | `beach-surf-overlay` |
| `cartoon-chase` | `cartoon-chase-overlay` |
| `diya-lights` | `diya-glow-overlay` |
| `faerie-magic` | `faerie-magic-overlay` |
| `flowering-vine` | `flowering-vine-overlay` |
| `fractal-flow` | `fractal-flow-overlay` |
| `ghostly-tear-border` | `ghostly-tear-overlay` |
| `neon-bleed` | `neon-bleed-overlay` |
| `paper` | `paper-overlay` |
| `pink-ribbon` | `pink-ribbon-overlay` |
| `portal-lava` | `portal-lava-overlay` |
| `rainbow` | `rainbow-overlay` |
| `somethings-watching` | `somethings-watching-overlay` |

The remaining effects in `effects/` are border-only (`dual-orbit` in
particular: its inner extension was dropped on purpose, the outer half is the
effect).

## Band width

`// @border <px>` is the size knob of each effect: the plugin applies it to
`general:border_size` on activation and restores the user's value on clear.
Most of the collection uses 6px; `lightning` 11, `fuse` 12, `portal-lava` 12
and `rainbow` 3. `dual-orbit` keeps its author-designed geometry (3 + 14 of
padding).

## The theme palette

Both passes read `~/.config/hypr/shaders/umbriel/palette.txt`: four lines of
`r g b a` in Umbriel's stop order (`accent_primary`, `accent_secondary`,
`warning`, `error`). The plugin re-reads it at start, after config reloads and
on a hot `mtime` watch, and falls back to a built-in palette when the file is
missing.

`tools/paleta_desde_kitty.py` is a template for that bridge: it writes the
file from the terminal's own colours. Any theme tool can do the same — the
contract is just four lines of `r g b a`.

## Known limits

- Hyprland's native band can show under the effect canvas when the effect's
  art is narrower than the native border (`portal-lava` self-caps at 10px with
  a 12px band).
- The palette path is fixed; making it configurable would be better.
- Pair sync at the corners depends on the rounding Hyprland reports per
  surface.

Authors and licences: `effects/NOTICE.md` and `overlays/NOTICE.md`; the MIT
texts are in `overlays/LICENSES/`.
