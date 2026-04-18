extends Control

@onready var storage_background = $StorageBackground
@onready var diagnostic_monitor_item = $DiagnosticMonitorItem
@onready var fire_suppression_item = $FireSuppressionItem

@onready var tooltip_panel = $BottomInfoContainer/TooltipPanel
@onready var item_name_label = $BottomInfoContainer/TooltipPanel/VBoxContainer/ItemNameLabel
@onready var item_description_label = $BottomInfoContainer/TooltipPanel/VBoxContainer/ItemDescriptionLabel
@onready var action_button = $BottomInfoContainer/TooltipPanel/VBoxContainer/ActionButton

var selected_item_id: String = ""

var item_nodes: Dictionary = {}
var modules_data: Dictionary = {}
var modules_grid_root: Control

const SELECTED_BRIGHTNESS := 1.2
const NORMAL_BRIGHTNESS := 1.0
const INSTALLED_ALPHA := 0.5
const NORMAL_ALPHA := 1.0


func _ready() -> void:
	tooltip_panel.visible = false

	diagnostic_monitor_item.visible = false
	diagnostic_monitor_item.mouse_filter = Control.MOUSE_FILTER_IGNORE

	fire_suppression_item.visible = false
	fire_suppression_item.mouse_filter = Control.MOUSE_FILTER_IGNORE

	_build_modules_data()

	await get_tree().process_frame
	_create_modules_grid()

	action_button.pressed.connect(_on_action_button_pressed)

	if PlayerState.has_signal("modules_changed"):
		PlayerState.modules_changed.connect(_on_player_modules_changed)

	refresh()


func _build_modules_data() -> void:
	modules_data.clear()

	for i in range(1, 9):
		var id := "module_sleep_%03d" % i
		modules_data[id] = {
			"id": id,
			"zone": "sleep",
			"title": "Спальная зона, Модуль %d" % i,
			"description": "Тестовое описание. Спальная зона, модуль %d." % i,
			"icon_path": "res://assets/items/hardware/pic.module.sleep%03d.png" % i
		}

	for i in range(1, 9):
		var id := "module_workzone_%03d" % i
		modules_data[id] = {
			"id": id,
			"zone": "workzone",
			"title": "Рабочая зона, Модуль %d" % i,
			"description": "Тестовое описание. Рабочая зона, модуль %d." % i,
			"icon_path": "res://assets/items/hardware/pic.module.workzone%03d.png" % i
		}

	for i in range(1, 9):
		var id := "module_front_%03d" % i
		modules_data[id] = {
			"id": id,
			"zone": "front",
			"title": "Зона отдыха, Модуль %d" % i,
			"description": "Тестовое описание. Зона отдыха, модуль %d." % i,
			"icon_path": "res://assets/items/hardware/pic.module.front%03d.png" % i
		}

	for i in range(1, 9):
		var panel_id := "module_panel_%03d" % i
		modules_data[panel_id] = {
			"id": panel_id,
			"zone": "panel",
			"title": "Передняя панель, модуль %d" % i,
			"description": "Заменяет верхнюю переднюю панель кокпита на вариант %d." % i,
			"icon_path": "res://assets/items/frontpanel/pic.frontpanel%03d.png" % i
		}


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

	var columns := 8
	var icon_size := Vector2(56, 56)
	var cell_w := 72.0
	var cell_h := 72.0
	var row_gap := 24.0

	var grid_width := (columns - 1) * cell_w + icon_size.x
	var left_margin := (size.x - grid_width) * 0.5
	var top_margin := 140.0

	if size.x <= 0.0:
		left_margin = 180.0

	_create_zone_row("sleep", 0, left_margin, top_margin, cell_w, cell_h, row_gap, icon_size)
	_create_zone_row("workzone", 1, left_margin, top_margin, cell_w, cell_h, row_gap, icon_size)
	_create_zone_row("front", 2, left_margin, top_margin, cell_w, cell_h, row_gap, icon_size)
	_create_zone_row("panel", 3, left_margin, top_margin, cell_w, cell_h, row_gap, icon_size)


func _create_zone_row(
	zone_id: String,
	row_index: int,
	left_margin: float,
	top_margin: float,
	cell_w: float,
	cell_h: float,
	row_gap: float,
	icon_size: Vector2
) -> void:
	var ids := _get_module_ids_for_zone(zone_id)

	for col in range(ids.size()):
		var item_id: String = ids[col]
		var data: Dictionary = modules_data[item_id]

		var button := Button.new()
		button.name = item_id
		button.text = ""
		button.flat = true
		button.clip_contents = true
		button.focus_mode = Control.FOCUS_NONE
		button.mouse_filter = Control.MOUSE_FILTER_STOP
		button.custom_minimum_size = icon_size
		button.size = icon_size
		button.position = Vector2(
			left_margin + col * cell_w,
			top_margin + row_index * (cell_h + row_gap)
		)

		var icon_rect := TextureRect.new()
		icon_rect.name = "Icon"
		icon_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

		var texture: Texture2D = load(data["icon_path"])
		if texture != null:
			icon_rect.texture = texture
		else:
			push_error("Не удалось загрузить иконку модуля: " + str(data["icon_path"]))

		button.add_child(icon_rect)
		button.pressed.connect(_on_item_pressed.bind(item_id))

		modules_grid_root.add_child(button)
		item_nodes[item_id] = button


func _get_module_ids_for_zone(zone_id: String) -> Array[String]:
	var result: Array[String] = []

	for i in range(1, 9):
		match zone_id:
			"sleep":
				result.append("module_sleep_%03d" % i)
			"workzone":
				result.append("module_workzone_%03d" % i)
			"front":
				result.append("module_front_%03d" % i)
			"panel":
				result.append("module_panel_%03d" % i)

	return result


func refresh() -> void:
	for item_id in item_nodes.keys():
		var node: Control = item_nodes[item_id]
		var found = PlayerState.has_found_module(item_id)
		var zone_id: String = modules_data[item_id]["zone"]
		var installed = PlayerState.is_module_installed(item_id, zone_id)
		var is_selected: bool = item_id == selected_item_id

		node.visible = found
		node.mouse_filter = Control.MOUSE_FILTER_STOP if found else Control.MOUSE_FILTER_IGNORE

		if found:
			_apply_item_visual_state(node, is_selected, installed)
		else:
			node.modulate = Color(1.0, 1.0, 1.0, 1.0)

	if selected_item_id.is_empty():
		tooltip_panel.visible = false
		return

	if not PlayerState.has_found_module(selected_item_id):
		selected_item_id = ""
		tooltip_panel.visible = false
		return

	_show_selected_item_info()


func _apply_item_visual_state(node: Control, is_selected: bool, installed: bool) -> void:
	var brightness := SELECTED_BRIGHTNESS if is_selected else NORMAL_BRIGHTNESS
	var alpha := INSTALLED_ALPHA if installed else NORMAL_ALPHA

	node.modulate = Color(brightness, brightness, brightness, alpha)


func _on_item_pressed(item_id: String) -> void:
	if not PlayerState.has_found_module(item_id):
		return

	selected_item_id = item_id
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
		tooltip_panel.visible = true
		return

	item_name_label.text = data["title"]
	item_description_label.text = data["description"]

	var zone_id: String = data["zone"]
	var installed = PlayerState.is_module_installed(selected_item_id, zone_id)
	action_button.text = "Убрать" if installed else "Установить"
	action_button.disabled = false

	tooltip_panel.visible = true


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
