extends Control

@onready var storage_background: TextureRect = $StorageBackground
@onready var items_root: Control = $ItemsRoot
@onready var tooltip_panel: Panel = $TopInfoContainer/TooltipPanel
@onready var item_name_label: Label = $TopInfoContainer/TooltipPanel/VBoxContainer/ItemNameLabel
@onready var item_description_label: Label = $TopInfoContainer/TooltipPanel/VBoxContainer/ItemDescriptionLabel
@onready var action_button: Button = $TopInfoContainer/TooltipPanel/VBoxContainer/ActionButton

const ITEM_COUNT := 40
const SELECTED_BRIGHTNESS := 1.2
const NORMAL_BRIGHTNESS := 1.0
const INSTALLED_ALPHA := 0.5
const NORMAL_ALPHA := 1.0
const MOVE_STEP := 0.01
const MOVE_STEP_FINE := 0.001
const SCALE_STEP := 1.05
const SCALE_STEP_FINE := 1.01
const MIN_SIZE_RATIO := 0.02
const MAX_SIZE_RATIO := 0.25

var selected_item_id := "interior_plant_001"
var item_nodes: Dictionary = {}
var item_data: Dictionary = {}
var cargo_visual_data := {
	"interior_plant_001": {"texture_path": "res://assets/items/interior/plant001.png", "anchor_pos": Vector2(0.12, 0.18), "size_ratio": Vector2(0.055, 0.09)},
	"interior_plant_002": {"texture_path": "res://assets/items/interior/plant002.png", "anchor_pos": Vector2(0.225, 0.18), "size_ratio": Vector2(0.055, 0.09)},
	"interior_plant_003": {"texture_path": "res://assets/items/interior/plant003.png", "anchor_pos": Vector2(0.33, 0.18), "size_ratio": Vector2(0.055, 0.09)},
	"interior_plant_004": {"texture_path": "res://assets/items/interior/plant004.png", "anchor_pos": Vector2(0.435, 0.18), "size_ratio": Vector2(0.055, 0.09)},
	"interior_plant_005": {"texture_path": "res://assets/items/interior/plant005.png", "anchor_pos": Vector2(0.54, 0.18), "size_ratio": Vector2(0.055, 0.09)},
	"interior_plant_006": {"texture_path": "res://assets/items/interior/plant006.png", "anchor_pos": Vector2(0.645, 0.18), "size_ratio": Vector2(0.055, 0.09)},
	"interior_plant_007": {"texture_path": "res://assets/items/interior/plant007.png", "anchor_pos": Vector2(0.75, 0.18), "size_ratio": Vector2(0.055, 0.09)},
	"interior_plant_008": {"texture_path": "res://assets/items/interior/plant008.png", "anchor_pos": Vector2(0.855, 0.18), "size_ratio": Vector2(0.055, 0.09)},
	"interior_plant_009": {"texture_path": "res://assets/items/interior/plant009.png", "anchor_pos": Vector2(0.12, 0.35), "size_ratio": Vector2(0.055, 0.09)},
	"interior_plant_010": {"texture_path": "res://assets/items/interior/plant010.png", "anchor_pos": Vector2(0.225, 0.35), "size_ratio": Vector2(0.055, 0.09)},
	"interior_plant_011": {"texture_path": "res://assets/items/interior/plant011.png", "anchor_pos": Vector2(0.33, 0.35), "size_ratio": Vector2(0.055, 0.09)},
	"interior_plant_012": {"texture_path": "res://assets/items/interior/plant012.png", "anchor_pos": Vector2(0.435, 0.35), "size_ratio": Vector2(0.055, 0.09)},
	"interior_plant_013": {"texture_path": "res://assets/items/interior/plant013.png", "anchor_pos": Vector2(0.54, 0.35), "size_ratio": Vector2(0.055, 0.09)},
	"interior_plant_014": {"texture_path": "res://assets/items/interior/plant014.png", "anchor_pos": Vector2(0.645, 0.35), "size_ratio": Vector2(0.055, 0.09)},
	"interior_plant_015": {"texture_path": "res://assets/items/interior/plant015.png", "anchor_pos": Vector2(0.75, 0.35), "size_ratio": Vector2(0.055, 0.09)},
	"interior_plant_016": {"texture_path": "res://assets/items/interior/plant016.png", "anchor_pos": Vector2(0.855, 0.35), "size_ratio": Vector2(0.055, 0.09)},
	"interior_plant_017": {"texture_path": "res://assets/items/interior/plant017.png", "anchor_pos": Vector2(0.12, 0.52), "size_ratio": Vector2(0.055, 0.09)},
	"interior_plant_018": {"texture_path": "res://assets/items/interior/plant018.png", "anchor_pos": Vector2(0.225, 0.52), "size_ratio": Vector2(0.055, 0.09)},
	"interior_plant_019": {"texture_path": "res://assets/items/interior/plant019.png", "anchor_pos": Vector2(0.33, 0.52), "size_ratio": Vector2(0.055, 0.09)},
	"interior_plant_020": {"texture_path": "res://assets/items/interior/plant020.png", "anchor_pos": Vector2(0.435, 0.52), "size_ratio": Vector2(0.055, 0.09)},
	"interior_plant_021": {"texture_path": "res://assets/items/interior/plant021.png", "anchor_pos": Vector2(0.54, 0.52), "size_ratio": Vector2(0.055, 0.09)},
	"interior_plant_022": {"texture_path": "res://assets/items/interior/plant022.png", "anchor_pos": Vector2(0.645, 0.52), "size_ratio": Vector2(0.055, 0.09)},
	"interior_plant_023": {"texture_path": "res://assets/items/interior/plant023.png", "anchor_pos": Vector2(0.75, 0.52), "size_ratio": Vector2(0.055, 0.09)},
	"interior_plant_024": {"texture_path": "res://assets/items/interior/plant024.png", "anchor_pos": Vector2(0.855, 0.52), "size_ratio": Vector2(0.055, 0.09)},
	"interior_plant_025": {"texture_path": "res://assets/items/interior/plant025.png", "anchor_pos": Vector2(0.12, 0.69), "size_ratio": Vector2(0.055, 0.09)},
	"interior_plant_026": {"texture_path": "res://assets/items/interior/plant026.png", "anchor_pos": Vector2(0.225, 0.69), "size_ratio": Vector2(0.055, 0.09)},
	"interior_plant_027": {"texture_path": "res://assets/items/interior/plant027.png", "anchor_pos": Vector2(0.33, 0.69), "size_ratio": Vector2(0.055, 0.09)},
	"interior_plant_028": {"texture_path": "res://assets/items/interior/plant028.png", "anchor_pos": Vector2(0.435, 0.69), "size_ratio": Vector2(0.055, 0.09)},
	"interior_plant_029": {"texture_path": "res://assets/items/interior/plant029.png", "anchor_pos": Vector2(0.54, 0.69), "size_ratio": Vector2(0.055, 0.09)},
	"interior_plant_030": {"texture_path": "res://assets/items/interior/plant030.png", "anchor_pos": Vector2(0.645, 0.69), "size_ratio": Vector2(0.055, 0.09)},
	"interior_plant_031": {"texture_path": "res://assets/items/interior/plant031.png", "anchor_pos": Vector2(0.75, 0.69), "size_ratio": Vector2(0.055, 0.09)},
	"interior_plant_032": {"texture_path": "res://assets/items/interior/plant032.png", "anchor_pos": Vector2(0.855, 0.69), "size_ratio": Vector2(0.055, 0.09)},
	"interior_plant_033": {"texture_path": "res://assets/items/interior/plant033.png", "anchor_pos": Vector2(0.12, 0.86), "size_ratio": Vector2(0.055, 0.09)},
	"interior_plant_034": {"texture_path": "res://assets/items/interior/plant034.png", "anchor_pos": Vector2(0.225, 0.86), "size_ratio": Vector2(0.055, 0.09)},
	"interior_plant_035": {"texture_path": "res://assets/items/interior/plant035.png", "anchor_pos": Vector2(0.33, 0.86), "size_ratio": Vector2(0.055, 0.09)},
	"interior_plant_036": {"texture_path": "res://assets/items/interior/plant036.png", "anchor_pos": Vector2(0.435, 0.86), "size_ratio": Vector2(0.055, 0.09)},
	"interior_plant_037": {"texture_path": "res://assets/items/interior/plant037.png", "anchor_pos": Vector2(0.54, 0.86), "size_ratio": Vector2(0.055, 0.09)},
	"interior_plant_038": {"texture_path": "res://assets/items/interior/plant038.png", "anchor_pos": Vector2(0.645, 0.86), "size_ratio": Vector2(0.055, 0.09)},
	"interior_plant_039": {"texture_path": "res://assets/items/interior/plant039.png", "anchor_pos": Vector2(0.75, 0.86), "size_ratio": Vector2(0.055, 0.09)},
	"interior_plant_040": {"texture_path": "res://assets/items/interior/plant040.png", "anchor_pos": Vector2(0.855, 0.86), "size_ratio": Vector2(0.055, 0.09)}
}
var debug_enabled := true


func _ready() -> void:
	tooltip_panel.visible = false
	items_root.clip_contents = true
	items_root.z_index = 0
	$TopInfoContainer.z_index = 20
	_build_item_data()
	await get_tree().process_frame
	_create_item_nodes()
	action_button.pressed.connect(_on_action_button_pressed)

	if PlayerState.has_signal("interior_changed"):
		PlayerState.interior_changed.connect(_on_player_interior_changed)

	refresh()


func _build_item_data() -> void:
	item_data.clear()
	for i in range(1, ITEM_COUNT + 1):
		var item_id := _item_id_from_index(i - 1)
		item_data[item_id] = {
			"title": "Растение № %d" % i,
			"description": "Заглушка описания. Интерьерный предмет для кокпита, вариант %d." % i
		}


func _create_item_nodes() -> void:
	item_nodes.clear()

	for child in items_root.get_children():
		child.queue_free()

	for index in range(ITEM_COUNT):
		var item_id := _item_id_from_index(index)
		var visual_data: Dictionary = cargo_visual_data[item_id]
		var texture := load(visual_data["texture_path"]) as Texture2D
		if texture == null:
			push_error("Не удалось загрузить интерьерную текстуру склада: '%s'" % visual_data["texture_path"])
			continue

		var button := Button.new()
		button.name = item_id
		button.text = ""
		button.flat = true
		button.focus_mode = Control.FOCUS_NONE
		button.mouse_filter = Control.MOUSE_FILTER_STOP
		button.clip_contents = false
		button.pressed.connect(_on_item_pressed.bind(item_id))

		var rect := TextureRect.new()
		rect.name = "Icon"
		rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		rect.texture = texture

		button.add_child(rect)
		items_root.add_child(button)
		item_nodes[item_id] = button

	_update_item_layout()


func refresh() -> void:
	for item_key in item_nodes.keys():
		var item_id := String(item_key)
		var node: Control = item_nodes[item_id]
		var is_selected: bool = item_id == selected_item_id
		var installed: bool = PlayerState.is_interior_item_installed(item_id)
		_apply_item_visual_state(node, is_selected, installed)

	if selected_item_id.is_empty():
		tooltip_panel.visible = false
		return

	_show_selected_item_info()


func _apply_item_visual_state(node: Control, is_selected: bool, installed: bool) -> void:
	var brightness := SELECTED_BRIGHTNESS if is_selected else NORMAL_BRIGHTNESS
	var alpha := INSTALLED_ALPHA if installed else NORMAL_ALPHA
	node.modulate = Color(brightness, brightness, brightness, alpha)


func _show_selected_item_info() -> void:
	var data: Dictionary = item_data.get(selected_item_id, {})
	var zone_id: int = PlayerState.get_interior_item_zone(selected_item_id)
	var installed: bool = zone_id != -1
	var free_zone: int = PlayerState.get_first_free_interior_zone()

	item_name_label.text = String(data.get("title", "Неизвестный предмет"))
	item_description_label.text = String(data.get("description", "Описание отсутствует."))
	if installed:
		item_description_label.text += "\n\nУстановлен в зоне %d." % zone_id
	else:
		item_description_label.text += "\n\nНе установлен."

	action_button.text = "Убрать" if installed else "Установить"
	action_button.disabled = (not installed and free_zone == -1)
	tooltip_panel.visible = true


func _on_item_pressed(item_id: String) -> void:
	selected_item_id = item_id
	refresh()


func _on_action_button_pressed() -> void:
	if selected_item_id.is_empty():
		return

	if PlayerState.is_interior_item_installed(selected_item_id):
		PlayerState.uninstall_interior_item(selected_item_id)
	else:
		var target_zone := PlayerState.get_first_free_interior_zone()
		if target_zone != -1:
			PlayerState.install_interior_item(selected_item_id, target_zone)

	refresh()


func _on_player_interior_changed() -> void:
	refresh()


func _unhandled_input(event: InputEvent) -> void:
	if not debug_enabled:
		return
	if not visible:
		return
	if not (event is InputEventKey):
		return

	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return

	if _handle_debug_cycle_input(key_event):
		return

	_handle_debug_transform_input(key_event)


func _handle_debug_cycle_input(event: InputEventKey) -> bool:
	if event.keycode == KEY_MINUS or event.keycode == KEY_KP_SUBTRACT:
		_cycle_selected_item(-1)
		return true

	if event.keycode == KEY_EQUAL or event.keycode == KEY_PLUS or event.keycode == KEY_KP_ADD:
		_cycle_selected_item(1)
		return true

	return false


func _handle_debug_transform_input(event: InputEventKey) -> void:
	if selected_item_id.is_empty():
		return
	if not cargo_visual_data.has(selected_item_id):
		return

	var current_move_step := MOVE_STEP_FINE if event.shift_pressed else MOVE_STEP
	var current_scale_step := SCALE_STEP_FINE if event.shift_pressed else SCALE_STEP

	var changed := false
	var anchor_pos: Vector2 = cargo_visual_data[selected_item_id]["anchor_pos"]
	var size_ratio: Vector2 = cargo_visual_data[selected_item_id]["size_ratio"]

	if event.keycode == KEY_LEFT:
		anchor_pos.x -= current_move_step
		changed = true
	elif event.keycode == KEY_RIGHT:
		anchor_pos.x += current_move_step
		changed = true
	elif event.keycode == KEY_UP:
		anchor_pos.y -= current_move_step
		changed = true
	elif event.keycode == KEY_DOWN:
		anchor_pos.y += current_move_step
		changed = true
	elif event.keycode == KEY_BRACKETLEFT:
		size_ratio *= (1.0 / current_scale_step)
		changed = true
	elif event.keycode == KEY_BRACKETRIGHT:
		size_ratio *= current_scale_step
		changed = true
	elif event.keycode == KEY_P:
		print_selected_debug_item()
		return

	if not changed:
		return

	anchor_pos.x = clamp(anchor_pos.x, 0.0, 1.0)
	anchor_pos.y = clamp(anchor_pos.y, 0.0, 1.0)
	size_ratio.x = clamp(size_ratio.x, MIN_SIZE_RATIO, MAX_SIZE_RATIO)
	size_ratio.y = clamp(size_ratio.y, MIN_SIZE_RATIO, MAX_SIZE_RATIO)

	cargo_visual_data[selected_item_id]["anchor_pos"] = anchor_pos
	cargo_visual_data[selected_item_id]["size_ratio"] = size_ratio
	_update_item_layout()

	print(
		"Updated [interior.cargo] ", selected_item_id,
		" -> anchor_pos=", anchor_pos,
		" size_ratio=", size_ratio
	)


func _cycle_selected_item(direction: int) -> void:
	var current_index := _index_from_item_id(selected_item_id)
	var next_index := posmod(current_index + direction, ITEM_COUNT)
	selected_item_id = _item_id_from_index(next_index)
	refresh()
	print("Selected [interior.cargo]: ", selected_item_id)


func _update_item_layout() -> void:
	if storage_background == null or not is_instance_valid(storage_background):
		return
	if items_root == null or not is_instance_valid(items_root):
		return

	var background_size := storage_background.size
	if background_size.x <= 0.0 or background_size.y <= 0.0:
		return

	for item_key in item_nodes.keys():
		var item_id := String(item_key)
		var node: Control = item_nodes[item_id]
		var visual_data: Dictionary = cargo_visual_data[item_id]
		var anchor_pos: Vector2 = visual_data["anchor_pos"]
		var size_ratio: Vector2 = visual_data["size_ratio"]
		var icon_rect := node.get_node_or_null("Icon") as TextureRect
		var item_size := _calculate_preserved_item_size(
			icon_rect.texture if icon_rect != null else null,
			Vector2(background_size.x * size_ratio.x, background_size.y * size_ratio.y)
		)

		node.size = item_size
		node.position = Vector2(
			background_size.x * anchor_pos.x - item_size.x * 0.5,
			background_size.y * anchor_pos.y - item_size.y * 0.5
		)


func print_selected_debug_item() -> void:
	if not cargo_visual_data.has(selected_item_id):
		return

	var data: Dictionary = cargo_visual_data[selected_item_id]
	print("\"", selected_item_id, "\": {")
	print("\t\"texture_path\": \"", data["texture_path"], "\",")
	print("\t\"anchor_pos\": Vector2(", data["anchor_pos"].x, ", ", data["anchor_pos"].y, "),")
	print("\t\"size_ratio\": Vector2(", data["size_ratio"].x, ", ", data["size_ratio"].y, ")")
	print("}")


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_update_item_layout()


func _item_id_from_index(index: int) -> String:
	return "interior_plant_%03d" % (index + 1)


func _texture_path_from_index(index: int) -> String:
	return "res://assets/items/interior/plant%03d.png" % (index + 1)


func _index_from_item_id(item_id: String) -> int:
	var parts := item_id.split("_")
	if parts.size() == 0:
		return 0
	return clamp(int(parts[parts.size() - 1]) - 1, 0, ITEM_COUNT - 1)


func _calculate_preserved_item_size(texture: Texture2D, max_size: Vector2) -> Vector2:
	if texture == null:
		return max_size

	var texture_size := texture.get_size()
	if texture_size.x <= 0.0 or texture_size.y <= 0.0:
		return max_size

	var scale_value: float = min(max_size.x / texture_size.x, max_size.y / texture_size.y)
	return texture_size * scale_value
