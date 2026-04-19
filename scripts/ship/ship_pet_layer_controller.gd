class_name ShipPetLayerController
extends RefCounted

var pet_visual_data := {
	"alien_jelly": {
		"zones": [
			{"texture_path": "res://assets/items/pets/meduza001.png", "anchor_pos": Vector2(0.334, 0.54),  "scale": 1.5},
			{"texture_path": "res://assets/items/pets/meduza002.png", "anchor_pos": Vector2(0.58,  0.53),  "scale": 1.30},
			{"texture_path": "res://assets/items/pets/meduza003.png", "anchor_pos": Vector2(0.64,  0.23),  "scale": 0.92},
			{"texture_path": "res://assets/items/pets/meduza004.png", "anchor_pos": Vector2(0.25,  0.39),  "scale": 1.16},
		]
	},
	"marta_cat": {
		"zones": [
			{"texture_path": "res://assets/items/pets/cat001.png", "anchor_pos": Vector2(0.40,  0.577), "scale": 1.341},
			{"texture_path": "res://assets/items/pets/cat002.png", "anchor_pos": Vector2(0.636, 0.54),  "scale": 1.3},
			{"texture_path": "res://assets/items/pets/cat003.png", "anchor_pos": Vector2(0.93,  0.68),  "scale": 1.505},
			{"texture_path": "res://assets/items/pets/cat004.png", "anchor_pos": Vector2(0.903, 0.08),  "scale": 1.882},
			{"texture_path": "res://assets/items/pets/cat005.png", "anchor_pos": Vector2(0.78,  0.91),  "scale": 2.28},
			{"texture_path": "res://assets/items/pets/cat006.png", "anchor_pos": Vector2(0.89,  0.64),  "scale": 1.08},
			{"texture_path": "res://assets/items/pets/cat007.png", "anchor_pos": Vector2(0.57,  0.47),  "scale": 2.28},
			{"texture_path": "res://assets/items/pets/cat008.png", "anchor_pos": Vector2(0.39,  0.52),  "scale": 0.24},
		]
	},
	"robo_crab": {
		"zones": [
			{"texture_path": "res://assets/items/pets/crab001.png", "anchor_pos": Vector2(0.225, 0.9),   "scale": 0.9},
			{"texture_path": "res://assets/items/pets/crab002.png", "anchor_pos": Vector2(0.319, 0.62),  "scale": 0.966},
			{"texture_path": "res://assets/items/pets/crab003.png", "anchor_pos": Vector2(0.895, 0.108), "scale": 1.0},
			{"texture_path": "res://assets/items/pets/crab004.png", "anchor_pos": Vector2(0.45,  0.522), "scale": 0.643},
			{"texture_path": "res://assets/items/pets/crab005.png", "anchor_pos": Vector2(0.334, 0.70),  "scale": 0.77},
			{"texture_path": "res://assets/items/pets/crab006.png", "anchor_pos": Vector2(0.342, 0.192), "scale": 0.889},
			{"texture_path": "res://assets/items/pets/crab007.png", "anchor_pos": Vector2(0.57,  0.47),  "scale": 0.767},
			{"texture_path": "res://assets/items/pets/crab008.png", "anchor_pos": Vector2(0.585, 0.244), "scale": 0.938},
		]
	}
}

var active_pet_zone_indices := {
	"alien_jelly": 0,
	"marta_cat":   0,
	"robo_crab":   0,
}


func refresh_items(pet_layer: Control, clear_layer_callable: Callable) -> void:
	clear_layer_callable.call(pet_layer)

	if PlayerState.active_pet_id.is_empty():
		return

	var pet_id: String = PlayerState.active_pet_id
	var pet_data = pet_visual_data.get(pet_id, null)
	if pet_data == null:
		push_error("Нет pet visual data для pet_id: '%s'" % pet_id)
		return

	var rect := TextureRect.new()
	rect.name         = pet_id
	rect.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_SCALE
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.visible      = true
	pet_layer.add_child(rect)


func update_layer(pet_layer: Control, cockpit_layer: Control, cockpit_texture: Texture2D) -> void:
	if cockpit_texture == null:
		return

	pet_layer.position = cockpit_layer.position
	pet_layer.size     = cockpit_layer.size

	for child in pet_layer.get_children():
		if not child is TextureRect:
			continue

		var pet_id: String = child.name
		var pet_data = pet_visual_data.get(pet_id, null)
		if pet_data == null:
			continue

		var zones: Array = pet_data["zones"]
		if zones.is_empty():
			continue

		var zone_index: int = active_pet_zone_indices.get(pet_id, 0)
		zone_index = clamp(zone_index, 0, zones.size() - 1)

		var zone_data: Dictionary = zones[zone_index]
		var texture = load(zone_data["texture_path"])
		if texture == null:
			continue

		child.texture = texture

		var anchor_pos: Vector2 = zone_data["anchor_pos"]
		var scale: float        = zone_data.get("scale", 1.0)
		var texture_size: Vector2 = texture.get_size()

		var base_scale: float = min(
			pet_layer.size.x / cockpit_texture.get_size().x,
			pet_layer.size.y / cockpit_texture.get_size().y
		)
		var item_size: Vector2 = texture_size * base_scale * scale

		child.size     = item_size
		child.position = Vector2(
			pet_layer.size.x * anchor_pos.x - item_size.x * 0.5,
			pet_layer.size.y * anchor_pos.y - item_size.y * 0.5
		)


func cycle_active_zone(pet_id: String) -> void:
	if not active_pet_zone_indices.has(pet_id):
		active_pet_zone_indices[pet_id] = 0

	var pet_data = pet_visual_data.get(pet_id, null)
	if pet_data == null:
		return

	var zones: Array = pet_data["zones"]
	if zones.is_empty():
		return

	active_pet_zone_indices[pet_id] = (active_pet_zone_indices[pet_id] + 1) % zones.size()
