extends SceneTree

# PixelLab to Godot Tileset Converter for Ruins of Veld
# Converts 2 chained Wang tilesets (earth→stone→void) into a single Godot TileSet .tres
# Usage: godot --headless -s assets/tilesets/ruins_of_veld/convert_tileset.gd

const BASE_DIR = "res://assets/tilesets/ruins_of_veld/"
const OUTPUT_PATH = "res://assets/tilesets/ruins_of_veld/ruins_terrain.tres"

var TILESET_PAIRS = [
	{"json": BASE_DIR + "earth_to_stone_metadata.json", "png": BASE_DIR + "earth_to_stone_image.png"},
	{"json": BASE_DIR + "stone_to_void_metadata.json", "png": BASE_DIR + "stone_to_void_image.png"},
]

# Terrain IDs: 0=dark earth, 1=weathered stone, 2=void corruption
var terrain_names = {}
var tiles = []
var tile_size = 16

func _init():
	print("\n=== Ruins of Veld Tileset Converter ===")

	for pair in TILESET_PAIRS:
		_load_tileset_pair(pair.json, pair.png)

	if tiles.is_empty():
		print("ERROR: No tiles loaded")
		quit()
		return

	_create_tileset()
	print("\nDone! Created: %s" % OUTPUT_PATH)
	print("Terrains: %s" % str(terrain_names))
	print("\nIn Godot Editor:")
	print("  1. Add TileMapLayer, assign ruins_terrain.tres")
	print("  2. TileMap tab > Terrains > select terrain")
	print("  3. Rect Tool (R) to paint")
	quit()


func _load_tileset_pair(json_path: String, png_path: String):
	print("Loading: %s" % json_path)

	var file = FileAccess.open(json_path, FileAccess.READ)
	if not file:
		print("  ERROR: Cannot open %s" % json_path)
		return

	var json = JSON.new()
	if json.parse(file.get_as_text()) != OK:
		print("  ERROR: Invalid JSON")
		return
	file.close()
	var metadata = json.data

	var sprite_sheet = Image.new()
	if sprite_sheet.load(png_path) != OK:
		print("  ERROR: Cannot load %s" % png_path)
		return

	# Extract terrain names from descriptions
	var lower_name = _shorten_name(metadata.lower_description)
	var upper_name = _shorten_name(metadata.upper_description)
	var lower_id = _get_terrain_id(lower_name)
	var upper_id = _get_terrain_id(upper_name)
	print("  Lower terrain [%d]: %s" % [lower_id, lower_name])
	print("  Upper terrain [%d]: %s" % [upper_id, upper_name])

	# Parse tiles
	var added = 0
	for tile in metadata.tileset_data.tiles:
		var corners = tile.corners
		var bbox = tile.bounding_box

		var tile_image = Image.create(bbox.width, bbox.height, false, Image.FORMAT_RGBA8)
		tile_image.blit_rect(sprite_sheet, Rect2i(bbox.x, bbox.y, bbox.width, bbox.height), Vector2i.ZERO)

		var nw = upper_id if corners.NW == "upper" else lower_id
		var ne = upper_id if corners.NE == "upper" else lower_id
		var sw = upper_id if corners.SW == "upper" else lower_id
		var se = upper_id if corners.SE == "upper" else lower_id

		tiles.append({
			"image": tile_image,
			"corners": [nw, ne, sw, se]
		})
		added += 1

	print("  Added %d tiles" % added)


func _shorten_name(desc: String) -> String:
	# Extract a short terrain name from the long description
	if "void" in desc.to_lower() or "corruption" in desc.to_lower():
		return "void_corruption"
	elif "earth" in desc.to_lower() or "dirt" in desc.to_lower() or "soil" in desc.to_lower():
		return "dark_earth"
	elif "sandstone" in desc.to_lower() or "flagstone" in desc.to_lower():
		return "weathered_stone"
	return desc.left(30)


func _get_terrain_id(name: String) -> int:
	for id in terrain_names:
		if terrain_names[id] == name:
			return id
	var id = terrain_names.size()
	terrain_names[id] = name
	return id


func _create_tileset():
	print("\nBuilding tileset with %d tiles, %d terrains..." % [tiles.size(), terrain_names.size()])

	# Create combined atlas
	var cols = 8
	var rows = ceili(float(tiles.size()) / cols)
	var atlas_w = cols * tile_size
	var atlas_h = rows * tile_size
	var atlas = Image.create(atlas_w, atlas_h, false, Image.FORMAT_RGBA8)

	for i in range(tiles.size()):
		var img = tiles[i].image
		var x = (i % cols) * tile_size
		var y = (i / cols) * tile_size
		atlas.blit_rect(img, Rect2i(0, 0, tile_size, tile_size), Vector2i(x, y))

	# Save atlas PNG
	var atlas_path = BASE_DIR + "ruins_terrain_atlas.png"
	atlas.save_png(atlas_path)
	print("Saved atlas: %s (%dx%d)" % [atlas_path, atlas_w, atlas_h])

	# Sample terrain colors from base tiles (all corners same)
	var terrain_colors = {}
	for i in range(tiles.size()):
		var c = tiles[i].corners
		if c[0] == c[1] and c[1] == c[2] and c[2] == c[3]:
			if not terrain_colors.has(c[0]):
				var img = tiles[i].image
				terrain_colors[c[0]] = img.get_pixel(img.get_width() / 2, img.get_height() / 2)

	# Build .tres content
	var tres = '[gd_resource type="TileSet" load_steps=3 format=3]\n\n'

	# Atlas texture (external reference)
	tres += '[ext_resource type="Texture2D" path="%s" id="atlas_tex"]\n\n' % atlas_path

	# TileSetAtlasSource
	tres += '[sub_resource type="TileSetAtlasSource" id="TileSetAtlasSource_1"]\n'
	tres += 'texture = ExtResource("atlas_tex")\n'
	tres += 'texture_region_size = Vector2i(%d, %d)\n' % [tile_size, tile_size]

	for i in range(tiles.size()):
		var x = i % cols
		var y = i / cols
		var c = tiles[i].corners
		tres += '%d:%d/0 = 0\n' % [x, y]
		tres += '%d:%d/0/terrain_set = 0\n' % [x, y]
		tres += '%d:%d/0/terrains_peering_bit/top_left_corner = %d\n' % [x, y, c[0]]
		tres += '%d:%d/0/terrains_peering_bit/top_right_corner = %d\n' % [x, y, c[1]]
		tres += '%d:%d/0/terrains_peering_bit/bottom_left_corner = %d\n' % [x, y, c[2]]
		tres += '%d:%d/0/terrains_peering_bit/bottom_right_corner = %d\n' % [x, y, c[3]]

	tres += '\n[resource]\n'
	tres += 'tile_size = Vector2i(%d, %d)\n' % [tile_size, tile_size]
	tres += 'terrain_set_0/mode = 0\n'

	for id in terrain_names:
		var name = terrain_names[id]
		var color = terrain_colors.get(id, Color(0.5, 0.5, 0.5))
		tres += 'terrain_set_0/terrain_%d/name = "%s"\n' % [id, name]
		tres += 'terrain_set_0/terrain_%d/color = Color(%f, %f, %f, 1)\n' % [id, color.r, color.g, color.b]

	tres += 'sources/0 = SubResource("TileSetAtlasSource_1")\n'

	var out = FileAccess.open(OUTPUT_PATH, FileAccess.WRITE)
	out.store_string(tres)
	out.close()
	print("Saved tileset: %s" % OUTPUT_PATH)
