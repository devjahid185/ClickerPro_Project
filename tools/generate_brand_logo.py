# tools/generate_brand_logo.py
#
# CLICKER PRO brand mark — a RIGHT-ANCHORED 3D blade fan, matching the
# reference art and the landing-page hero: blades emanate from the right
# edge and sweep left, cream tips -> orange bodies, deep shadow under
# each blade, dark maroon backdrop.
#
# Outputs:
#   clicker_pro/assets/icon/app_icon.png        1024px, dark bg (launcher)
#   clicker_pro/assets/icon/app_icon_ios.png    1024px, dark bg (iOS, no alpha)
#   clicker_pro/assets/brand/logo_flower.png    1024px, TRANSPARENT bg (in-app)
#   web_app/public/favicon.ico                  multi-size site icon
#   web_app/public/logo_flower.png              512px transparent (web use)

import math
import os

from PIL import Image, ImageDraw, ImageFilter

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

S = 2048                       # master canvas
ANCHOR = (int(S * 1.04), S // 2)   # fan hub just off the right edge
BLADES = 17
SPREAD = 162                   # degrees of total fan spread
BLADE_LEN = int(S * 1.06)
BLADE_H = int(S * 0.105)

# palette sampled from the reference
TIP = (255, 244, 226)
LIGHT = (255, 169, 92)
BODY = (255, 110, 28)
DEEP = (178, 58, 6)
BASE = (84, 22, 3)
BG_TOP = (58, 18, 9)
BG_BOT = (24, 7, 3)


def lerp(a, b, t):
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(3))


def blade_color(t):
    """Horizontal gradient along the blade: cream tip (t=0) -> ember base."""
    if t < 0.18:
        return lerp(TIP, LIGHT, t / 0.18)
    if t < 0.45:
        return lerp(LIGHT, BODY, (t - 0.18) / 0.27)
    if t < 0.78:
        return lerp(BODY, DEEP, (t - 0.45) / 0.33)
    return lerp(DEEP, BASE, (t - 0.78) / 0.22)


def make_blade():
    """One horizontal blade pointing LEFT from the anchor, with 3D shading:
    bright crown along the top edge, darker belly along the bottom."""
    w, h = BLADE_LEN, BLADE_H
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    px = img.load()
    half = h / 2
    for x in range(w):
        t = x / w                      # 0 at left tip, 1 at base
        # width profile: pointed tip, swelling to full height by ~30%
        prof = min(1.0, (t / 0.30) ** 0.65) if t < 0.30 else 1.0
        bh = half * prof
        base_col = blade_color(t)
        for y in range(h):
            dy = (y - half) / max(bh, 1)
            if abs(dy) > 1:
                continue
            # vertical 3D shading: top edge bright, bottom edge dark
            shade = -dy                      # +1 top, -1 bottom
            col = base_col
            if shade > 0:
                col = lerp(base_col, (255, 255, 255), shade * 0.38 * (1 - t * 0.6))
            else:
                col = lerp(base_col, (0, 0, 0), -shade * 0.45)
            # soft anti-aliased edge
            edge = min(1.0, (1 - abs(dy)) * (bh * 0.35))
            px[x, y] = col + (int(255 * min(1.0, edge)),)
    return img


def blade_shadow(blade):
    alpha = blade.split()[3]
    sh = Image.new("RGBA", blade.size, (0, 0, 0, 0))
    sh.paste(Image.new("RGBA", blade.size, (5, 1, 0, 210)), mask=alpha)
    return sh.filter(ImageFilter.GaussianBlur(BLADE_H * 0.10))


def place(canvas, tile, angle):
    """Rotate `tile` about the fan anchor and composite onto canvas."""
    layer = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    # blade's right-center sits at the anchor
    layer.paste(tile, (ANCHOR[0] - tile.width, ANCHOR[1] - tile.height // 2), tile)
    layer = layer.rotate(angle, resample=Image.BICUBIC, center=ANCHOR)
    return Image.alpha_composite(canvas, layer)


def build_fan(background):
    blade = make_blade()
    shadow = blade_shadow(blade)
    fan = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    # draw bottom blade first, top last — each upper blade overlaps the
    # one below and drops its shadow onto it, like the reference
    for i in range(BLADES):
        frac = i / (BLADES - 1)
        angle = -SPREAD / 2 + frac * SPREAD   # bottom .. top
        fan = place(fan, shadow, angle - 3.6)
        fan = place(fan, blade, angle)

    if not background:
        return fan

    bg = Image.new("RGBA", (S, S))
    d = ImageDraw.Draw(bg)
    for y in range(S):
        d.line([(0, y), (S, y)], fill=lerp(BG_TOP, BG_BOT, y / S) + (255,))
    # warm halo behind the hub
    halo = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    hd = ImageDraw.Draw(halo)
    r = int(S * 0.55)
    hd.ellipse([ANCHOR[0] - r, ANCHOR[1] - r, ANCHOR[0] + r, ANCHOR[1] + r],
               fill=(255, 90, 20, 55))
    halo = halo.filter(ImageFilter.GaussianBlur(S * 0.08))
    bg = Image.alpha_composite(bg, halo)
    return Image.alpha_composite(bg, fan)


def save(img, path, size, mode="RGBA"):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    out = img.resize((size, size), Image.LANCZOS)
    if mode == "RGB":
        out = out.convert("RGB")
    out.save(path)
    print("wrote", path)


fan_dark = build_fan(background=True)
fan_mark = build_fan(background=False)

save(fan_dark, os.path.join(ROOT, "clicker_pro/assets/icon/app_icon.png"), 1024)
save(fan_dark, os.path.join(ROOT, "clicker_pro/assets/icon/app_icon_ios.png"), 1024, mode="RGB")
save(fan_mark, os.path.join(ROOT, "clicker_pro/assets/brand/logo_flower.png"), 1024)
save(fan_mark, os.path.join(ROOT, "web_app/public/logo_flower.png"), 512)

fav = fan_dark.resize((256, 256), Image.LANCZOS).convert("RGBA")
fav_path = os.path.join(ROOT, "web_app/public/favicon.ico")
fav.save(fav_path, sizes=[(16, 16), (32, 32), (48, 48), (64, 64)])
print("wrote", fav_path)
print("DONE")
