class_name EnemyRegistry

const ENEMIES: Dictionary = {
	"shadowling": {
		"display_name": "Shadowling",
		"role": "Core harrier",
		"scene_path": "res://enemies/shadowling/shadowling.tscn",
		"codex_icon": "res://enemies/shadowling/shadowling.png",
		"unlock_hint": "Encounter a Shadowling during the first night wave.",
		"lore": "A thin void-touched scout that probes the garden before turning its claws toward the Dianthus Core.",
	},
	"voidrunner": {
		"display_name": "Voidrunner",
		"role": "Rushing striker",
		"scene_path": "res://enemies/voidrunner/voidrunner.tscn",
		"codex_icon": "res://enemies/voidrunner/voidrunner.png",
		"unlock_hint": "Encounter a Voidrunner from Day 2 onward.",
		"lore": "A fragile but blindingly fast attacker that ignores hesitation and races straight for the Core.",
	},
	"stonehusk": {
		"display_name": "Stonehusk",
		"role": "Siege brute",
		"scene_path": "res://enemies/stonehusk/stonehusk.tscn",
		"codex_icon": "res://enemies/stonehusk/stonehusk.png",
		"unlock_hint": "Encounter a Stonehusk from Day 4 onward.",
		"lore": "A slow armored mass that refuses to retreat, grinding through defenses until it reaches striking range.",
	},
	"phantom_weaver": {
		"display_name": "Phantom Weaver",
		"role": "Teleporting hunter",
		"scene_path": "res://enemies/phantom_weaver/phantom_weaver.tscn",
		"codex_icon": "res://enemies/phantom_weaver/phantom_weaver.png",
		"unlock_hint": "Encounter a Phantom Weaver from Day 6 onward.",
		"lore": "A shadow-threaded predator that slips out of lethal pressure and reappears where the garden line is weakest.",
	},
	"swarm_larva": {
		"display_name": "Swarm Larva",
		"role": "Flocking swarm",
		"scene_path": "res://enemies/swarm_larva/swarm_larva.tscn",
		"codex_icon": "res://enemies/swarm_larva/swarm_larva.png",
		"unlock_hint": "Encounter Swarm Larvae from Day 8 onward.",
		"lore": "Small void larvae that are weak alone but dangerous in groups, flooding lanes with skittering pressure.",
	},
	"the_devourer": {
		"display_name": "The Devourer",
		"role": "Final boss",
		"scene_path": "res://enemies/devourer/the_devourer.tscn",
		"codex_icon": "res://enemies/devourer/the_devourer.png",
		"unlock_hint": "Stand against the Devourer during the final story night.",
		"lore": "The great void hunger given shape, drawn to the Dianthus Core for the bloom it could never grow itself.",
	},
}

const ANIMATION_TEXTURE_SUFFIXES: Array[String] = [
	"_animations.png",
	"_walk.png",
	"_attack.png",
	"_death.png",
]

static var _placeholder_icon: Texture2D = null


static func has_enemy(enemy_id: String) -> bool:
	return ENEMIES.has(enemy_id)


static func get_enemy(enemy_id: String) -> Dictionary:
	return ENEMIES.get(enemy_id, {})


static func get_enemy_ids() -> Array[String]:
	var result: Array[String] = []
	for enemy_id: String in ENEMIES:
		result.append(enemy_id)
	return result


static func get_display_name(enemy_id: String) -> String:
	return str(get_enemy(enemy_id).get("display_name", enemy_id.capitalize()))


static func get_scene_path(enemy_id: String) -> String:
	return str(get_enemy(enemy_id).get("scene_path", ""))


static func get_codex_icon_texture(enemy_id: String) -> Texture2D:
	var icon_path: String = _get_codex_icon_path(enemy_id)
	if icon_path.is_empty():
		push_warning("Missing codex icon for %s" % enemy_id)
		return _get_placeholder_icon()
	var texture: Texture2D = load(icon_path) as Texture2D
	if texture == null:
		push_warning("Missing codex icon for %s at %s" % [enemy_id, icon_path])
		return _get_placeholder_icon()
	return texture


static func get_stats(enemy_id: String) -> Dictionary:
	var enemy: Node = _instantiate_enemy(enemy_id)
	if enemy == null:
		return {"hp": 0, "damage": 0, "speed": 0.0}
	var stats: Dictionary = {
		"hp": int(enemy.get("max_hp")),
		"damage": int(enemy.get("damage")),
		"speed": float(enemy.get("move_speed")),
	}
	enemy.free()
	return stats


static func get_sprite_texture(enemy_id: String) -> Texture2D:
	var enemy: Node = _instantiate_enemy(enemy_id)
	if enemy == null:
		return null
	var sprite: Sprite2D = enemy.find_child("Sprite2D", true, false) as Sprite2D
	var texture: Texture2D = sprite.texture if sprite != null else null
	enemy.free()
	return texture


static func get_drop_summary(enemy_id: String) -> String:
	var enemy: Node = _instantiate_enemy(enemy_id)
	if enemy == null:
		return "Unknown"
	var raw_drops: Array = enemy.call("_get_seed_drop_table") as Array
	enemy.free()
	if raw_drops.is_empty():
		return "None"
	var parts: Array[String] = []
	for entry: Dictionary in raw_drops:
		var item_id: String = str(entry.get("item", ""))
		var chance: int = int(round(float(entry.get("chance", 0.0)) * 100.0))
		parts.append("%s (%d%%)" % [ItemDatabase.get_display_name(item_id), chance])
	var summary: String = ""
	for part: String in parts:
		if not summary.is_empty():
			summary += ", "
		summary += part
	return summary


static func get_enemy_id_for_node(node: Node) -> String:
	if node == null:
		return ""
	var script: Script = node.get_script() as Script
	if script != null:
		var script_id: String = script.resource_path.get_file().get_basename()
		if has_enemy(script_id):
			return script_id
	var scene_path: String = node.scene_file_path
	for enemy_id: String in ENEMIES:
		if get_scene_path(enemy_id) == scene_path:
			return enemy_id
	return ""


static func _instantiate_enemy(enemy_id: String) -> Node:
	var scene_path: String = get_scene_path(enemy_id)
	if scene_path.is_empty():
		return null
	var scene: PackedScene = load(scene_path) as PackedScene
	if scene == null:
		return null
	return scene.instantiate()


static func _get_codex_icon_path(enemy_id: String) -> String:
	var enemy: Dictionary = get_enemy(enemy_id)
	var icon_path: String = str(enemy.get("codex_icon", ""))
	if _is_clean_icon_path(icon_path):
		return icon_path
	var scene_path: String = get_scene_path(enemy_id)
	if scene_path.is_empty():
		return ""
	var base_icon_path: String = "%s/%s.png" % [
		scene_path.get_base_dir(),
		scene_path.get_file().get_basename(),
	]
	if ResourceLoader.exists(base_icon_path, "Texture2D"):
		return base_icon_path
	return ""


static func _is_clean_icon_path(texture_path: String) -> bool:
	if texture_path.is_empty():
		return false
	var lower_path: String = texture_path.to_lower()
	for suffix: String in ANIMATION_TEXTURE_SUFFIXES:
		if lower_path.ends_with(suffix):
			return false
	return lower_path.ends_with(".png") and ResourceLoader.exists(texture_path, "Texture2D")


static func _get_placeholder_icon() -> Texture2D:
	if _placeholder_icon != null:
		return _placeholder_icon
	var image: Image = Image.create(32, 32, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.12, 0.1, 0.09, 1.0))
	for y: int in range(32):
		for x: int in range(32):
			if x == y or x == 31 - y or x == 0 or y == 0 or x == 31 or y == 31:
				image.set_pixel(x, y, Color(0.72, 0.55, 0.22, 1.0))
	_placeholder_icon = ImageTexture.create_from_image(image)
	return _placeholder_icon
