#!/usr/bin/env python3
"""Compose store screenshots from raw device captures.

    python3 tool/make_store_screenshots.py play
    python3 tool/make_store_screenshots.py iphone 01-home
    python3 tool/make_store_screenshots.py ipad

Reads raw captures from store/<target>/raw/<slug>.png and writes finished
panels to store/<target>/screenshots/.

Each panel is a caption over the real screen, on the same gradient as the
feature graphic, so a set reads as one piece of work. The screen itself is
never redrawn or retouched: both stores require screenshots to show actual
in-app content, so the capture goes in as it came off the device.

Targets and why those sizes:
  play    1242x2208  9:16, and both sides clear the 1080 px Play wants
                     before it will consider an app for promotion.
  iphone  1206x2622  the 6.1"/6.3" slot in App Store Connect. That slot takes
                     only 1179x2556 or 1206x2622; the 6.9" sizes are rejected there.
  ipad    2064x2752  the 13" set, required because the app ships with
                     TARGETED_DEVICE_FAMILY = "1,2".

Layout is expressed as fractions of the canvas, so the three targets stay
visually consistent instead of needing three hand-tuned layouts.
"""

from __future__ import annotations

import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont

SS = 2

ROOT = Path(__file__).resolve().parent.parent
FONTS = ROOT / "assets/fonts"

AMBER = (247, 169, 40)
WHITE = (255, 255, 255)
ON_DARK = (201, 209, 228)

# name -> (width, height, device width as a fraction of canvas width, crop_top)
#
# crop_top removes the device status bar from the capture. The Android
# emulator carries a persistent settings-gear notification icon that no
# SystemUI demo command will hide, and a stray icon is exactly the kind of
# detail that makes a listing look unconsidered. The iOS simulator already
# renders a clean 9:41 bar, so its captures go in whole.
TARGETS: dict[str, tuple[int, int, float, int]] = {
    "play":   (1242, 2208, 0.734, 156),
    "iphone": (1206, 2622, 0.734, 0),
    "ipad":   (2064, 2752, 0.800, 0),
}

# slug, headline (\n breaks the line), supporting line
PANELS: list[tuple[str, str, str]] = [
    ("01-home",    "Buy now\nPay in steps",      "Phones, ACs, bikes and more on easy monthly installments."),
    ("02-product", "See the monthly\namount first", "Advance, monthly amount and total, before you order."),
    ("03-plans",   "Track every\ninstallment",      "Active, pending and completed plans, with a receipt for each payment."),
    ("04-atompay", "0% markup\nwith AtomPay",       "Get your limit once, then pay over 3 months with no advance."),
    ("05-custom",  "Want it from\nany shop?",       "Enter the price and see the monthly plan straight away."),
    ("06-offer",   "Not sure of\nthe price?",       "Tell us what you want and a verified seller calls you back."),
    ("07-offline", "Works without\na signal",       "We save it on your phone and send it when you are back online."),
    ("08-sellers", "Verified sellers\nnear you",    "Every seller is checked in person before they can take an order."),
]


def font(weight: str, px: int) -> ImageFont.FreeTypeFont:
    return ImageFont.truetype(str(FONTS / f"PlusJakartaSans-{weight}.ttf"), max(1, px))


def background(w: int, h: int, device_top: int) -> Image.Image:
    tiny = Image.new("RGB", (2, 2))
    tiny.putdata([(9, 16, 40), (22, 37, 92), (20, 33, 61), (39, 71, 199)])
    canvas = tiny.resize((w, h), Image.BICUBIC).convert("RGBA")

    # One warm highlight behind the device, echoing the feature graphic.
    halo = Image.new("RGBA", canvas.size, AMBER + (0,))
    mask = Image.new("L", canvas.size, 0)
    r = round(w * 0.78)
    cy = device_top + round(h * 0.19)
    ImageDraw.Draw(mask).ellipse([w // 2 - r, cy - r, w // 2 + r, cy + r], fill=42)
    halo.putalpha(mask.filter(ImageFilter.GaussianBlur(r * 0.42)))
    canvas.alpha_composite(halo)
    return canvas


def rounded(src: Image.Image, radius: int) -> Image.Image:
    mask = Image.new("L", src.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, src.width - 1, src.height - 1],
                                           radius=radius, fill=255)
    out = src.convert("RGBA")
    out.putalpha(mask)
    return out


def wrap(draw: ImageDraw.ImageDraw, text: str, f: ImageFont.FreeTypeFont,
         limit: float) -> list[str]:
    lines, line = [], ""
    for word in text.split():
        trial = f"{line} {word}".strip()
        if draw.textlength(trial, font=f) > limit and line:
            lines.append(line)
            line = word
        else:
            line = trial
    lines.append(line)
    return lines


def build(target: str, slug: str, headline: str, sub: str) -> Image.Image | None:
    source = ROOT / f"store/{target}/raw/{slug}.png"
    if not source.exists():
        return None

    tw, th, device_frac, crop_top = TARGETS[target]
    w, h = tw * SS, th * SS

    margin = round(w * 0.0676)
    head_px = round(w * 0.0596)
    lead = round(head_px * 1.19)
    sub_px = round(w * 0.0250)
    device_w = round(w * device_frac)
    corner = round(w * 0.0419)

    f_head = font("ExtraBold", head_px)
    f_sub = font("Medium", sub_px)

    # Lay the caption out on its own layer first, so the device can be placed
    # below whatever height it actually came to. A fixed device offset works
    # at phone proportions and collides with the caption on the squarer iPad
    # canvas, where the same fractions give a much taller caption block.
    caption = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(caption)

    y = round(h * 0.0679)
    for line in headline.split("\n"):
        draw.text((margin, y), line, font=f_head, fill=WHITE)
        y += lead

    rule_y = y + round(head_px * 0.24)
    draw.rounded_rectangle(
        [margin, rule_y, margin + round(w * 0.0515), rule_y + round(w * 0.0048)],
        radius=round(w * 0.0024), fill=AMBER)

    ty = y + round(head_px * 0.78)
    for line in wrap(draw, sub, f_sub, w - margin * 2):
        draw.text((margin, ty), line, font=f_sub, fill=ON_DARK)
        ty += round(sub_px * 1.42)

    device_top = max(round(h * 0.2129), ty + round(h * 0.030))

    canvas = background(w, h, device_top)

    shot = Image.open(source).convert("RGB")
    if crop_top:
        shot = shot.crop((0, crop_top, shot.width, shot.height))
    shot = shot.resize((device_w, round(shot.height * device_w / shot.width)), Image.LANCZOS)
    shot = rounded(shot, corner)

    left, top = (w - shot.width) // 2, device_top

    glow = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    ImageDraw.Draw(glow).rounded_rectangle(
        [left, top + round(h * 0.008), left + shot.width, top + shot.height],
        radius=corner, fill=(0, 0, 0, 150))
    canvas.alpha_composite(glow.filter(ImageFilter.GaussianBlur(round(w * 0.021))))
    canvas.alpha_composite(shot, (left, top))

    # Hairline, so a light screen does not bleed into the background.
    edge = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    ImageDraw.Draw(edge).rounded_rectangle(
        [left, top, left + shot.width - 1, top + shot.height - 1],
        radius=corner, outline=(255, 255, 255, 56), width=max(2, round(w * 0.0016)))
    canvas.alpha_composite(edge)

    canvas.alpha_composite(caption)
    return canvas.convert("RGB").resize((tw, th), Image.LANCZOS)


def main(argv: list[str]) -> int:
    if len(argv) < 2 or argv[1] not in TARGETS:
        print(f"Usage: {Path(argv[0]).name} {{{'|'.join(TARGETS)}}} [slug ...]", file=sys.stderr)
        return 2

    target = argv[1]
    wanted = set(argv[2:])
    out = ROOT / f"store/{target}/screenshots"
    out.mkdir(parents=True, exist_ok=True)

    tw, th, _, _ = TARGETS[target]
    made, missing = 0, []
    for slug, headline, sub in PANELS:
        if wanted and slug not in wanted:
            continue
        image = build(target, slug, headline, sub)
        if image is None:
            missing.append(slug)
            continue
        path = out / f"{slug}.png"
        image.save(path, "PNG", optimize=True)
        print(f"  {path.relative_to(ROOT)}  {tw}x{th}  {path.stat().st_size / 1024:.0f} KB")
        made += 1

    if missing:
        print(f"\nNo capture yet for: {', '.join(missing)}")
        print(f"Put them in store/{target}/raw/<slug>.png")
    print(f"\n{made} panel(s) written.")
    if made and made < 4 and target == "play":
        print("Play wants at least 4 before it will consider the app for promotion.")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
