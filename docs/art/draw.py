import math
import random
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

OUT = Path(__file__).resolve().parent
FONT = "/System/Library/Fonts/Supplemental/Comic Sans MS.ttf"
FONT_BOLD = "/System/Library/Fonts/Supplemental/Comic Sans MS Bold.ttf"

WHITE = (255, 255, 255)
BLACK = (0, 0, 0)
RED = (255, 0, 0)
GREEN = (0, 255, 0)
BLUE = (0, 0, 255)
YELLOW = (255, 255, 0)
CYAN = (0, 255, 255)
MAGENTA = (255, 0, 255)
ORANGE = (255, 128, 0)
PURPLE = (128, 0, 255)
RAINBOW = [RED, ORANGE, YELLOW, GREEN, CYAN, BLUE, MAGENTA]

PIXEL_SIZE = 2
LINE = 2


def new_canvas(w, h, seed):
    random.seed(seed)
    return Image.new("RGB", (w // PIXEL_SIZE, h // PIXEL_SIZE), WHITE)


def save(img, name):
    big = img.resize((img.width * PIXEL_SIZE, img.height * PIXEL_SIZE), Image.NEAREST)
    big.quantize(colors=32, method=Image.Quantize.MEDIANCUT, dither=Image.Dither.NONE).save(
        OUT / name, optimize=True
    )


def wobble(n=1.2):
    return random.uniform(-n, n)


def shaky_line(img, p0, p1, color=BLACK, width=LINE, wobble_by=1.2):
    (x0, y0), (x1, y1) = p0, p1
    steps = max(2, int(math.dist(p0, p1) / 7))
    pts = [(x0, y0)]
    for i in range(1, steps):
        t = i / steps
        pts.append((x0 + (x1 - x0) * t + wobble(wobble_by), y0 + (y1 - y0) * t + wobble(wobble_by)))
    pts.append((x1, y1))
    ImageDraw.Draw(img).line(pts, fill=color, width=width, joint="curve")


def shaky_path(img, pts, color=BLACK, width=LINE, closed=False, wobble_by=1.2):
    pts = list(pts) + ([pts[0]] if closed else [])
    for a, b in zip(pts, pts[1:]):
        shaky_line(img, a, b, color, width, wobble_by)


def bucket_fill(img, pts, color):
    cx = sum(p[0] for p in pts) / len(pts)
    cy = sum(p[1] for p in pts) / len(pts)
    shrink = random.uniform(0.82, 0.93)
    dx, dy = wobble(2), wobble(2)
    missed = [(cx + (x - cx) * shrink + dx + wobble(1.5), cy + (y - cy) * shrink + dy + wobble(1.5)) for x, y in pts]
    ImageDraw.Draw(img).polygon(missed, fill=color)


def shaky_box(img, box, fill=None, color=BLACK, width=LINE):
    x0, y0, x1, y1 = box
    if fill:
        inset = [random.randint(2, 5) for _ in range(4)]
        ImageDraw.Draw(img).polygon(
            [
                (x0 + inset[0], y0 + inset[1] + wobble(2)),
                (x1 - inset[2], y0 + inset[1] + wobble(2)),
                (x1 - inset[2], y1 - inset[3] + wobble(2)),
                (x0 + inset[0], y1 - inset[3] + wobble(2)),
            ],
            fill=fill,
        )
    overshoot = 3
    shaky_line(img, (x0 - overshoot, y0 + wobble(2)), (x1 + wobble(2), y0 + wobble(1)), color, width)
    shaky_line(img, (x1 + wobble(1), y0 - overshoot), (x1 + wobble(1), y1 + wobble(2)), color, width)
    shaky_line(img, (x1 + overshoot, y1 + wobble(1)), (x0 + wobble(2), y1 + wobble(1)), color, width)
    shaky_line(img, (x0 + wobble(1), y1 + overshoot), (x0 + wobble(1), y0 - wobble(2)), color, width)


def ellipse_points(cx, cy, rx, ry, n=28, rough=1.5):
    return [
        (cx + (rx + wobble(rough)) * math.cos(2 * math.pi * i / n), cy + (ry + wobble(rough)) * math.sin(2 * math.pi * i / n))
        for i in range(n)
    ]


def shaky_ellipse(img, cx, cy, rx, ry, fill=None, color=BLACK, width=LINE):
    pts = ellipse_points(cx, cy, rx, ry)
    if fill:
        bucket_fill(img, pts, fill)
    ImageDraw.Draw(img).line(pts + pts[:2], fill=color, width=width, joint="curve")


def scribble_circle(img, cx, cy, rx, ry, color=RED, width=LINE):
    for lap in range(2):
        start = random.uniform(0, 1)
        pts = [
            (
                cx + (rx + lap * 3 + wobble(2.5)) * math.cos(2 * math.pi * (start + i / 30)),
                cy + (ry + lap * 2 + wobble(2.5)) * math.sin(2 * math.pi * (start + i / 30)),
            )
            for i in range(34)
        ]
        ImageDraw.Draw(img).line(pts, fill=color, width=width, joint="curve")


def arrow(img, p0, p1, color=RED, width=LINE + 1, head=12):
    shaky_line(img, p0, p1, color, width, wobble_by=2)
    angle = math.atan2(p1[1] - p0[1], p1[0] - p0[0])
    for side in (-1, 1):
        a = angle + math.pi - side * 0.5
        shaky_line(img, p1, (p1[0] + head * math.cos(a), p1[1] + head * math.sin(a)), color, width)


def curvy_arrow(img, p0, p1, bend=30, color=RED, width=LINE + 1, head=12):
    mx, my = (p0[0] + p1[0]) / 2, (p0[1] + p1[1]) / 2 - bend
    pts = []
    for i in range(13):
        t = i / 12
        pts.append(
            (
                (1 - t) ** 2 * p0[0] + 2 * (1 - t) * t * mx + t**2 * p1[0] + wobble(1.5),
                (1 - t) ** 2 * p0[1] + 2 * (1 - t) * t * my + t**2 * p1[1] + wobble(1.5),
            )
        )
    ImageDraw.Draw(img).line(pts, fill=color, width=width, joint="curve")
    angle = math.atan2(p1[1] - pts[-3][1], p1[0] - pts[-3][0])
    for side in (-1, 1):
        a = angle + math.pi - side * 0.5
        shaky_line(img, p1, (p1[0] + head * math.cos(a), p1[1] + head * math.sin(a)), color, width)


def spray(img, cx, cy, radius, color, dots=90):
    d = ImageDraw.Draw(img)
    for _ in range(dots):
        r = radius * math.sqrt(random.random())
        a = random.uniform(0, 2 * math.pi)
        d.point((cx + r * math.cos(a), cy + r * math.sin(a)), fill=color)


def text_mask(text, size, bold):
    font = ImageFont.truetype(FONT_BOLD if bold else FONT, size)
    arrow_w = int(size * 0.9)
    runs = text.split("→")
    ascent, descent = font.getmetrics()
    total = sum(int(font.getlength(run)) + 1 for run in runs) + arrow_w * (len(runs) - 1)
    mask = Image.new("L", (total + 8, ascent + descent + 8), 0)
    d = ImageDraw.Draw(mask)
    d.fontmode = "1"
    x = 4
    mid = 4 + ascent * 0.62
    stroke = max(1, size // 8)
    for i, run in enumerate(runs):
        if i:
            tip = x + arrow_w - 3
            d.line([(x + 2, mid), (tip, mid)], fill=255, width=stroke)
            d.line([(tip, mid), (tip - size // 4, mid - size // 5)], fill=255, width=stroke)
            d.line([(tip, mid), (tip - size // 4, mid + size // 5)], fill=255, width=stroke)
            x += arrow_w
        d.text((x, 4), run, font=font, fill=255)
        x += int(font.getlength(run)) + 1
    return mask.crop(mask.getbbox())


def text_tilted(img, xy, text, size, color=BLACK, angle=0.0, bold=False, anchor="center"):
    mask = text_mask(text, size, bold).rotate(angle, resample=Image.NEAREST, expand=True)
    x, y = xy
    if anchor == "center":
        x -= mask.width // 2
    y -= mask.height // 2
    img.paste(color, (int(x), int(y)), mask)
    return mask.width


def rainbow_text(img, xy, text, size, start=0):
    x, y = xy
    for i, ch in enumerate(text):
        if ch == " ":
            x += size * 0.35
            continue
        color = RAINBOW[(start + i) % len(RAINBOW)]
        angle = random.uniform(-10, 10)
        dy = random.uniform(-size * 0.06, size * 0.06)
        mask = text_mask(ch, size, bold=True).rotate(angle, resample=Image.NEAREST, expand=True)
        img.paste(BLACK, (int(x + 3), int(y + dy - mask.height // 2 + 3)), mask)
        img.paste(color, (int(x), int(y + dy - mask.height // 2)), mask)
        x += mask.width + size * 0.05
    return x


def underline_scribble(img, x0, x1, y, color=RED):
    pts = [(x, y + 2 * math.sin(x / 9) + wobble(1)) for x in range(int(x0), int(x1), 6)]
    ImageDraw.Draw(img).line(pts, fill=color, width=LINE + 1, joint="curve")


def sun(img, cx, cy, r):
    for i in range(10):
        a = 2 * math.pi * i / 10 + wobble(0.1)
        shaky_line(
            img,
            (cx + (r + 6) * math.cos(a), cy + (r + 6) * math.sin(a)),
            (cx + (r + 17) * math.cos(a), cy + (r + 17) * math.sin(a)),
            ORANGE,
            LINE + 1,
        )
    ImageDraw.Draw(img).polygon(ellipse_points(cx, cy, r, r, rough=1), fill=YELLOW)
    e = r * 0.35
    shaky_path(img, [(cx - e - 4, cy - 3), (cx - e, cy - 7), (cx - e + 4, cy - 3)], BLACK, 1)
    shaky_path(img, [(cx + e - 4, cy - 3), (cx + e, cy - 7), (cx + e + 4, cy - 3)], BLACK, 1)
    ImageDraw.Draw(img).arc((cx - e, cy - e * 0.6, cx + e, cy + e), 20, 160, fill=BLACK, width=LINE)


def stick_figure(img, x, y, h=60, color=BLACK, wave=False):
    head = h * 0.17
    shaky_ellipse(img, x, y + head, head, head, color=color)
    d = ImageDraw.Draw(img)
    d.point([(x - head * 0.4, y + head * 0.8), (x + head * 0.4, y + head * 0.8)], fill=color)
    d.arc((x - head * 0.5, y + head * 0.6, x + head * 0.5, y + head * 1.5), 20, 160, fill=color, width=1)
    neck, hip = y + head * 2, y + h * 0.65
    shaky_line(img, (x, neck), (x, hip), color)
    arm_y = neck + h * 0.12
    shaky_line(img, (x, arm_y), (x - h * 0.28, arm_y + h * 0.15), color)
    shaky_line(img, (x, arm_y), (x + h * 0.28, arm_y - (h * 0.25 if wave else -h * 0.15)), color)
    shaky_line(img, (x, hip), (x - h * 0.2, y + h), color)
    shaky_line(img, (x, hip), (x + h * 0.2, y + h), color)


def cat(img, x, y, s=1.0, fill=ORANGE):
    r = 16 * s
    shaky_path(img, [(x - r * 0.9, y - r * 0.3), (x - r * 0.75, y - r * 1.5), (x - r * 0.15, y - r * 0.85)], closed=True)
    shaky_path(img, [(x + r * 0.9, y - r * 0.3), (x + r * 0.75, y - r * 1.5), (x + r * 0.15, y - r * 0.85)], closed=True)
    shaky_ellipse(img, x, y, r, r * 0.9, fill=fill)
    d = ImageDraw.Draw(img)
    d.rectangle((x - r * 0.45, y - r * 0.25, x - r * 0.3, y - r * 0.05), fill=BLACK)
    d.rectangle((x + r * 0.3, y - r * 0.25, x + r * 0.45, y - r * 0.05), fill=BLACK)
    d.polygon([(x - 2 * s, y + r * 0.15), (x + 2 * s, y + r * 0.15), (x, y + r * 0.3)], fill=MAGENTA)
    for side in (-1, 1):
        for dy in (-2, 3):
            shaky_line(img, (x + side * r * 0.25, y + r * 0.35), (x + side * r * 1.45, y + r * 0.3 + dy * s), BLACK, 1, 0.6)
    body_top, body_bot = y + r, y + r * 2.6
    shaky_line(img, (x, body_top), (x + r * 1.6, body_top + r * 0.3))
    for lx in (x + r * 0.1, x + r * 1.5):
        shaky_line(img, (lx, body_top + r * 0.1), (lx - r * 0.25, body_bot))
        shaky_line(img, (lx, body_top + r * 0.1), (lx + r * 0.25, body_bot))
    shaky_path(img, [(x + r * 1.6, body_top + r * 0.3), (x + r * 2.3, body_top - r * 0.3), (x + r * 2.1, body_top - r * 1.1)])


def dog(img, x, y, s=1.0, fill=WHITE):
    r = 16 * s
    shaky_ellipse(img, x, y, r, r * 0.95, fill=fill)
    for side in (-1, 1):
        ear = [(x + side * r * 0.7, y - r * 0.8), (x + side * r * 1.45, y - r * 0.2), (x + side * r * 1.2, y + r * 0.7), (x + side * r * 0.85, y)]
        bucket_fill(img, ear, BLACK)
        shaky_path(img, ear, closed=True)
    d = ImageDraw.Draw(img)
    d.rectangle((x - r * 0.45, y - r * 0.3, x - r * 0.28, y - r * 0.1), fill=BLACK)
    d.rectangle((x + r * 0.28, y - r * 0.3, x + r * 0.45, y - r * 0.1), fill=BLACK)
    shaky_ellipse(img, x, y + r * 0.25, r * 0.22, r * 0.15, fill=BLACK)
    tongue = [(x - r * 0.2, y + r * 0.55), (x + r * 0.2, y + r * 0.55), (x + r * 0.15, y + r * 1.05), (x - r * 0.15, y + r * 1.05)]
    bucket_fill(img, tongue, RED)
    shaky_path(img, tongue, RED, 1, closed=True)
    body_top, body_bot = y + r, y + r * 2.6
    shaky_line(img, (x - r * 0.1, body_top), (x - r * 1.8, body_top + r * 0.3))
    for lx in (x - r * 0.2, x - r * 1.7):
        shaky_line(img, (lx, body_top + r * 0.1), (lx - r * 0.25, body_bot))
        shaky_line(img, (lx, body_top + r * 0.1), (lx + r * 0.25, body_bot))
    shaky_line(img, (x - r * 1.8, body_top + r * 0.3), (x - r * 2.5, body_top - r * 0.5))
    for i in range(3):
        shaky_line(img, (x - r * 2.9 - i * 3, body_top - r * (0.9 - i * 0.35)), (x - r * 2.65 - i * 3, body_top - r * (0.8 - i * 0.35)), BLACK, 1)


def computer_mouse(img, cx, cy, w, h, light, glow=True):
    if glow:
        for lap, (ring, length) in enumerate(((h * 0.12 + 4, h * 0.09 + 3), (h * 0.28 + 4, h * 0.07 + 3))):
            for i in range(14):
                a = 2 * math.pi * (i + 0.5 * lap) / 14 + wobble(0.08)
                rx, ry = w / 2 + ring, h / 2 + ring
                shaky_line(
                    img,
                    (cx + rx * math.cos(a), cy + ry * math.sin(a)),
                    (cx + (rx + length) * math.cos(a), cy + (ry + length) * math.sin(a)),
                    light,
                    LINE + 1,
                )
    top, cord = cy - h / 2, h * 0.4
    shaky_path(img, [(cx, top), (cx + w * 0.1, top - cord * 0.35), (cx - w * 0.08, top - cord * 0.65), (cx + w * 0.06, top - cord)])
    body = [
        (cx + w / 2 * math.sin(t) * (0.82 + 0.18 * math.sin(t / 2)), cy - h / 2 * math.cos(t))
        for t in [2 * math.pi * i / 30 for i in range(30)]
    ]
    bucket_fill(img, body, light)
    shaky_path(img, body, closed=True, width=LINE + 1)
    shaky_line(img, (cx, cy - h / 2), (cx, cy - h * 0.08))
    shaky_line(img, (cx - w * 0.45, cy - h * 0.08), (cx + w * 0.45, cy - h * 0.08))
    ImageDraw.Draw(img).rectangle((cx - w * 0.05 - 1, cy - h * 0.36, cx + w * 0.05 + 1, cy - h * 0.2), fill=BLACK)


def button(img, box, label, fill, size=14, text_color=BLACK, angle=0.0):
    shaky_box(img, box, fill=fill)
    x0, y0, x1, y1 = box
    text_tilted(img, ((x0 + x1) / 2, (y0 + y1) / 2), label, size, text_color, angle, bold=True)


def number_badge(img, cx, cy, n, fill):
    shaky_ellipse(img, cx, cy, 22, 20, fill=fill, width=LINE + 1)
    text_tilted(img, (cx, cy), str(n), 32, BLACK, random.uniform(-12, 12), bold=True)


def monitor(img, box):
    x0, y0, x1, y1 = box
    shaky_box(img, box, fill=None, width=LINE + 1)
    shaky_box(img, (x0 + 8, y0 + 8, x1 - 8, y1 - 8))
    mid = (x0 + x1) / 2
    shaky_path(img, [(mid - 8, y1), (mid - 12, y1 + 16), (mid + 12, y1 + 16), (mid + 8, y1)])
    shaky_line(img, (mid - 30, y1 + 17), (mid + 30, y1 + 17), width=LINE + 1)


def pointer(img, x, y, s=1.0):
    pts = [(x, y), (x, y + 22 * s), (x + 6 * s, y + 16 * s), (x + 11 * s, y + 26 * s), (x + 15 * s, y + 24 * s), (x + 10 * s, y + 15 * s), (x + 17 * s, y + 14 * s)]
    ImageDraw.Draw(img).polygon(pts, fill=WHITE)
    shaky_path(img, pts, closed=True, wobble_by=0.5)


def thought_bubble(img, cx, cy, rx, ry, tail_to):
    shaky_ellipse(img, cx, cy, rx, ry)
    tx, ty = tail_to
    sx, sy = cx - rx * 0.3, cy + ry
    for t, r in ((0.25, 8), (0.6, 5), (0.9, 3)):
        shaky_ellipse(img, sx + (tx - sx) * t, sy + (ty - sy) * t, r, r * 0.8, width=1)


def json_page(img, box, lines, size=12):
    x0, y0, x1, y1 = box
    fold = 22
    page = [(x0, y0), (x1 - fold, y0), (x1, y0 + fold), (x1, y1), (x0, y1)]
    shaky_path(img, page, closed=True, width=LINE + 1)
    shaky_path(img, [(x1 - fold, y0), (x1 - fold, y0 + fold), (x1, y0 + fold)])
    y = y0 + 22
    for indent, text, color in lines:
        text_tilted(img, (x0 + 10 + indent, y), text, size, color, random.uniform(-1.5, 1.5), bold=True, anchor="left")
        y += size + 9


def folder(img, cx, cy, w, h):
    x0, y0, x1, y1 = cx - w / 2, cy - h / 2, cx + w / 2, cy + h / 2
    tab = [(x0, y0), (x0 + w * 0.35, y0), (x0 + w * 0.42, y0 + 10), (x1, y0 + 10), (x1, y1), (x0, y1)]
    bucket_fill(img, tab, ORANGE)
    shaky_path(img, tab, closed=True, width=LINE + 1)
    front = [(x0 - 6, y0 + 24), (x1 + 6, y0 + 24), (x1, y1), (x0, y1)]
    bucket_fill(img, front, YELLOW)
    shaky_path(img, front, closed=True, width=LINE + 1)


def landscape_picture(img, box):
    x0, y0, x1, y1 = box
    shaky_box(img, box, fill=CYAN)
    hills = [(x0 + 3, y1 - 3), (x0 + (x1 - x0) * 0.35, y0 + (y1 - y0) * 0.45), (x0 + (x1 - x0) * 0.6, y1 - (y1 - y0) * 0.3), (x0 + (x1 - x0) * 0.8, y0 + (y1 - y0) * 0.55), (x1 - 3, y1 - 3)]
    bucket_fill(img, hills, GREEN)
    shaky_path(img, hills, width=LINE)
    shaky_ellipse(img, x1 - 12, y0 + 12, 6, 6, fill=YELLOW, width=1)


def draw_cover():
    img = new_canvas(1280, 640, 1)
    spray(img, 40, 40, 30, CYAN, 120)
    spray(img, 600, 290, 26, MAGENTA, 110)
    spray(img, 230, 300, 18, GREEN, 60)
    sun(img, 585, 52, 26)

    end = rainbow_text(img, (26, 62), "razer jev!!1", 74)
    underline_scribble(img, 26, end - 10, 108)

    cat(img, 70, 210, 1.5)
    text_tilted(img, (105, 288), "cat", 20, BLACK, -6, bold=True)
    dog(img, 290, 220, 1.4)
    text_tilted(img, (255, 290), "dog", 20, BLACK, 5, bold=True)
    text_tilted(img, (200, 190), "vs", 22, MAGENTA, -12, bold=True)
    stick_figure(img, 378, 204, 70, wave=True)

    computer_mouse(img, 510, 185, 62, 96, RED)
    curvy_arrow(img, (118, 172), (428, 176), bend=40)
    text_tilted(img, (275, 136), "cat = RED!!", 18, RED, 4, bold=True)
    text_tilted(img, (606, 244), "glow", 16, RED, -18, bold=True)

    text_tilted(img, (430, 298), "ur mouse knows if its a cat", 19, BLUE, -2)
    return img


def draw_how_it_works():
    img = new_canvas(1600, 600, 2)
    panels = [(14, 20, 254, 280), (282, 20, 522, 280), (550, 20, 790, 280)]
    for box in panels:
        shaky_box(img, box)
    for (x0, y0, x1, y1), n, fill in zip(panels, (1, 2, 3), (YELLOW, CYAN, GREEN)):
        number_badge(img, x0 + 26, y0 + 26, n, fill)

    monitor(img, (66, 56, 236, 168))
    shaky_box(img, (96, 74, 206, 152), fill=CYAN, width=1)
    cat(img, 122, 98, 0.85)
    shaky_ellipse(img, 124, 102, 16, 16, color=MAGENTA, width=LINE + 1)
    pointer(img, 124, 102, 1.3)
    text_tilted(img, (148, 222), "the app screenshots", 15, BLACK, -2)
    text_tilted(img, (148, 246), "under ur pointer", 15, BLACK, 1)

    shaky_box(img, (322, 128, 400, 196), fill=MAGENTA, width=LINE + 1)
    ImageDraw.Draw(img).rectangle((340, 146, 347, 155), fill=BLACK)
    ImageDraw.Draw(img).rectangle((372, 146, 379, 155), fill=BLACK)
    ImageDraw.Draw(img).arc((344, 152, 378, 182), 20, 160, fill=BLACK, width=LINE)
    text_tilted(img, (346, 110), "Jev", 22, BLACK, -4, bold=True)
    thought_bubble(img, 444, 66, 66, 30, (404, 126))
    text_tilted(img, (444, 56), "cat? dog?", 14, BLACK, -3)
    text_tilted(img, (444, 76), "neither?", 14, BLACK, 2)
    text_tilted(img, (454, 166), "CAT!!", 30, RED, 10, bold=True)
    spray(img, 456, 166, 34, YELLOW, 70)
    text_tilted(img, (402, 222), "Jev picks", 15, BLACK, 2)
    text_tilted(img, (402, 246), "an answer", 15, BLACK, -1)

    computer_mouse(img, 670, 112, 46, 74, RED)
    text_tilted(img, (670, 222), "the mouse goes", 15, BLACK, -2)
    text_tilted(img, (670, 248), "RED", 22, RED, 3, bold=True)

    arrow(img, (238, 150), (306, 150))
    arrow(img, (510, 150), (574, 150))
    return img


def draw_add_a_mode():
    img = new_canvas(1400, 500, 3)
    json_page(
        img,
        (14, 14, 236, 214),
        [
            (0, "{", BLACK),
            (8, '"title": "Spoiler → red",', BLUE),
            (8, '"look_at": "pointer",', BLUE),
            (8, '"question": "is it a', BLUE),
            (24, 'spoiler??",', BLUE),
            (8, '"answers": [ ... ]', BLUE),
            (0, "}", BLACK),
        ],
    )
    text_tilted(img, (125, 232), "spoiler.json", 15, BLACK, -2, bold=True)

    curvy_arrow(img, (244, 100), (306, 120), bend=34)
    text_tilted(img, (272, 64), "drop it in", 14, RED, 8, bold=True)
    folder(img, 360, 120, 92, 70)
    text_tilted(img, (360, 182), "ur modes folder", 13, BLACK, 3)

    curvy_arrow(img, (412, 118), (468, 118), bend=24)

    shaky_box(img, (478, 14, 688, 236))
    text_tilted(img, (486, 34), "pick a mode >:)", 14, BLUE, 2, anchor="left")
    underline_scribble(img, 486, 600, 44)
    for i, (label, fill) in enumerate([("Cat → red, dog → green", CYAN), ("Picture → purple...", MAGENTA), ("Quiz: best answer...", ORANGE)]):
        y = 60 + i * 34
        button(img, (492, y, 672, y + 24), label, fill, 11)
    button(img, (492, 166, 672, 192), "Spoiler → red", YELLOW, 13)
    scribble_circle(img, 582, 179, 104, 20)
    text_tilted(img, (622, 216), "NEW!!", 20, RED, -8, bold=True)
    spray(img, 676, 206, 14, MAGENTA, 50)

    text_tilted(img, (340, 228), "no code. just a json file lol", 16, BLUE, -2)
    return img


def draw_modes():
    img = new_canvas(1400, 500, 4)
    panels = [(10, 12, 230, 238), (240, 12, 460, 238), (470, 12, 690, 238)]
    for box in panels:
        shaky_box(img, box)

    text_tilted(img, (120, 28), "Cat → red,", 13, BLACK, -1, bold=True)
    text_tilted(img, (120, 46), "dog → green", 13, BLACK, 1, bold=True)
    cat(img, 52, 92, 0.9)
    arrow(img, (98, 108), (146, 108))
    computer_mouse(img, 186, 112, 24, 38, RED)
    dog(img, 74, 176, 0.9)
    arrow(img, (98, 192), (146, 192))
    computer_mouse(img, 186, 196, 24, 38, GREEN)

    text_tilted(img, (350, 28), "Quiz: best answer → green,", 13, BLACK, 1, bold=True)
    text_tilted(img, (350, 46), "others → red", 13, BLACK, -1, bold=True)
    shaky_box(img, (262, 64, 438, 96), fill=YELLOW)
    text_tilted(img, (350, 80), "2 + 2 = ?", 18, BLACK, -2, bold=True)
    for i, (label, ok) in enumerate([("3", False), ("4", True), ("5", False), ("22", False)]):
        x = 266 + (i % 2) * 90
        y = 104 + (i // 2) * 36
        button(img, (x, y, x + 80, y + 28), label, GREEN if ok else RED, 17)
    pointer(img, 402, 114, 0.8)
    text_tilted(img, (318, 206), "best one = GREEN", 14, BLUE, -2)
    computer_mouse(img, 418, 206, 16, 24, GREEN)

    text_tilted(img, (580, 28), "Picture → purple,", 13, BLACK, -1, bold=True)
    text_tilted(img, (580, 46), "text → yellow", 13, BLACK, 1, bold=True)
    landscape_picture(img, (494, 76, 574, 134))
    arrow(img, (580, 105), (616, 105))
    computer_mouse(img, 648, 112, 24, 38, PURPLE)
    shaky_box(img, (494, 164, 574, 222), fill=None)
    for i, word in enumerate(("blah blah", "words n", "stuff")):
        text_tilted(img, (500, 176 + i * 17), word, 11, BLACK, wobble(2), anchor="left")
    arrow(img, (580, 193), (616, 193))
    computer_mouse(img, 648, 196, 24, 38, YELLOW)
    return img


if __name__ == "__main__":
    save(draw_cover(), "cover.png")
    save(draw_how_it_works(), "how-it-works.png")
    save(draw_add_a_mode(), "add-a-mode.png")
    save(draw_modes(), "modes.png")
