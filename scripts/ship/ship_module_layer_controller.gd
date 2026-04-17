class_name ShipModuleLayerController
extends RefCounted

var module_visual_data := {
	# Sleep zone
	"module_sleep_001": {"texture_path": "res://assets/items/hardware/module.sleep001.png", "anchor_pos": Vector2(0.863, 0.608), "scale": 1.0},
	"module_sleep_002": {"texture_path": "res://assets/items/hardware/module.sleep002.png", "anchor_pos": Vector2(0.866, 0.568), "scale": 1.0},
	"module_sleep_003": {"texture_path": "res://assets/items/hardware/module.sleep003.png", "anchor_pos": Vector2(0.851, 0.584), "scale": 1.0},
	"module_sleep_004": {"texture_path": "res://assets/items/hardware/module.sleep004.png", "anchor_pos": Vector2(0.865, 0.59), "scale": 1.0},
	"module_sleep_005": {"texture_path": "res://assets/items/hardware/module.sleep005.png", "anchor_pos": Vector2(0.85, 0.50), "scale": 1.0},
	"module_sleep_006": {"texture_path": "res://assets/items/hardware/module.sleep006.png", "anchor_pos": Vector2(0.861, 0.605), "scale": 1.0},
	"module_sleep_007": {"texture_path": "res://assets/items/hardware/module.sleep007.png", "anchor_pos": Vector2(0.851, 0.50), "scale": 1.0},
	"module_sleep_008": {"texture_path": "res://assets/items/hardware/module.sleep008.png", "anchor_pos": Vector2(0.87, 0.568), "scale": 1.0},

	# Workzone
	"module_workzone_001": {"texture_path": "res://assets/items/hardware/module.workzone001.png", "anchor_pos": Vector2(0.083, 0.653), "scale": 1.534},
	"module_workzone_002": {"texture_path": "res://assets/items/hardware/module.workzone002.png", "anchor_pos": Vector2(0.184, 0.604), "scale": 1.0},
	"module_workzone_003": {"texture_path": "res://assets/items/hardware/module.workzone003.png", "anchor_pos": Vector2(0.196, 0.579), "scale": 1.0},
	"module_workzone_004": {"texture_path": "res://assets/items/hardware/module.workzone004.png", "anchor_pos": Vector2(0.153, 0.592), "scale": 1.01},
	"module_workzone_005": {"texture_path": "res://assets/items/hardware/module.workzone005.png", "anchor_pos": Vector2(0.153, 0.499), "scale": 1.0},
	"module_workzone_006": {"texture_path": "res://assets/items/hardware/module.workzone006.png", "anchor_pos": Vector2(0.174, 0.604), "scale": 1.0},
	"module_workzone_007": {"texture_path": "res://assets/items/hardware/module.workzone007.png", "anchor_pos": Vector2(0.182, 0.497), "scale": 1.0},
	"module_workzone_008": {"texture_path": "res://assets/items/hardware/module.workzone008.png", "anchor_pos": Vector2(0.166, 0.501), "scale": 1.0},

	# Front
	"module_front_001": {"texture_path": "res://assets/items/hardware/module.front001.png", "anchor_pos": Vector2(0.568, 0.563), "scale": 1.0},
	"module_front_002": {"texture_path": "res://assets/items/hardware/module.front002.png", "anchor_pos": Vector2(0.574, 0.601), "scale": 0.5568},
	"module_front_003": {"texture_path": "res://assets/items/hardware/module.front003.png", "anchor_pos": Vector2(0.45, 0.59), "scale": 0.677},
	"module_front_004": {"texture_path": "res://assets/items/hardware/module.front004.png", "anchor_pos": Vector2(0.561, 0.576), "scale": 1.0},
	"module_front_005": {"texture_path": "res://assets/items/hardware/module.front005.png", "anchor_pos": Vector2(0.52, 0.586), "scale": 1.0},
	"module_front_006": {"texture_path": "res://assets/items/hardware/module.front006.png", "anchor_pos": Vector2(0.539, 0.584), "scale": 1.0},
	"module_front_007": {"texture_path": "res://assets/items/hardware/module.front007.png", "anchor_pos": Vector2(0.531, 0.611), "scale": 1.0},
	"module_front_008": {"texture_path": "res://assets/items/hardware/module.front008.png", "anchor_pos": Vector2(0.555, 0.569), "scale": 1.0}
}

func refresh_items(hardware_layer: Control, clear_layer_callable: Callable) -> void:
	clear_layer_callable.call(hardware_layer)

	var active_ids: Array[String] = []

	var sleep_id: String = PlayerState.get_active_module_for_zone("sleep")
	var workzone_id: String = PlayerState.get_active_module_for_zone("workzone")
	var front_id: String = PlayerState.get_active_module_for_zone("front")

	if not sleep_id.is_empty():
		active_ids.append(sleep_id)
	if not workzone_id.is_empty():
		active_ids.append(workzone_id)
	if not front_id.is_empty():
		active_ids.append(front_id)

	for item_id in active_ids:
		var data = module_visual_data.get(item_id, null)
		if data == null:
			push_error("Нет module visual data для item_id: " + item_id)
			continue

		var texture = load(data["texture_path"])
		if texture == null:
			push_error("Не удалось загрузить module текстуру: " + str(data["texture_path"]))
			continue

		var rect := TextureRect.new()
		rect.name = item_id
		rect.texture = texture
		rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		rect.stretch_mode = TextureRect.STRETCH_SCALE
		rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		rect.visible = true
		hardware_layer.add_child(rect)

func update_layer(hardware_layer: Control, cockpit_layer: Control, cockpit_texture: Texture2D) -> void:
	if cockpit_texture == null:
		return

	hardware_layer.position = cockpit_layer.position
	hardware_layer.size = cockpit_layer.size

	for child in hardware_layer.get_children():
		if child is TextureRect:
			var item_id := child.name
			var data = module_visual_data.get(item_id, null)
			if data == null:
				continue

			if child.texture == null:
				continue

			var anchor_pos: Vector2 = data["anchor_pos"]
			var scale: float = data.get("scale", 1.0)

			var texture_size: Vector2 = child.texture.get_size()
			var cockpit_scale_x: float = hardware_layer.size.x / cockpit_texture.get_size().x
			var cockpit_scale_y: float = hardware_layer.size.y / cockpit_texture.get_size().y

			var base_scale: float = min(cockpit_scale_x, cockpit_scale_y)
			var item_size: Vector2 = texture_size * base_scale * scale

			child.size = item_size
			child.position = Vector2(
				hardware_layer.size.x * anchor_pos.x - item_size.x * 0.5,
				hardware_layer.size.y * anchor_pos.y - item_size.y * 0.5
			)
