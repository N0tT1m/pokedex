"""Generates the Pokedex launcher icon (a Pokeball on a dark ground).

Run: python3 tool/generate_icon.py
Writes assets/icon/app_icon.png (1024x1024) and app_icon_foreground.png,
which flutter_launcher_icons consumes to produce every platform's icons.
"""
from PIL import Image, ImageDraw

S = 1024          # master canvas
SS = 4            # supersample factor for smooth edges
BG = (32, 36, 44)
RED = (238, 21, 21)
WHITE = (245, 245, 245)
BLACK = (26, 26, 26)


def ball(size, margin_ratio, background):
    """Draw a Pokeball centred on `size`, supersampled then downscaled."""
    n = size * SS
    img = Image.new("RGBA", (n, n), background)
    d = ImageDraw.Draw(img)

    m = int(n * margin_ratio)
    box = (m, m, n - m, n - m)
    r = (n - 2 * m) / 2
    cx = cy = n / 2
    band = r * 0.16          # thickness of the equator band
    ring = r * 0.34          # outer radius of the centre button

    # White base, then the red upper hemisphere.
    d.ellipse(box, fill=WHITE)
    d.pieslice(box, 180, 360, fill=RED)

    # Equator band across the full diameter.
    d.rectangle((cx - r, cy - band / 2, cx + r, cy + band / 2), fill=BLACK)

    # Outline the ball so it holds an edge on light backgrounds.
    d.ellipse(box, outline=BLACK, width=int(r * 0.075))

    # Centre button: black ring, white face.
    d.ellipse((cx - ring, cy - ring, cx + ring, cy + ring), fill=BLACK)
    d.ellipse((cx - ring * 0.62, cy - ring * 0.62,
               cx + ring * 0.62, cy + ring * 0.62), fill=WHITE)

    return img.resize((size, size), Image.LANCZOS)


import os
os.makedirs("assets/icon", exist_ok=True)

# Full-bleed icon: opaque ground, ball inset so it breathes.
ball(S, 0.14, BG).convert("RGB").save("assets/icon/app_icon.png")

# Adaptive-icon foreground: transparent, extra inset for Android's mask crop.
ball(S, 0.26, (0, 0, 0, 0)).save("assets/icon/app_icon_foreground.png")

print("wrote assets/icon/app_icon.png and app_icon_foreground.png")
