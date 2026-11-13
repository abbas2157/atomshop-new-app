#!/usr/bin/env python3
"""Render the Play Store feature graphic (1024 x 500) from the app's own brand.

    python3 tool/make_feature_graphic.py

Writes store/play/feature-graphic-<variant>.png.

Everything is drawn from assets already in the repo: the lockup in
assets/images/nav-logo.png and the Plus Jakarta Sans faces the app ships with.
Nothing is traced by hand, so the graphic stays in step with the brand.

Google crops this image differently in different Play surfaces, so the
headline sits left of centre and nothing important goes within SAFE px of an
edge. Text is kept large: at the size Play usually renders it, anything under
about 16px of the final 1024 is unreadable.
"""

from __future__ import annotations

import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont

W, H = 1024, 500
SS = 3  # supersample, then downscale once at the end
SAFE = 56

ROOT = Path(__file__).resolve().parent.parent
FONTS = ROOT / "assets/fonts"
OUT = ROOT / "store/play"

INK = (11, 20, 48)
PRIMARY = (39, 71, 199)
AMBER = (247, 169, 40)
WHITE = (255, 255, 255)
ON_DARK = (201, 209, 228)
BODY = (79, 91, 118)

HEADLINE = ["Buy now", "Pay in steps"]
SUBLINE = "Phones, ACs, bikes and more on easy monthly installments."
PILLS = ["No credit card", "Verified sellers", "Track every payment"]


def font(weight: str, size: int) -> ImageFont.FreeTypeFont:
    return ImageFont.truetype(str(FONTS / f"PlusJakartaSans-{weight}.ttf"), size * SS)


def lockup() -> tuple[Image.Image, Image.Image]:
    """(mark, wordmark) cropped out of the horizontal lockup.

    The lockup is one image, so the two halves are split at the widest empty
    column rather than at a hard-coded x, which survives the asset changing.
    """
    im = Image.open(ROOT / "assets/images/nav-logo.png").convert("RGBA")
    alpha = im.getchannel("A")
    cols = [alpha.crop((x, 0, x + 1, im.height)).getbbox() is not None for x in range(im.width)]

    runs, start = [], None
    for x, filled in enumerate(cols):
        if not filled and start is None:
            start = x
        elif filled and start is not None:
            runs.append((start, x))
            start = None
    inner = [r for r in runs if r[0] > 0]
    split = max(inner, key=lambda r: r[1] - r[0])[1] if inner else im.width // 3

    mark = im.crop((0, 0, split, im.height))
    word = im.crop((split, 0, im.width, im.height))
    return mark.crop(mark.getbbox()), word.crop(word.getbbox())


def top_line(src: Image.Image) -> Image.Image:
    """Just the ATOMSHOP.PK line of the wordmark.

    The lockup stacks "PAY IN STEPS" underneath it. At the size this graphic
    uses, that second line renders about six pixels tall and turns to mush,
    and the headline says it anyway.
    """
    alpha = src.getchannel("A")
    rows = [alpha.crop((0, y, src.width, y + 1)).getbbox() is not None for y in range(src.height)]
    for y in range(1, src.height):
        if rows[y - 1] and not rows[y]:
            return src.crop((0, 0, src.width, y))
    return src


def tinted(src: Image.Image, colour: tuple[int, int, int]) -> Image.Image:
    """Recolour artwork to a flat colour, keeping its alpha."""
    out = Image.new("RGBA", src.size, colour + (0,))
    out.putalpha(src.getchannel("A"))
    return out


def fitted(src: Image.Image, height: int) -> Image.Image:
    w = round(src.width * height / src.height)
    return src.resize((w, height), Image.LANCZOS)


def gradient(corners: tuple[tuple[int, int, int], ...]) -> Image.Image:
    """Smooth 2D gradient from four corner colours."""
    tiny = Image.new("RGB", (2, 2))
    tiny.putdata(list(corners))
    return tiny.resize((W * SS, H * SS), Image.BICUBIC)


def glow(canvas: Image.Image, centre: tuple[int, int], radius: int,
         colour: tuple[int, int, int], strength: int) -> None:
    """Soft radial light, composited additively enough to read as a bloom."""
    layer = Image.new("RGBA", canvas.size, colour + (0,))
    mask = Image.new("L", canvas.size, 0)
    ImageDraw.Draw(mask).ellipse(
        [centre[0] - radius, centre[1] - radius, centre[0] + radius, centre[1] + radius],
        fill=strength,
    )
    mask = mask.filter(ImageFilter.GaussianBlur(radius * 0.45))
    layer.putalpha(mask)
    canvas.alpha_composite(layer)


def orbits(canvas: Image.Image, centre: tuple[int, int], radius: int,
           colour: tuple[int, int, int], alpha: int) -> None:
    """The atom motif from the logo, as faint rings behind the mark."""
    layer = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    for rx, ry, angle in ((radius, round(radius * 0.42), 28),
                          (radius, round(radius * 0.42), -32),
                          (round(radius * 0.78), round(radius * 0.78), 0)):
        ring = Image.new("RGBA", (rx * 2 + 40, ry * 2 + 40), (0, 0, 0, 0))
        ImageDraw.Draw(ring).ellipse([20, 20, 20 + rx * 2, 20 + ry * 2],
                                     outline=colour + (alpha,), width=3 * SS)
        ring = ring.rotate(angle, resample=Image.BICUBIC, expand=True)
        layer.alpha_composite(ring, (centre[0] - ring.width // 2, centre[1] - ring.height // 2))
    del d
    canvas.alpha_composite(layer)


def squircle(size: int, radius: int, fill: tuple[int, int, int]) -> Image.Image:
    tile = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    ImageDraw.Draw(tile).rounded_rectangle([0, 0, size - 1, size - 1], radius=radius, fill=fill)
    return tile


def shadow(canvas: Image.Image, box: tuple[int, int, int, int], radius: int,
           blur: int, alpha: int) -> None:
    layer = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    ImageDraw.Draw(layer).rounded_rectangle(box, radius=radius, fill=(0, 0, 0, alpha))
    canvas.alpha_composite(layer.filter(ImageFilter.GaussianBlur(blur)))


def build(variant: str) -> Image.Image:
    dark = variant == "dark"

    if dark:
        canvas = gradient((
            (9, 16, 40), (22, 37, 92),
            (20, 33, 61), PRIMARY,
        )).convert("RGBA")
    else:
        canvas = gradient((
            (255, 255, 255), (238, 242, 253),
            (245, 247, 251), (223, 231, 250),
        )).convert("RGBA")

    mark_src, word_src = lockup()

    # The mark sits on a light tile on both variants: its own centre is near
    # black, which would vanish straight into the dark gradient.
    tile_px = 268
    cx, cy = round(W * 0.805) * SS, round(H * 0.50) * SS
    tile = tile_px * SS

    if dark:
        glow(canvas, (cx, cy), round(tile * 0.95), AMBER, 48)
        glow(canvas, (cx, cy), round(tile * 0.62), (120, 160, 255), 38)
        orbits(canvas, (cx, cy), round(tile * 0.86), WHITE, 34)
    else:
        glow(canvas, (cx, cy), round(tile * 0.9), AMBER, 40)
        orbits(canvas, (cx, cy), round(tile * 0.86), PRIMARY, 30)

    shadow(canvas, (cx - tile // 2, cy - tile // 2 + 10 * SS,
                    cx + tile // 2, cy + tile // 2 + 14 * SS),
           radius=round(tile * 0.26), blur=16 * SS, alpha=110 if dark else 46)
    canvas.alpha_composite(squircle(tile, round(tile * 0.26), WHITE),
                           (cx - tile // 2, cy - tile // 2))
    mark = fitted(mark_src, round(tile * 0.70))
    canvas.alpha_composite(mark, (cx - mark.width // 2, cy - mark.height // 2))

    draw = ImageDraw.Draw(canvas)
    x = SAFE * SS

    word = fitted(tinted(top_line(word_src), WHITE if dark else INK), 30 * SS)
    canvas.alpha_composite(word, (x, 60 * SS))

    y = 124 * SS
    f_head = font("ExtraBold", 59)
    for line in HEADLINE:
        draw.text((x, y), line, font=f_head, fill=WHITE if dark else INK)
        y += 68 * SS

    draw.text((x, 278 * SS), SUBLINE, font=font("Medium", 20),
              fill=ON_DARK if dark else BODY)

    # Accent rule, then the claims the app can actually back up.
    draw.rounded_rectangle([x, 332 * SS, x + 58 * SS, 337 * SS], radius=3 * SS, fill=AMBER)

    # Pills go on their own layer: ImageDraw writes RGBA straight into the
    # canvas instead of blending, so a translucent fill drawn directly would
    # punch a hole in the background and flatten to solid white.
    pills = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    pd = ImageDraw.Draw(pills)
    px, py, ph = x, 368 * SS, 42 * SS
    f_pill = font("SemiBold", 16)
    for label in PILLS:
        pw = round(pd.textlength(label, font=f_pill)) + 48 * SS
        pd.rounded_rectangle([px, py, px + pw, py + ph], radius=ph // 2,
                             fill=(255, 255, 255, 30) if dark else (255, 255, 255, 240),
                             outline=(255, 255, 255, 70) if dark else (214, 223, 240, 255),
                             width=max(1, SS))
        pd.ellipse([px + 18 * SS, py + ph // 2 - 4 * SS,
                    px + 26 * SS, py + ph // 2 + 4 * SS], fill=AMBER + (255,))
        pd.text((px + 34 * SS, py + ph // 2), label, font=f_pill,
                fill=WHITE + (255,) if dark else INK + (255,), anchor="lm")
        px += pw + 12 * SS
    canvas.alpha_composite(pills)

    return canvas.convert("RGB").resize((W, H), Image.LANCZOS)


def main() -> int:
    OUT.mkdir(parents=True, exist_ok=True)
    wanted = sys.argv[1:] or ["dark", "light"]
    for variant in wanted:
        path = OUT / f"feature-graphic-{variant}.png"
        build(variant).save(path, "PNG", optimize=True)
        kb = path.stat().st_size / 1024
        print(f"  {path.relative_to(ROOT)}  {W}x{H}  {kb:.0f} KB")
    return 0


if __name__ == "__main__":
    sys.exit(main())
