# -*- coding: utf-8 -*-
"""Kit de rendu des maquettes ShopShop - charte ShopShop / look Power BI."""
from PIL import Image, ImageDraw, ImageFont, ImageFilter

SS = 2                       # supersampling
W, H = 1600, 900

# --- charte -------------------------------------------------------------------
BG      = (248, 249, 250)
CARD    = (255, 255, 255)
BORDER  = (218, 221, 225)
RED     = (204, 0, 0)
TEAL    = (63, 173, 161)
AMBER   = (232, 163, 61)
CRIMSON = (204, 32, 71)
INK     = (43, 43, 43)
BODY    = (67, 67, 67)
MUTED   = (154, 154, 154)
GRID    = (236, 238, 240)
SOFT    = (245, 246, 247)

FONTS = {
    "l":  "C:/Windows/Fonts/segoeuil.ttf",
    "r":  "C:/Windows/Fonts/segoeui.ttf",
    "sb": "C:/Windows/Fonts/seguisb.ttf",
    "b":  "C:/Windows/Fonts/segoeuib.ttf",
}
_cache = {}
def f(size, weight="r"):
    k = (size, weight)
    if k not in _cache:
        _cache[k] = ImageFont.truetype(FONTS[weight], int(size * SS))
    return _cache[k]

def s(v):            # scale
    return int(round(v * SS))

def mix(c1, c2, t):
    return tuple(int(round(a + (b - a) * t)) for a, b in zip(c1, c2))

def fade(color, t):  # vers le blanc
    return mix(color, (255, 255, 255), t)

def money(v, dec=0):
    return ("{:,.%df}" % dec).format(v).replace(",", "\u00a0").replace(".", ",")

# --- primitives ---------------------------------------------------------------
class Canvas:
    def __init__(self, w=W, h=H, bg=BG):
        self.img = Image.new("RGB", (s(w), s(h)), bg)
        self.d = ImageDraw.Draw(self.img)

    def text(self, x, y, txt, size=12, weight="r", fill=BODY, anchor="la", spacing=0):
        if spacing:
            fo = f(size, weight)
            ws = [self.d.textlength(ch, font=fo) for ch in txt]
            total = sum(ws) + s(spacing) * max(len(txt) - 1, 0)
            cx = s(x)
            if anchor[0] == "r":
                cx -= total
            elif anchor[0] == "m":
                cx -= total / 2
            va = "l" + (anchor[1] if len(anchor) > 1 else "a")
            for ch, cw in zip(txt, ws):
                self.d.text((cx, s(y)), ch, font=fo, fill=fill, anchor=va)
                cx += cw + s(spacing)
            return
        self.d.text((s(x), s(y)), txt, font=f(size, weight), fill=fill, anchor=anchor)

    def tw(self, txt, size=12, weight="r"):
        return self.d.textlength(txt, font=f(size, weight)) / SS

    def rrect(self, x, y, w, h, r=8, fill=None, outline=None, width=1):
        self.d.rounded_rectangle([s(x), s(y), s(x + w), s(y + h)], radius=s(r),
                                 fill=fill, outline=outline, width=s(width))

    def rect(self, x, y, w, h, fill=None, outline=None, width=1):
        self.d.rectangle([s(x), s(y), s(x + w), s(y + h)], fill=fill,
                         outline=outline, width=s(width))

    def line(self, pts, fill=BODY, width=1):
        self.d.line([(s(a), s(b)) for a, b in pts], fill=fill, width=s(width), joint="curve")

    def dash(self, pts, fill=MUTED, width=1, on=7, off=5):
        for i in range(len(pts) - 1):
            (x1, y1), (x2, y2) = pts[i], pts[i + 1]
            dx, dy = x2 - x1, y2 - y1
            ln = (dx * dx + dy * dy) ** .5
            if ln == 0:
                continue
            ux, uy, t = dx / ln, dy / ln, 0.0
            while t < ln:
                e = min(t + on, ln)
                self.line([(x1 + ux * t, y1 + uy * t), (x1 + ux * e, y1 + uy * e)], fill, width)
                t = e + off

    def dot(self, x, y, r, fill, outline=None, width=2):
        self.d.ellipse([s(x - r), s(y - r), s(x + r), s(y + r)], fill=fill,
                       outline=outline, width=s(width))

    def shadow(self, x, y, w, h, r=8, blur=7, alpha=26, dy=2):
        lay = Image.new("RGBA", self.img.size, (0, 0, 0, 0))
        ImageDraw.Draw(lay).rounded_rectangle(
            [s(x), s(y + dy), s(x + w), s(y + h + dy)], radius=s(r), fill=(40, 45, 55, alpha))
        lay = lay.filter(ImageFilter.GaussianBlur(s(blur)))
        self.img.paste(Image.alpha_composite(self.img.convert("RGBA"), lay).convert("RGB"), (0, 0))
        self.d = ImageDraw.Draw(self.img)

    def fillpoly(self, pts, color, alpha):
        lay = Image.new("RGBA", self.img.size, (0, 0, 0, 0))
        ImageDraw.Draw(lay).polygon([(s(a), s(b)) for a, b in pts], fill=color + (alpha,))
        self.img = Image.alpha_composite(self.img.convert("RGBA"), lay).convert("RGB")
        self.d = ImageDraw.Draw(self.img)

    def arc(self, cx, cy, r, w, a0, a1, fill):
        self.d.arc([s(cx - r), s(cy - r), s(cx + r), s(cy + r)],
                   a0, a1, fill=fill, width=s(w))

    def save(self, path):
        self.img.resize((W, H), Image.LANCZOS).save(path, "PNG", optimize=True)

# --- blocs de haut niveau -----------------------------------------------------
def card(c, x, y, w, h, title=None, sub=None, r=8):
    c.shadow(x, y, w, h, r)
    c.rrect(x, y, w, h, r, fill=CARD, outline=BORDER, width=1)
    if title:
        c.text(x + 18, y + 15, title, 13.5, "sb", INK)
    if sub:
        c.text(x + w - 18, y + 17, sub, 10.5, "r", MUTED, anchor="ra")
    return x + 18, y + (46 if title else 16), w - 36, h - (62 if title else 32)

def kpi(c, x, y, w, h, eyebrow, value, note, accent=RED, note_color=MUTED):
    c.shadow(x, y, w, h, 8)
    c.rrect(x, y, w, h, 8, fill=CARD, outline=BORDER, width=1)
    c.d.rounded_rectangle([s(x), s(y + 10), s(x + 4), s(y + h - 10)], radius=s(2), fill=accent)
    c.text(x + 20, y + 16, eyebrow.upper(), 9.5, "b", TEAL, spacing=1.2)
    c.text(x + 20, y + 33, value, 31, "sb", accent)
    c.text(x + 20, y + h - 26, note, 10.5, "r", note_color)

def axis_steps(vmax, n=4):
    import math
    raw = vmax / n
    mag = 10 ** math.floor(math.log10(raw))
    step = next(m * mag for m in (1, 2, 2.5, 5, 10) if m * mag >= raw)
    return step, step * n
