extends Control

const ShipDebugPositioningController = preload("res://scripts/ship/ship_debug_positioning_controller.gd")

@onready var storage_background: TextureRect = $StorageBackground
@onready var diagnostic_monitor_item: TextureRect = $DiagnosticMonitorItem
@onready var fire_suppression_item: TextureRect = $FireSuppressionItem

@onready var tooltip_panel: Panel = $BottomInfoContainer/TooltipPanel
@onready var item_name_label: Label = $BottomInfoContainer/TooltipPanel/VBoxContainer/ItemNameLabel
@onready var item_description_label: Label = $BottomInfoContainer/TooltipPanel/VBoxContainer/ItemDescriptionLabel
@onready var action_button: Button = $BottomInfoContainer/TooltipPanel/VBoxContainer/ActionButton

const SELECTED_BRIGHTNESS := 1.2
const NORMAL_BRIGHTNESS := 1.0
const INSTALLED_ALPHA := 0.5
const NORMAL_ALPHA := 1.0
const MODULES_PER_ZONE := 10

const ZONE_CONFIGS := [
	["sleep", "module_sleep_%03d", "res://assets/items/hardware/pic.module.sleep%03d.png", "Спальная зона"],
	["workzone", "module_workzone_%03d", "res://assets/items/hardware/pic.module.workzone%03d.png", "Рабочая зона"],
	["front", "module_front_%03d", "res://assets/items/hardware/pic.module.front%03d.png", "Зона отдыха"],
	["panel", "module_panel_%03d", "res://assets/items/frontpanel/pic.frontpanel%03d.png", "Передняя панель"],
]

var selected_item_id: String = ""
var item_nodes: Dictionary = {}
var modules_data: Dictionary = {}
var cargo_visual_data: Dictionary = {}
var cargo_visual_overrides := {
	"module_sleep_001": {"anchor_pos": Vector2(0.2140, 0.241),"size_ratio": Vector2(0.0916, 0.1644)},
	"module_sleep_002": {"anchor_pos": Vector2(0.2780, 0.241),"size_ratio": Vector2(0.0916, 0.1644)},
	"module_sleep_003": {"anchor_pos": Vector2(0.3420, 0.242),"size_ratio": Vector2(0.0916, 0.1644)},
	"module_sleep_004": {"anchor_pos": Vector2(0.4050, 0.242),"size_ratio": Vector2(0.0916, 0.1644)},
	"module_sleep_005": {"anchor_pos": Vector2(0.4680, 0.242),"size_ratio": Vector2(0.0916, 0.1644)},
	"module_sleep_006": {"anchor_pos": Vector2(0.5310, 0.242),"size_ratio": Vector2(0.0916, 0.1644)},
	"module_sleep_007": {"anchor_pos": Vector2(0.5950, 0.241),"size_ratio": Vector2(0.0916, 0.1644)},
	"module_sleep_008": {"anchor_pos": Vector2(0.6575, 0.241),"size_ratio": Vector2(0.0916, 0.1644)},
	"module_sleep_009": {"anchor_pos": Vector2(0.7215, 0.241),"size_ratio": Vector2(0.0916, 0.1644)},
	"module_sleep_010": {"anchor_pos": Vector2(0.7855, 0.241),"size_ratio": Vector2(0.0916, 0.1644)},
	"module_workzone_001": {"anchor_pos": Vector2(0.2140, 0.4150),"size_ratio": Vector2(0.0908, 0.1629)},
	"module_workzone_002": {"anchor_pos": Vector2(0.2780, 0.4150),"size_ratio": Vector2(0.0908, 0.1629)},
	"module_workzone_003": {"anchor_pos": Vector2(0.3420, 0.4150),"size_ratio": Vector2(0.0908, 0.1629)},
	"module_workzone_004": {"anchor_pos": Vector2(0.4050, 0.4150),"size_ratio": Vector2(0.0908, 0.1629)},
	"module_workzone_005": {"anchor_pos": Vector2(0.4680, 0.4150),"size_ratio": Vector2(0.0908, 0.1629)},
	"module_workzone_006": {"anchor_pos": Vector2(0.5310, 0.4150),"size_ratio": Vector2(0.0908, 0.1629)},
	"module_workzone_007": {"anchor_pos": Vector2(0.5950, 0.4150),"size_ratio": Vector2(0.0908, 0.1629)},
	"module_workzone_008": {"anchor_pos": Vector2(0.6575, 0.4150),"size_ratio": Vector2(0.0908, 0.1629)},
	"module_workzone_009": {"anchor_pos": Vector2(0.7215, 0.4150),"size_ratio": Vector2(0.0908, 0.1629)},
	"module_workzone_010": {"anchor_pos": Vector2(0.7855, 0.4150),"size_ratio": Vector2(0.0908, 0.1629)},
	"module_front_001": {"anchor_pos": Vector2(0.2130, 0.5900),"size_ratio": Vector2(0.0912, 0.1636)},
	"module_front_002": {"anchor_pos": Vector2(0.2780, 0.5900),"size_ratio": Vector2(0.0912, 0.1636)},
	"module_front_003": {"anchor_pos": Vector2(0.3420, 0.5900),"size_ratio": Vector2(0.0912, 0.1636)},
	"module_front_004": {"anchor_pos": Vector2(0.4050, 0.5900),"size_ratio": Vector2(0.0912, 0.1636)},
	"module_front_005": {"anchor_pos": Vector2(0.4680, 0.5900),"size_ratio": Vector2(0.0912, 0.1636)},
	"module_front_006": {"anchor_pos": Vector2(0.5310, 0.5900),"size_ratio": Vector2(0.0912, 0.1636)},
	"module_front_007": {"anchor_pos": Vector2(0.5950, 0.5900),"size_ratio": Vector2(0.0912, 0.1636)},
	"module_front_008": {"anchor_pos": Vector2(0.6575, 0.5900),"size_ratio": Vector2(0.0912, 0.1636)},
	"module_front_009": {"anchor_pos": Vector2(0.7215, 0.5900),"size_ratio": Vector2(0.0912, 0.1636)},
	"module_front_010": {"anchor_pos": Vector2(0.7855, 0.5900),"size_ratio": Vector2(0.0912, 0.1636)},
	"module_panel_001": {"anchor_pos": Vector2(0.2140, 0.7630),"size_ratio": Vector2(0.0909, 0.1629)},
	"module_panel_002": {"anchor_pos": Vector2(0.2780, 0.7630),"size_ratio": Vector2(0.0909, 0.1629)},
	"module_panel_003": {"anchor_pos": Vector2(0.3420, 0.7630),"size_ratio": Vector2(0.0909, 0.1629)},
	"module_panel_004": {"anchor_pos": Vector2(0.4050, 0.7630),"size_ratio": Vector2(0.0909, 0.1629)},
	"module_panel_005": {"anchor_pos": Vector2(0.4680, 0.7630),"size_ratio": Vector2(0.0909, 0.1629)},
	"module_panel_006": {"anchor_pos": Vector2(0.5310, 0.7630),"size_ratio": Vector2(0.0909, 0.1629)},
	"module_panel_007": {"anchor_pos": Vector2(0.5950, 0.7630),"size_ratio": Vector2(0.0909, 0.1629)},
	"module_panel_008": {"anchor_pos": Vector2(0.6575, 0.7630),"size_ratio": Vector2(0.0909, 0.1629)},
	"module_panel_009": {"anchor_pos": Vector2(0.7215, 0.7630),"size_ratio": Vector2(0.0909, 0.1629)},
	"module_panel_010": {"anchor_pos": Vector2(0.7855, 0.7630),"size_ratio": Vector2(0.0909, 0.1629)},



}
var modules_grid_root: Control
var debug_controller := ShipDebugPositioningController.new()
var tooltip_rects := {
	"left": Rect2(Vector2(0.020, 0.200), Vector2(0.160, 0.600)),
	"right": Rect2(Vector2(0.820, 0.200), Vector2(0.160, 0.600)),
}


func _ready() -> void:
	tooltip_panel.visible = false
	tooltip_panel.clip_contents = true
	item_name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	item_name_label.clip_text = true
	item_description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	item_description_label.clip_text = true
	item_description_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	action_button.size_flags_horizontal = Control.SIZE_SHRINK_END
	action_button.size_flags_vertical = Control.SIZE_SHRINK_END
	$BottomInfoContainer.z_index = 100
	debug_controller.selected_layer = "hardware.cargo"
	debug_controller.selected_item_id = "module_sleep_001"

	diagnostic_monitor_item.visible = false
	diagnostic_monitor_item.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fire_suppression_item.visible = false
	fire_suppression_item.mouse_filter = Control.MOUSE_FILTER_IGNORE

	_build_modules_data()
	_build_cargo_visual_data()

	await get_tree().process_frame
	_create_modules_grid()

	action_button.pressed.connect(_on_action_button_pressed)

	if PlayerState.has_signal("modules_changed"):
		PlayerState.modules_changed.connect(_on_player_modules_changed)

	refresh()


func _build_modules_data() -> void:
	modules_data.clear()

	for zone_cfg in ZONE_CONFIGS:
		var zone_id: String = zone_cfg[0]
		var id_template: String = zone_cfg[1]
		var icon_template: String = zone_cfg[2]
		var zone_label: String = zone_cfg[3]

		for i in range(1, MODULES_PER_ZONE + 1):
			var item_id := id_template % i
			modules_data[item_id] = {
				"id": item_id,
				"zone": zone_id,
				"title": "%s, модуль %d" % [zone_label, i],
				"description": "Тестовое описание. %s, модуль %d." % [zone_label, i],
				"icon_path": icon_template % i,
			}

	for i in range(1, MODULES_PER_ZONE + 1):
		var panel_id := "module_panel_%03d" % i
		modules_data[panel_id]["description"] = "Заменяет верхнюю переднюю панель кокпита на вариант %d." % i


func _build_cargo_visual_data() -> void:
	cargo_visual_data.clear()

	var x_start := 0.369
	var x_step := 0.0375
	var y_start := 0.156
	var y_step := 0.089
	var default_size := Vector2(0.029, 0.052)

	for row_index in range(ZONE_CONFIGS.size()):
		var zone_id: String = ZONE_CONFIGS[row_index][0]
		var ids := _get_module_ids_for_zone(zone_id)
		for col in range(ids.size()):
			var item_id: String = ids[col]
			cargo_visual_data[item_id] = {
				"texture_path": modules_data[item_id]["icon_path"],
				"anchor_pos": Vector2(x_start + col * x_step, y_start + row_index * y_step),
				"size_ratio": default_size,
			}

	for item_id in cargo_visual_overrides.keys():
		if not cargo_visual_data.has(item_id):
			continue
		var override_data: Dictionary = cargo_visual_overrides[item_id]
		if override_data.has("anchor_pos"):
			cargo_visual_data[item_id]["anchor_pos"] = override_data["anchor_pos"]
		if override_data.has("size_ratio"):
			cargo_visual_data[item_id]["size_ratio"] = override_data["size_ratio"]


func _create_modules_grid() -> void:
	item_nodes.clear()

	if modules_grid_root != null and is_instance_valid(modules_grid_root):
		modules_grid_root.queue_free()

	modules_grid_root = Control.new()
	modules_grid_root.name = "ModulesGridRoot"
	modules_grid_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	modules_grid_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(modules_grid_root)

	var bottom_info_index := $BottomInfoContainer.get_index()
	move_child(modules_grid_root, bottom_info_index)

	for zone_cfg in ZONE_CONFIGS:
		var zone_id: String = zone_cfg[0]
		_create_zone_row(zone_id)

	_update_item_layout()


func _create_zone_row(zone_id: String) -> void:
	for item_id in _get_module_ids_for_zone(zone_id):
		var data: Dictionary = modules_data[item_id]
		var button := Button.new()
		button.name = item_id
		button.text = ""
		button.flat = true
		button.clip_contents = true
		button.focus_mode = Control.FOCUS_NONE
		button.mouse_filter = Control.MOUSE_FILTER_STOP
		button.custom_minimum_size = Vector2.ZERO
		button.pressed.connect(_on_item_pressed.bind(item_id))

		var icon_rect := TextureRect.new()
		icon_rect.name = "Icon"
		icon_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

		var texture := load(data["icon_path"]) as Texture2D
		if texture != null:
			icon_rect.texture = texture
		else:
			push_error("Не удалось загрузить иконку модуля: '%s'" % data["icon_path"])

		button.add_child(icon_rect)
		modules_grid_root.add_child(button)
		item_nodes[item_id] = button


func _get_module_ids_for_zone(zone_id: String) -> Array[String]:
	var result: Array[String] = []
	for zone_cfg in ZONE_CONFIGS:
		if zone_cfg[0] == zone_id:
			for i in range(1, MODULES_PER_ZONE + 1):
				result.append(zone_cfg[1] % i)
			break
	return result


func refresh() -> void:
	for item_key in item_nodes.keys():
		var item_id := String(item_key)
		var node: Control = item_nodes[item_id]
		var found: bool = PlayerState.has_found_module(item_id)
		var zone_id: String = modules_data[item_id]["zone"]
		var installed: bool = PlayerState.is_module_installed(item_id, zone_id)
		var is_selected: bool = item_id == selected_item_id

		node.visible = found
		node.mouse_filter = Control.MOUSE_FILTER_STOP if found else Control.MOUSE_FILTER_IGNORE
		node.modulate = _get_item_modulate(is_selected, installed) if found else Color.WHITE

	if selected_item_id.is_empty():
		tooltip_panel.visible = false
		return

	if not PlayerState.has_found_module(selected_item_id):
		selected_item_id = ""
		tooltip_panel.visible = false
		return

	_show_selected_item_info()


func _get_item_modulate(is_selected: bool, installed: bool) -> Color:
	var brightness := SELECTED_BRIGHTNESS if is_selected else NORMAL_BRIGHTNESS
	var alpha := INSTALLED_ALPHA if installed else NORMAL_ALPHA
	return Color(brightness, brightness, brightness, alpha)


func _on_item_pressed(item_id: String) -> void:
	if not PlayerState.has_found_module(item_id):
		return

	selected_item_id = item_id
	debug_controller.selected_item_id = item_id
	refresh()


func _show_selected_item_info() -> void:
	if selected_item_id.is_empty():
		tooltip_panel.visible = false
		return

	var data = modules_data.get(selected_item_id, null)
	if data == null:
		item_name_label.text = "Неизвестный модуль"
		item_description_label.text = "Описание отсутствует."
		action_button.text = "Установить"
		action_button.disabled = true
		_update_tooltip_layout()
		tooltip_panel.visible = true
		call_deferred("_update_tooltip_layout")
		return

	var zone_id: String = data["zone"]
	var installed: bool = PlayerState.is_module_installed(selected_item_id, zone_id)

	item_name_label.text = data["title"]
	item_description_label.text = data["description"]
	action_button.text = "Убрать" if installed else "Установить"
	action_button.disabled = false
	_update_tooltip_layout()
	tooltip_panel.visible = true
	call_deferred("_update_tooltip_layout")


func _on_action_button_pressed() -> void:
	if selected_item_id.is_empty():
		return
	if not PlayerState.has_found_module(selected_item_id):
		return

	var data = modules_data.get(selected_item_id, null)
	if data == null:
		return

	var zone_id: String = data["zone"]
	if PlayerState.is_module_installed(selected_item_id, zone_id):
		PlayerState.uninstall_module(zone_id)
	else:
		PlayerState.install_module(selected_item_id, zone_id)

	refresh()


func _on_player_modules_changed() -> void:
	refresh()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if not (event is InputEventKey):
		return

	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return

	var handled := debug_controller.handle_cargo_input(key_event, cargo_visual_data, Callable(self, "_update_item_layout"))
	if handled:
		selected_item_id = debug_controller.selected_item_id
		refresh()
		get_viewport().set_input_as_handled()


func _update_item_layout() -> void:
	if modules_grid_root == null or not is_instance_valid(modules_grid_root):
		return

	var background_rect := _get_drawn_background_rect(storage_background)
	if background_rect.size.x <= 0.0 or background_rect.size.y <= 0.0:
		return

	for item_id in item_nodes.keys():
		if not cargo_visual_data.has(item_id):
			continue

		var node: Control = item_nodes[item_id]
		var data: Dictionary = cargo_visual_data[item_id]
		var anchor_pos: Vector2 = data["anchor_pos"]
		var size_ratio: Vector2 = data["size_ratio"]
		var icon_rect := node.get_node_or_null("Icon") as TextureRect
		var item_size := _calculate_preserved_item_size(
			icon_rect.texture if icon_rect != null else null,
			background_rect.size * size_ratio
		)

		node.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
		node.size = item_size
		node.position = background_rect.position + Vector2(
			background_rect.size.x * anchor_pos.x - item_size.x * 0.5,
			background_rect.size.y * anchor_pos.y - item_size.y * 0.5
		)

	_update_tooltip_layout()


func _update_tooltip_layout() -> void:
	var background_rect := _get_drawn_background_rect(storage_background)
	if background_rect.size.x <= 0.0 or background_rect.size.y <= 0.0:
		return

	var side := _get_tooltip_side_for_selected_module()
	var normalized_rect: Rect2 = tooltip_rects[side]
	var popup_position := background_rect.position + normalized_rect.position * background_rect.size
	var popup_size := normalized_rect.size * background_rect.size
	var container := $BottomInfoContainer as Control

	container.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	container.custom_minimum_size = Vector2.ZERO
	container.position = popup_position
	container.size = popup_size
	tooltip_panel.custom_minimum_size = Vector2.ZERO
	tooltip_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tooltip_panel.offset_left = 0.0
	tooltip_panel.offset_top = 0.0
	tooltip_panel.offset_right = 0.0
	tooltip_panel.offset_bottom = 0.0

	var vbox := tooltip_panel.get_node_or_null("VBoxContainer") as VBoxContainer
	if vbox != null:
		vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		vbox.clip_contents = true
		vbox.offset_left = 14.0
		vbox.offset_top = 14.0
		vbox.offset_right = -14.0
		vbox.offset_bottom = -14.0


func _get_tooltip_side_for_selected_module() -> String:
	if selected_item_id.is_empty():
		return "left"

	var parts := selected_item_id.split("_")
	if parts.is_empty():
		return "left"

	var index := int(parts[parts.size() - 1])
	return "left" if index <= 5 else "right"


func _get_drawn_background_rect(background: TextureRect) -> Rect2:
	if background == null or not is_instance_valid(background):
		return Rect2()

	var viewport_size := background.size
	if background.texture == null:
		return Rect2(Vector2.ZERO, viewport_size)

	var texture_size := background.texture.get_size()
	if texture_size.x <= 0.0 or texture_size.y <= 0.0 or viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return Rect2(Vector2.ZERO, viewport_size)

	var scale_value: float = max(viewport_size.x / texture_size.x, viewport_size.y / texture_size.y)
	var drawn_size := texture_size * scale_value
	var drawn_position := (viewport_size - drawn_size) * 0.5
	return Rect2(drawn_position, drawn_size)


func _calculate_preserved_item_size(texture: Texture2D, max_size: Vector2) -> Vector2:
	if texture == null:
		return max_size

	var texture_size := texture.get_size()
	if texture_size.x <= 0.0 or texture_size.y <= 0.0:
		return max_size

	var scale_value: float = min(max_size.x / texture_size.x, max_size.y / texture_size.y)
	return texture_size * scale_value


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and is_node_ready():
		_update_item_layout()
		_update_tooltip_layout()
