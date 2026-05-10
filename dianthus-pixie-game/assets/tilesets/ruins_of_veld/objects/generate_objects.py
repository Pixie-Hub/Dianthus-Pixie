"""
Ruins of Veld — Procedural Object Generator
Draws pixel art for the 5 missing decorative map objects.
Run: python assets/tilesets/ruins_of_veld/objects/generate_objects.py
"""

from pathlib import Path
from PIL import Image

OUT_DIR = Path(__file__).parent

# Colour palette (desaturated stone + void purple)
T  = (  0,   0,   0,   0)   # transparent
OL = ( 31,  26,  23, 255)   # outline
SD = ( 66,  59,  51, 255)   # stone dark
SM = (110, 100,  87, 255)   # stone mid
SL = (158, 145, 128, 255)   # stone light
SO = ( 51,  41,  31, 255)   # soil
RO = ( 92,  71,  46, 255)   # root brown
VD = ( 56,  18,  89, 255)   # void dark
VM = (107,  36, 148, 255)   # void mid
VL = (166,  82, 209, 255)   # void light
CR = ( 41,  33,  28, 255)   # crack


def save(img: Image.Image, name: str) -> None:
    path = OUT_DIR / name
    img.save(path)
    print(f"  Saved: {name}  ({img.width}x{img.height})")


def px(img: Image.Image, x: int, y: int, c: tuple) -> None:
    if 0 <= x < img.width and 0 <= y < img.height:
        img.putpixel((x, y), c)


def fill(img: Image.Image, x: int, y: int, w: int, h: int, c: tuple) -> None:
    for px_ in range(x, x + w):
        for py_ in range(y, y + h):
            px(img, px_, py_, c)


def border(img: Image.Image, x: int, y: int, w: int, h: int, t: int, c: tuple) -> None:
    fill(img, x,         y,         w, t, c)
    fill(img, x,         y + h - t, w, t, c)
    fill(img, x,         y,         t, h, c)
    fill(img, x + w - t, y,         t, h, c)


def circle_outline(img: Image.Image, cx: int, cy: int, r: int, c: tuple) -> None:
    import math
    for i in range(128):
        a = i * 2 * math.pi / 128
        px(img, cx + int(r * math.cos(a)), cy + int(r * math.sin(a)), c)


# ── 32×32  Ruined planter box ────────────────────────────────────────────────
def make_planter_box() -> None:
    img = Image.new("RGBA", (32, 32), T)
    fill(img,  2,  4, 28, 24, SM)
    border(img, 2, 4, 28, 24, 1, OL)
    # bevel highlight
    fill(img, 4, 6, 22, 1, SL); fill(img, 4, 6, 1, 18, SL)
    # shadow
    fill(img, 4, 25, 22, 1, SD); fill(img, 26, 7, 1, 17, SD)
    # inner soil
    fill(img, 6, 9, 20, 15, SO)
    # cracks
    for p in [(8,5),(9,6),(10,6),(21,24),(22,25),(23,25)]:
        px(img, *p, CR)
    # dead roots
    fill(img,  7, 15, 5, 1, RO); fill(img,  7, 16, 1, 3, RO)
    fill(img, 18, 12, 6, 1, RO); fill(img, 23, 12, 1, 5, RO)
    fill(img, 12, 20, 4, 1, RO)
    # void stain
    for p in [(14,17,VD),(15,16,VD),(16,17,VD),(15,18,VM)]:
        px(img, p[0], p[1], p[2])
    save(img, "ruined_planter_box.png")


# ── 48×48  Broken archway ────────────────────────────────────────────────────
def make_broken_archway() -> None:
    img = Image.new("RGBA", (48, 48), T)
    # left pillar
    fill(img,  3, 14, 11, 32, SM); border(img, 3, 14, 11, 32, 1, OL)
    fill(img,  4, 15,  2, 30, SL); fill(img, 4, 44, 10, 1, SD)
    # right pillar (broken)
    fill(img, 34, 22, 11, 24, SM); border(img, 34, 22, 11, 24, 1, OL)
    fill(img, 35, 23,  2, 22, SL)
    # jagged break top of right pillar
    fill(img, 35, 21, 3, 1, SD); fill(img, 40, 20, 4, 2, SD)
    for p in [(34,22),(38,21),(42,22)]: px(img, *p, OL)
    # left arch segments
    for i in range(6):
        ax, ay = 3 + i * 2, 14 - i * 2
        fill(img, ax, ay, 5, 3, SM)
        px(img, ax, ay, OL); px(img, ax + 4, ay, OL); px(img, ax, ay + 2, OL)
    # keystone fragment (broken)
    fill(img, 14, 6, 10, 6, SD); fill(img, 15, 7, 8, 4, SM)
    border(img, 14, 6, 10, 6, 1, OL)
    px(img, 18, 6, SL); px(img, 19, 7, SL)
    # fallen debris
    fill(img, 26, 36, 7, 5, SD); border(img, 26, 36, 7, 5, 1, OL)
    fill(img, 34, 40, 5, 4, SM); border(img, 34, 40, 5, 4, 1, OL)
    px(img, 28, 37, SL)
    # roots on left pillar
    fill(img, 2, 20, 2, 6, RO); fill(img, 2, 25, 4, 1, RO)
    for p in [(5,28),(6,29),(4,32),(3,33)]: px(img, *p, RO)
    save(img, "broken_archway.png")


# ── 32×32  Inscribed floor tile ──────────────────────────────────────────────
def make_inscribed_tile() -> None:
    img = Image.new("RGBA", (32, 32), T)
    fill(img, 1, 1, 30, 30, SM); border(img, 1, 1, 30, 30, 1, OL)
    # grout lines
    fill(img,  1, 16, 30, 1, SD); fill(img, 16,  1,  1, 30, SD)
    # inscribed circles + cross
    circle_outline(img, 16, 16,  9, SL)
    circle_outline(img, 16, 16,  5, SL)
    fill(img, 13, 16, 7, 1, SL); fill(img, 16, 13, 1, 7, SL)
    # diagonal marks
    for p in [(12,12),(13,11),(20,12),(21,11),(12,20),(11,21),(20,20),(21,21)]:
        px(img, *p, SL)
    # void corner stain
    fill(img, 2, 2, 5, 5, VD)
    for p in [(4,4,VM),(5,3,VD),(3,5,VD)]: px(img, p[0], p[1], p[2])
    # dirt spots
    for p in [(22,8),(23,8),(22,9),(25,25),(26,24),(7,26),(8,27)]:
        px(img, *p, SO)
    save(img, "inscribed_floor_tile.png")


# ── 48×32  Irrigation channel ────────────────────────────────────────────────
def make_irrigation_channel() -> None:
    img = Image.new("RGBA", (48, 32), T)
    fill(img,  2,  2, 44, 28, SM); border(img, 2, 2, 44, 28, 1, OL)
    # bevel
    fill(img, 3,  3, 42,  1, SL); fill(img, 3, 3, 1, 26, SL)
    fill(img, 3, 27, 42,  1, SD); fill(img, 44, 3, 1, 25, SD)
    # channel groove
    fill(img,  7,  8, 34, 16, SD); border(img, 7, 8, 34, 16, 1, OL)
    fill(img,  9, 10, 30, 12, SO)
    # void residue
    fill(img, 10, 12, 8, 4, VD)
    for p in [(12,13,VM),(14,14,VM),(11,15,VM)]: px(img, p[0], p[1], p[2])
    fill(img, 30, 14, 8, 4, VD)
    for p in [(33,15,VM),(35,16,VM)]: px(img, p[0], p[1], p[2])
    # void crystals
    for p in [(16,11,VL),(17,10,VM),(36,11,VL),(37,10,VM)]: px(img, p[0], p[1], p[2])
    # cracks
    for p in [(18,4),(19,5),(20,4),(30,26),(31,27),(29,27)]: px(img, *p, CR)
    save(img, "irrigation_channel.png")


# ── 48×48  Void rubble pile ──────────────────────────────────────────────────
def make_void_rubble() -> None:
    img = Image.new("RGBA", (48, 48), T)
    # large chunk
    fill(img,  5, 12, 18, 14, SM); border(img,  5, 12, 18, 14, 1, OL)
    fill(img,  6, 13,  3, 12, SL); fill(img, 6, 24, 15, 1, SD)
    # medium chunk
    fill(img, 26, 16, 16, 11, SD); border(img, 26, 16, 16, 11, 1, OL)
    fill(img, 27, 17,  2,  9, SM)
    # small chunk bottom-left
    fill(img,  8, 30, 10,  8, SD); border(img,  8, 30, 10, 8, 1, OL)
    px(img, 9, 31, SL); px(img, 10, 31, SL)
    # small chunk bottom-right
    fill(img, 28, 32, 12,  8, SM); border(img, 28, 32, 12, 8, 1, OL)
    fill(img, 29, 33,  2,  6, SL)
    # tiny fragments
    fill(img, 20, 28,  5, 3, SD); border(img, 20, 28, 5, 3, 1, OL)
    fill(img, 38, 20,  5, 5, SM); border(img, 38, 20, 5, 5, 1, OL)
    fill(img,  4, 24,  4, 4, SD); border(img,  4, 24, 4, 4, 1, OL)
    fill(img, 40, 30,  4, 6, SD); border(img, 40, 30, 4, 6, 1, OL)
    # void crystal spike on large chunk
    for p in [(14,13,VD),(15,12,VM),(16,11,VL),(17,12,VM),(15,13,VD),(13,12,VD)]:
        px(img, p[0], p[1], p[2])
    # void crystal spike on medium chunk
    for p in [(34,17,VD),(35,16,VM),(36,15,VL),(37,16,VM),(35,17,VD)]:
        px(img, p[0], p[1], p[2])
    # void pool between chunks
    fill(img, 18, 34, 10, 6, VD); border(img, 18, 34, 10, 6, 1, OL)
    for p in [(20,35,VM),(22,36,VM),(21,37,VL),(24,35,VM),(19,37,VM)]:
        px(img, p[0], p[1], p[2])
    save(img, "void_rubble_pile.png")


if __name__ == "__main__":
    print("\n=== Ruins of Veld Object Generator ===")
    make_planter_box()
    make_broken_archway()
    make_inscribed_tile()
    make_irrigation_channel()
    make_void_rubble()
    print(f"\nDone! 5 objects written to: {OUT_DIR}")
