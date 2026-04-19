extends Control

@onready var storage_background     = $StorageBackground
@onready var diagnostic_monitor_item = $DiagnosticMonitorItem
@onready var fire_suppression_item   = $FireSuppressionItem

@onready var tooltip_panel           = $BottomInfoContainer/TooltipPanel
@onready var item_name_label         = $BottomInfoContainer/TooltipPanel/VBoxContainer/ItemNameLabel
@onready var item_description_label  = $BottomInfoContainer/TooltipPanel/VBoxContainer/ItemDescriptionLabel
@onready var action_button           = $BottomInfoContainer/TooltipPanel/VBoxContainer/ActionButton

# Текущий выбранный модуль (пустая строка = ничего не выбрано)
var selected_item_id: String = ""

# Словарь: item_id → Button-узел в гриде
var item_nodes: Dictionary = {}

# Словарь: item_id → данные модуля (zone, title, description, icon_path)
var modules_data: Dictionary = {}

# Корневой узел динамически созданного грида модулей
var modules_grid_root: Control

const SELECTED_BRIGHTNESS := 1.2
const NORMAL_BRIGHTNESS   := 1.0
const INSTALLED_ALPHA     := 0.5
const NORMAL_ALPHA        := 1.0

# Описание всех зон: id зоны → [шаблон id, шаблон пути иконки, название зоны для UI]
const ZONE_CONFIGS := [
	["sleep",    "module_sleep_%03d",    "res://assets/items/hardware/pic.module.sleep%03d.png",    "Спальная зона"],
	["workzone", "module_workzone_%03d", "res://assets/items/hardware/pic.module.workzone%03d.png", "Рабочая зона"],
	["front",    "module_front_%03d",    "res://assets/items/hardware/pic.module.front%03d.png",    "Зона отдыха"],
	["panel",    "module_panel_%03d",    "res://assets/items/frontpanel/pic.frontpanel%03d.png",    "Передняя панель"],
]


func _ready() -> void:
	tooltip_panel.visible = false

	# Скрываем декоративные узлы — они не интерактивны
	diagnostic_monitor_item.visible = false
	diagnostic_monitor_item.mouse_filter = Control.MOUSE_FILTER_IGNORE

	fire_suppression_item.visible = false
	fire_suppression_item.mouse_filter = Control.MOUSE_FILTER_IGNORE

	_build_modules_data()

	# Ждём один кадр, чтобы size панели был корректно вычислен
	await get_tree().process_frame
	_create_modules_grid()

	action_button.pressed.connect(_on_action_button_pressed)

	# Подписываемся на изменения модулей игрока (если сигнал существует)
	if PlayerState.has_signal("modules_changed"):
		PlayerState.modules_changed.connect(_on_player_modules_changed)

	refresh()


# Заполняем modules_data для всех зон и модулей
func _build_modules_data() -> void:
	modules_data.clear()

	for zone_cfg in ZONE_CONFIGS:
		var zone_id: String    = zone_cfg[0]
		var id_template: String    = zone_cfg[1]
		var icon_template: String  = zone_cfg[2]
		var zone_label: String     = zone_cfg[3]

		for i in range(1, 9):
			var item_id := id_template % i
			modules_data[item_id] = {
				"id":          item_id,
				"zone":        zone_id,
				"title":       "%s, Модуль %d" % [zone_label, i],
				"description": "Тестовое описание. %s, модуль %d." % [zone_label, i],
				"icon_path":   icon_template % i,
			}

	# Отдельное описание для панели (отличается от шаблона)
	for i in range(1, 9):
		var panel_id := "module_panel_%03d" % i
		modules_data[panel_id]["description"] = \
			"Заменяет верхнюю переднюю панель кокпита на вариант %d." % i


# Создаём динамический грид кнопок модулей
func _create_modules_grid() -> void:
	item_nodes.clear()

	if modules_grid_root != null and is_instance_valid(modules_grid_root):
		modules_grid_root.queue_free()

	modules_grid_root = Control.new()
	modules_grid_root.name = "ModulesGridRoot"
	modules_grid_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	modules_grid_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(modules_grid_root)

	# Размещаем грид под BottomInfoContainer в иерархии
	var bottom_info_index := $BottomInfoContainer.get_index()
	move_child(modules_grid_root, bottom_info_index)

	var columns   := 8
	var icon_size := Vector2(56, 56)
	var cell_w    := 72.0
	var cell_h    := 72.0
	var row_gap   := 24.0

	var grid_width  := (columns - 1) * cell_w + icon_size.x
	var left_margin := (size.x - grid_width) * 0.5 if size.x > 0.0 else 180.0
	var top_margin  := 140.0

	for row_index in range(ZONE_CONFIGS.size()):
		var zone_id: String = ZONE_CONFIGS[row_index][0]
		_create_zone_row(zone_id, row_index, left_margin, top_margin, cell_w, cell_h, row_gap, icon_size)


# Создаём одну строку грида для заданной зоны
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
		var item_id: String   = ids[col]
		var data: Dictionary  = modules_data[item_id]

		# Кнопка-контейнер для иконки модуля
		var button := Button.new()
		button.name             = item_id
		button.text             = ""
		button.flat             = true
		button.clip_contents    = true
		button.focus_mode       = Control.FOCUS_NONE
		button.mouse_filter     = Control.MOUSE_FILTER_STOP
		button.custom_minimum_size = icon_size
		button.size             = icon_size
		button.position         = Vector2(
			left_margin + col * cell_w,
			top_margin + row_index * (cell_h + row_gap)
		)

		# Иконка внутри кнопки
		var icon_rect := TextureRect.new()
		icon_rect.name         = "Icon"
		icon_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon_rect.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
		icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

		var texture: Texture2D = load(data["icon_path"])
		if texture != null:
			icon_rect.texture = texture
		else:
			push_error("Не удалось загрузить иконку модуля: '%s'" % data["icon_path"])

		button.add_child(icon_rect)
		button.pressed.connect(_on_item_pressed.bind(item_id))

		modules_grid_root.add_child(button)
		item_nodes[item_id] = button


# Возвращает список item_id для зоны (8 штук)
func _get_module_ids_for_zone(zone_id: String) -> Array[String]:
	var result: Array[String] = []
	# Ищем шаблон id для этой зоны в ZONE_CONFIGS
	for zone_cfg in ZONE_CONFIGS:
		if zone_cfg[0] == zone_id:
			for i in range(1, 9):
				result.append(zone_cfg[1] % i)
			break
	return result


# Обновляем визуальное состояние всех модулей и tooltip
func refresh() -> void:
	for item_id in item_nodes.keys():
		var node: Control    = item_nodes[item_id]
		var found: bool      = PlayerState.has_found_module(item_id)
		var zone_id: String  = modules_data[item_id]["zone"]
		var installed: bool  = PlayerState.is_module_installed(item_id, zone_id)
		var is_selected: bool = item_id == selected_item_id

		node.visible      = found
		node.mouse_filter = Control.MOUSE_FILTER_STOP if found else Control.MOUSE_FILTER_IGNORE

		if found:
			_apply_item_visual_state(node, is_selected, installed)
		else:
			node.modulate = Color.WHITE

	# Если ничего не выбрано или выбранный предмет больше недоступен — скрываем tooltip
	if selected_item_id.is_empty():
		tooltip_panel.visible = false
		return

	if not PlayerState.has_found_module(selected_item_id):
		selected_item_id = ""
		tooltip_panel.visible = false
		return

	_show_selected_item_info()


# Применяем цвет/прозрачность к кнопке модуля
func _apply_item_visual_state(node: Control, is_selected: bool, installed: bool) -> void:
	var brightness := SELECTED_BRIGHTNESS if is_selected else NORMAL_BRIGHTNESS
	var alpha      := INSTALLED_ALPHA if installed else NORMAL_ALPHA
	node.modulate  = Color(brightness, brightness, brightness, alpha)


# Обработка клика по модулю
func _on_item_pressed(item_id: String) -> void:
	if not PlayerState.has_found_module(item_id):
		return
	selected_item_id = item_id
	refresh()


# Заполняем tooltip данными выбранного модуля
func _show_selected_item_info() -> void:
	if selected_item_id.is_empty():
		tooltip_panel.visible = false
		return

	var data = modules_data.get(selected_item_id, null)
	if data == null:
		item_name_label.text        = "Неизвестный модуль"
		item_description_label.text = "Описание отсутствует."
		action_button.text          = "Установить"
		action_button.disabled      = true
		tooltip_panel.visible       = true
		return

	var zone_id: String  = data["zone"]
	var installed: bool  = PlayerState.is_module_installed(selected_item_id, zone_id)

	item_name_label.text        = data["title"]
	item_description_label.text = data["description"]
	action_button.text          = "Убрать" if installed else "Установить"
	action_button.disabled      = false
	tooltip_panel.visible       = true


# Обработка кнопки "Установить / Убрать"
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


# Реакция на внешнее изменение модулей (например, из другого места игры)
func _on_player_modules_changed() -> void:
	refresh()
