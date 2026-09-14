# Static itch.io page background: localthunk's Balatro swirl shader
# (https://www.playbalatro.com), ported to numpy, one frozen frame, recoloured with the
# 18-colour palette of Assets/Cutscene5Background.png and snapped to it for a pixel-art look.
# Run from the project root: python ItchPage/make_background.py
# ItchPage/.gdignore keeps Godot from importing (and exporting) anything in this folder.
import numpy as np
from PIL import Image

SOURCE = "Assets/Cutscene5Background.png"
OUT = "ItchPage/itch_background.png"
WIDTH, HEIGHT = 1920, 1080
PIXEL = 6              # screen pixels per art pixel (the cutscene art is shown at 4.6x)
TIME = 11.0            # which frame of the animation to freeze
SPIN_ROTATION = -2.0
SPIN_SPEED = 7.0
SPIN_AMOUNT = 0.55     # template: 0.25. Higher = tighter, trippier spiral
CONTRAST = 3.5
LIGHTING = 0.4
SPIN_EASE = 1.0


def hex_rgb(h):
    return np.array([int(h[i:i + 2], 16) / 255 for i in (1, 3, 5)])


COLOUR_1 = hex_rgb("#9bc7ec")   # light nebula blue   (template: red)
COLOUR_2 = hex_rgb("#323b8a")   # violet-blue         (template: blue)
COLOUR_3 = hex_rgb("#091f35")   # deep space navy     (template: near-black)


def palette():
    img = Image.open(SOURCE).convert("RGB")
    return np.array(sorted({p for p in img.getdata()}), dtype=float) / 255


def render(width=WIDTH, height=HEIGHT, pixel=PIXEL, time=TIME, spin_amount=SPIN_AMOUNT):
    bw, bh = -(-width // pixel), -(-height // pixel)
    # One sample per art pixel, at the block's corner like the shader's floor() snap.
    # Flipped so y points up, as in Shadertoy.
    x = np.arange(bw) * pixel
    y = (bh - 1 - np.arange(bh)) * pixel
    sx, sy = np.meshgrid(x, y)
    diag = np.hypot(width, height)
    ux = (sx - 0.5 * width) / diag
    uy = (sy - 0.5 * height) / diag
    uv_len = np.hypot(ux, uy)

    speed = SPIN_ROTATION * SPIN_EASE * 0.2 + 302.2
    angle = np.arctan2(uy, ux) + speed - SPIN_EASE * 20.0 * (spin_amount * uv_len + (1.0 - spin_amount))
    ux = uv_len * np.cos(angle) * 30.0
    uy = uv_len * np.sin(angle) * 30.0

    speed = time * SPIN_SPEED
    u2x = ux + uy
    u2y = ux + uy
    for _ in range(5):
        s = np.sin(np.maximum(ux, uy))
        u2x = u2x + s + ux
        u2y = u2y + s + uy
        ux = ux + 0.5 * np.cos(5.1123314 + 0.353 * u2y + speed * 0.131121)
        uy = uy + 0.5 * np.sin(u2x - 0.113 * speed)
        d = np.cos(ux + uy) - np.sin(ux * 0.711 - uy)
        ux, uy = ux - d, uy - d

    contrast_mod = 0.25 * CONTRAST + 0.5 * spin_amount + 1.2
    paint = np.clip(np.hypot(ux, uy) * 0.035 * contrast_mod, 0.0, 2.0)
    c1p = np.maximum(0.0, 1.0 - contrast_mod * np.abs(1.0 - paint))
    c2p = np.maximum(0.0, 1.0 - contrast_mod * np.abs(paint))
    c3p = 1.0 - np.minimum(1.0, c1p + c2p)
    light = (LIGHTING - 0.2) * np.maximum(c1p * 5.0 - 4.0, 0.0) + LIGHTING * np.maximum(c2p * 5.0 - 4.0, 0.0)
    rgb = ((0.3 / CONTRAST) * COLOUR_1
           + (1.0 - 0.3 / CONTRAST) * (c1p[..., None] * COLOUR_1 + c2p[..., None] * COLOUR_2 + c3p[..., None] * COLOUR_3)
           + light[..., None])
    rgb = np.clip(rgb, 0.0, 1.0)

    # Snap every art pixel to the nearest cutscene colour: no in-between shades, no dithering.
    pal = palette()
    nearest = ((rgb[..., None, :] - pal) ** 2).sum(-1).argmin(-1)
    art = (pal[nearest] * 255).astype(np.uint8)
    return Image.fromarray(art).resize((bw * pixel, bh * pixel), Image.NEAREST).crop((0, 0, width, height))


if __name__ == "__main__":
    render().save(OUT)
    print("wrote", OUT)
