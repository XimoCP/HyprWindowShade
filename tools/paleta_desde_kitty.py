#!/usr/bin/env python3
"""paleta_desde_kitty — bridge the terminal's colors to HyprWindowShade's palette file.

Reads kitty's current theme (the file kitty.conf includes — Noctalia regenerates
it on theme changes) and writes ~/.config/hypr/shaders/umbriel/palette.txt in
Umbriel's stop order:

    accent_primary   = active_border_color  (the theme's accent; falls back to color2)
    accent_secondary = color5               (the theme's purple — the orbiting
                                             highlights of dual-orbit read this stop)
    warning          = color3               (amber — ANSI warning slot)
    error            = color1               (red — ANSI error slot)

Re-run after a theme change; hook it to the theme file's mtime to make it live.
"""
import re, sys, pathlib

KITTY = pathlib.Path.home() / ".config/kitty"
OUT = pathlib.Path.home() / ".config/hypr/shaders/umbriel/palette.txt"

def theme_path():
    # current-theme.conf is kitty's record of the applied theme — the most
    # direct source. Fall back to the theme include in kitty.conf.
    ct = KITTY / "current-theme.conf"
    if ct.exists():
        return ct
    conf = (KITTY / "kitty.conf").read_text(errors="ignore")
    m = re.search(r"^include\s+(\S*themes\S+)", conf, re.M)
    if m:
        p = KITTY / m.group(1)
        if p.exists():
            return p
    return None

def color(src, key):
    m = re.search(rf"^{key}\s+#([0-9a-fA-F]{{6}})", src, re.M)
    if not m:
        return None
    h = m.group(1)
    return tuple(int(h[i:i+2], 16) / 255.0 for i in (0, 2, 4)) + (1.0,)

def main():
    theme = theme_path()
    if not theme:
        sys.exit("no kitty theme file found (kitty.conf include or current-theme.conf)")
    src = theme.read_text(errors="ignore")
    stops = [
        ("accent_primary",   color(src, "active_border_color") or color(src, "color2")),
        ("accent_secondary", color(src, "color5")),
        ("warning",          color(src, "color3")),
        ("error",            color(src, "color1")),
    ]
    if any(c is None for _, c in stops):
        sys.exit(f"missing ANSI colors in {theme}")
    OUT.parent.mkdir(parents=True, exist_ok=True)
    lines = ["# Paleta del tema (orden Umbriel: accent_primary, accent_secondary, warning, error)",
             f"# generada desde la terminal: {theme}"]
    for name, (r, g, b, a) in stops:
        lines.append(f"{r:.3f} {g:.3f} {b:.3f} {a:.3f}  # {name}")
    OUT.write_text("\n".join(lines) + "\n")
    print(f"paleta escrita en {OUT} desde {theme}")

if __name__ == "__main__":
    main()
