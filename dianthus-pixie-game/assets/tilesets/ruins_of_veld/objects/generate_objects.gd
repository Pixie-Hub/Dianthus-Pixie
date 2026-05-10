extends SceneTree

# Ruins of Veld — Procedural Object Generator
# Draws pixel art placeholders for the 5 missing decorative objects.
# Usage: godot --headless -s assets/tilesets/ruins_of_veld/objects/generate_objects.gd

const OUT_DIR = "res://assets/tilesets/ruins_of_veld/objects/"

# Colour palette (desaturated stone + void purple, matches ruins tileset)
const TRANSP  := Color(0.00, 0.00, 0.00, 0.00)
const OUTLINE := Color(0.12, 0.10, 0.09, 1.00)
const STONE_D := Color(0.26, 0.23, 0.20, 1.00)
const STONE_M := Color(0.43, 0.39, 0.34, 1.00)
const STONE_L := Color(0.62, 0.57, 0.50, 1.00)
const SOIL    := Color(0.20, 0.16, 0.12, 1.00)
const ROOT    := Color(0.36, 0.28, 0.18, 1.00)
const VOID_D  := Color(0.22, 0.07, 0.35, 1.00)
const VOID_M  := Color(0.42, 0.14, 0.58, 1.00)
const VOID_L  := Color(0.65, 0.32, 0.82, 1.00)
const CRACK   := Color(0.16, 0.13, 0.11, 1.00)


func _init() -> void:
	print("\n=== Ruins of Veld Object Generator ===")
	_make_planter_box()
	_make_broken_archway()
	_make_inscribed_tile()
	_make_irrigation_channel()
	_make_void_rubble()
	print("\nDone! 5 objects written to: %s" % OUT_DIR)
	quit()


# ── Helpers ─────────────────────────────────────────────────────────────────

func _save(img: Image, filename: String) -> void:
	var path := OUT_DIR + filename
	img.save_png(path)
	print("  Saved: %s  (%dx%d)" % [filename, img.get_width(), img.get_height()])


func _px(img: Image, x: int, y: int, c: Color) -> void:
	if x >= 0 and y >= 0 and x < img.get_width() and y < img.get_height():
		img.set_pixel(x, y, c)


func _fill(img: Image, x: int, y: int, w: int, h: int, c: Color) -> void:
	for px in range(x, x + w):
		for py in range(y, y + h):
			_px(img, px, py, c)


func _border(img: Image, x: int, y: int, w: int, h: int, t: int, c: Color) -> void:
	_fill(img, x,         y,         w, t, c)
	_fill(img, x,         y + h - t, w, t, c)
	_fill(img, x,         y,         t, h, c)
	_fill(img, x + w - t, y,         t, h, c)


func _circle_outline(img: Image, cx: int, cy: int, r: int, c: Color) -> void:
	for i in range(128):
		var a := i * TAU / 128.0
		_px(img, cx + int(r * cos(a)), cy + int(r * sin(a)), c)


# ── Objects ──────────────────────────────────────────────────────────────────

# 32×32  Ruined planter box
func _make_planter_box() -> void:
	var img := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	# Stone walls (4 px thick)
	_fill(img,  2,  4, 28, 24, STONE_M)
	_border(img, 2, 4, 28, 24, 1, OUTLINE)
	# Bevel highlight (top-left)
	_fill(img, 4, 6, 22, 1, STONE_L)
	_fill(img, 4, 6,  1, 18, STONE_L)
	# Shadow (bottom-right)
	_fill(img, 4, 25, 22, 1, STONE_D)
	_fill(img, 26, 7,  1, 17, STONE_D)
	# Inner soil
	_fill(img, 6, 9, 20, 15, SOIL)
	# Cracks on stone
	_px(img,  8,  5, CRACK); _px(img,  9,  6, CRACK); _px(img, 10,  6, CRACK)
	_px(img, 21, 24, CRACK); _px(img, 22, 25, CRACK); _px(img, 23, 25, CRACK)
	# Dead root tendrils in soil
	_fill(img,  7, 15, 5, 1, ROOT); _fill(img,  7, 16, 1, 3, ROOT)
	_fill(img, 18, 12, 6, 1, ROOT); _fill(img, 23, 12, 1, 5, ROOT)
	_fill(img, 12, 20, 4, 1, ROOT)
	# Void stain
	_px(img, 14, 17, VOID_D); _px(img, 15, 16, VOID_D)
	_px(img, 16, 17, VOID_D); _px(img, 15, 18, VOID_M)
	_save(img, "ruined_planter_box.png")


# 48×48  Broken archway
func _make_broken_archway() -> void:
	var img := Image.create(48, 48, false, Image.FORMAT_RGBA8)
	# Left pillar (full height)
	_fill(img,  3, 14, 11, 32, STONE_M)
	_border(img, 3, 14, 11, 32, 1, OUTLINE)
	_fill(img,  4, 15,  2, 30, STONE_L)
	_fill(img,  4, 44, 10,  1, STONE_D)
	# Right pillar (broken, shorter)
	_fill(img, 34, 22, 11, 24, STONE_M)
	_border(img, 34, 22, 11, 24, 1, OUTLINE)
	_fill(img, 35, 23,  2, 22, STONE_L)
	# Jagged break on right pillar top
	_px(img, 34, 22, OUTLINE); _px(img, 38, 21, OUTLINE); _px(img, 42, 22, OUTLINE)
	_fill(img, 35, 21, 3, 1, STONE_D)
	_fill(img, 40, 20, 4, 2, STONE_D)
	# Left arch segment (sweeping up from left pillar)
	for i in range(6):
		var ax := 3 + i * 2
		var ay := 14 - i * 2
		_fill(img, ax, ay, 5, 3, STONE_M)
		_px(img, ax, ay, OUTLINE)
		_px(img, ax + 4, ay, OUTLINE)
		_px(img, ax, ay + 2, OUTLINE)
	# Keystone fragment (broken top)
	_fill(img, 14,  6, 10,  6, STONE_D)
	_fill(img, 15,  7,  8,  4, STONE_M)
	_border(img, 14, 6, 10, 6, 1, OUTLINE)
	_px(img, 18, 6, STONE_L); _px(img, 19, 7, STONE_L)
	# Fallen chunks at base
	_fill(img, 26, 36,  7, 5, STONE_D); _border(img, 26, 36, 7, 5, 1, OUTLINE)
	_fill(img, 34, 40,  5, 4, STONE_M); _border(img, 34, 40, 5, 4, 1, OUTLINE)
	_px(img, 28, 37, STONE_L)
	# Roots on left pillar
	_fill(img, 2, 20, 2, 6, ROOT); _fill(img, 2, 25, 4, 1, ROOT)
	_px(img, 5, 28, ROOT); _px(img, 6, 29, ROOT)
	_px(img, 4, 32, ROOT); _px(img, 3, 33, ROOT)
	_save(img, "broken_archway.png")


# 32×32  Inscribed floor tile
func _make_inscribed_tile() -> void:
	var img := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	# Stone base
	_fill(img, 1, 1, 30, 30, STONE_M)
	_border(img, 1, 1, 30, 30, 1, OUTLINE)
	# Grout crack lines (very subtle)
	_fill(img,  1, 16, 30, 1, STONE_D)
	_fill(img, 16,  1,  1, 30, STONE_D)
	# Inscribed botanical circle
	_circle_outline(img, 16, 16, 9, STONE_L)
	_circle_outline(img, 16, 16, 5, STONE_L)
	# Cross/rune inside
	_fill(img, 13, 16,  7, 1, STONE_L)
	_fill(img, 16, 13,  1, 7, STONE_L)
	# Diagonal marks (botanical symbol)
	_px(img, 12, 12, STONE_L); _px(img, 13, 11, STONE_L)
	_px(img, 20, 12, STONE_L); _px(img, 21, 11, STONE_L)
	_px(img, 12, 20, STONE_L); _px(img, 11, 21, STONE_L)
	_px(img, 20, 20, STONE_L); _px(img, 21, 21, STONE_L)
	# Void corner stain
	_fill(img,  2,  2, 5, 5, VOID_D)
	_px(img, 4, 4, VOID_M); _px(img, 5, 3, VOID_D); _px(img, 3, 5, VOID_D)
	# Dirt overlay spots
	_px(img, 22, 8, SOIL); _px(img, 23, 8, SOIL); _px(img, 22, 9, SOIL)
	_px(img, 25, 25, SOIL); _px(img, 26, 24, SOIL)
	_px(img,  7, 26, SOIL); _px(img,  8, 27, SOIL)
	_save(img, "inscribed_floor_tile.png")


# 48×32  Irrigation channel
func _make_irrigation_channel() -> void:
	var img := Image.create(48, 32, false, Image.FORMAT_RGBA8)
	# Stone surround
	_fill(img,  2,  2, 44, 28, STONE_M)
	_border(img, 2, 2, 44, 28, 1, OUTLINE)
	# Top highlight / side shadow
	_fill(img, 3,  3, 42, 1, STONE_L)
	_fill(img, 3,  3,  1, 26, STONE_L)
	_fill(img, 3, 27, 42,  1, STONE_D)
	_fill(img, 44, 3,  1, 25, STONE_D)
	# Channel groove (sunken center strip)
	_fill(img,  7,  8, 34, 16, STONE_D)
	_border(img, 7, 8, 34, 16, 1, OUTLINE)
	# Inner channel floor
	_fill(img,  9, 10, 30, 12, SOIL)
	# Void residue pooling inside
	_fill(img, 10, 12, 8, 4, VOID_D)
	_px(img, 12, 13, VOID_M); _px(img, 14, 14, VOID_M); _px(img, 11, 15, VOID_M)
	_fill(img, 30, 14, 8, 4, VOID_D)
	_px(img, 33, 15, VOID_M); _px(img, 35, 16, VOID_M)
	# Crystal growths in residue
	_px(img, 16, 11, VOID_L); _px(img, 17, 10, VOID_M)
	_px(img, 36, 11, VOID_L); _px(img, 37, 10, VOID_M)
	# Cracks on stone surround
	_px(img, 18,  4, CRACK); _px(img, 19,  5, CRACK); _px(img, 20,  4, CRACK)
	_px(img, 30, 26, CRACK); _px(img, 31, 27, CRACK); _px(img, 29, 27, CRACK)
	_save(img, "irrigation_channel.png")


# 48×48  Void rubble pile
func _make_void_rubble() -> void:
	var img := Image.create(48, 48, false, Image.FORMAT_RGBA8)
	# Large chunk (center-left)
	_fill(img,  5, 12, 18, 14, STONE_M)
	_border(img, 5, 12, 18, 14, 1, OUTLINE)
	_fill(img,  6, 13,  3, 12, STONE_L)
	_fill(img,  6, 24, 15,  1, STONE_D)
	# Medium chunk (right)
	_fill(img, 26, 16, 16, 11, STONE_D)
	_border(img, 26, 16, 16, 11, 1, OUTLINE)
	_fill(img, 27, 17,  2,  9, STONE_M)
	# Small chunk (bottom-left)
	_fill(img,  8, 30, 10,  8, STONE_D)
	_border(img, 8, 30, 10, 8, 1, OUTLINE)
	_px(img, 9, 31, STONE_L); _px(img, 10, 31, STONE_L)
	# Small chunk (bottom-right)
	_fill(img, 28, 32, 12,  8, STONE_M)
	_border(img, 28, 32, 12, 8, 1, OUTLINE)
	_fill(img, 29, 33,  2,  6, STONE_L)
	# Tiny scattered fragments
	_fill(img, 20, 28,  5,  3, STONE_D); _border(img, 20, 28, 5, 3, 1, OUTLINE)
	_fill(img, 38, 20,  5,  5, STONE_M); _border(img, 38, 20, 5, 5, 1, OUTLINE)
	_fill(img,  4, 24,  4,  4, STONE_D); _border(img,  4, 24, 4, 4, 1, OUTLINE)
	_fill(img, 40, 30,  4,  6, STONE_D); _border(img, 40, 30, 4, 6, 1, OUTLINE)
	# Void crystal spike on large chunk
	_px(img, 14, 13, VOID_D); _px(img, 15, 12, VOID_M); _px(img, 16, 11, VOID_L)
	_px(img, 17, 12, VOID_M); _px(img, 15, 13, VOID_D); _px(img, 13, 12, VOID_D)
	# Void crystal spike on medium chunk
	_px(img, 34, 17, VOID_D); _px(img, 35, 16, VOID_M); _px(img, 36, 15, VOID_L)
	_px(img, 37, 16, VOID_M); _px(img, 35, 17, VOID_D)
	# Void pool between chunks
	_fill(img, 18, 34, 10,  6, VOID_D)
	_px(img, 20, 35, VOID_M); _px(img, 22, 36, VOID_M); _px(img, 21, 37, VOID_L)
	_px(img, 24, 35, VOID_M); _px(img, 19, 37, VOID_M)
	# Outline around void pool
	_border(img, 18, 34, 10, 6, 1, OUTLINE)
	_save(img, "void_rubble_pile.png")
