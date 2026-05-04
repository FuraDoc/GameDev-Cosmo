extends Control

# Подключаем общий контроллер ручного позиционирования предметов в Cargo Bay.
const ShipDebugPositioningController = preload("res://scripts/ship/ship_debug_positioning_controller.gd")

# Узел фоновой картинки раздела "Снаряжение"; от него считаются координаты предметов и окна.
@onready var stand_background: TextureRect = $StandBackground

# Узлы верхнего всплывающего окна: рамка, заголовок, описание, кнопка использования.
@onready var info_popup: PanelContainer = $InfoPopup
@onready var info_title_label: Label = $InfoPopup/MarginContainer/VBoxContainer/TitleLabel
@onready var info_description_label: Label = $InfoPopup/MarginContainer/VBoxContainer/DescriptionLabel
@onready var use_button: Button = $InfoPopup/MarginContainer/VBoxContainer/BottomRow/UseButton
@onready var selected_hint_label: Label = $SelectedHintLabel

# TextureRect-узлы предметов на фоне склада; каждый будет связан с item_id из ItemDatabase.
@onready var standard_suit_item: TextureRect = $StandardSuitItem
@onready var future_suit_item: TextureRect = $FutureSuitItem
@onready var heavy_suit_item: TextureRect = $HeavySuitItem
@onready var ar_visor_item: TextureRect = $ArVisorItem
@onready var wave_drone_item: TextureRect = $WaveDroneItem
@onready var analytic_resonator_item: TextureRect = $AnalyticResonatorItem
@onready var smart_metal_container_item: TextureRect = $SmartMetalContainerItem
@onready var plasma_cutter_item: TextureRect = $PlasmaCutterItem
@onready var strange_cube_item: TextureRect = $StrangeCubeItem

# Яркость выбранного и обычного предмета; используется для визуального выделения.
const SELECTED_BRIGHTNESS := 1.15
const NORMAL_BRIGHTNESS := 1.0

# Старые шаги ручного debug-позиционирования в пикселях; оставлены для совместимости.
const MOVE_STEP := 4.0
const MOVE_STEP_FINE := 1.0
const SCALE_STEP := 1.05
const SCALE_STEP_FINE := 1.01
const MIN_ITEM_SIZE := Vector2(24.0, 24.0)

# Словарь "узел предмета -> item_id"; нужен, чтобы по клику понять, какой предмет выбран.
var _spot_to_item_id: Dictionary = {}

# Словарь "item_id -> узел предмета"; обратный быстрый поиск узла по строковому id.
var _item_id_to_node: Dictionary = {}

# item_id выбранного предмета; пустая строка значит, что сейчас ничего не выбрано.
var _selected_item_id: String = ""

# Экземпляр общего debug-контроллера; он двигает предметы и печатает координаты.
var _debug_controller := ShipDebugPositioningController.new()

# Положение и размер всплывающего окна в нормализованных координатах фоновой картинки.
var info_popup_rect := Rect2(Vector2(0.205, 0.095), Vector2(0.6, 0.042))

# Порядок переключения предметов клавишами + и - в debug-режиме.
var _ordered_item_ids: Array[String] = [
	"standard_suit",
	"nova_suit",
	"heavy_rescue_suit",
	"ar_visor",
	"wave_drone",
	"analytic_resonator",
	"smart_metal_container",
	"plasma_cutter",
	"strange_cube",
]

# Визуальные данные предметов: anchor_pos — центр, size_ratio — размер относительно фона.
var cargo_visual_data := {
	"standard_suit": {"anchor_pos": Vector2(0.122, 0.561), "size_ratio": Vector2(0.290, 0.819)},
	"nova_suit": {"anchor_pos": Vector2(0.849, 0.541), "size_ratio": Vector2(0.260, 0.843)},
	"heavy_rescue_suit": {"anchor_pos": Vector2(0.305, 0.554), "size_ratio": Vector2(0.273, 0.831)},
	"ar_visor": {"anchor_pos": Vector2(0.668, 0.526), "size_ratio": Vector2(0.059, 0.0746)},
	"wave_drone": {"anchor_pos": Vector2(0.488, 0.633), "size_ratio": Vector2(0.1077, 0.1757)},
	"analytic_resonator": {"anchor_pos": Vector2(0.485, 0.495), "size_ratio": Vector2(0.1312, 0.1355)},
	"smart_metal_container": {"anchor_pos": Vector2(0.663, 0.848), "size_ratio": Vector2(0.0855, 0.1366)},
	"plasma_cutter": {"anchor_pos": Vector2(0.661, 0.335), "size_ratio": Vector2(0.105, 0.144)},
	"strange_cube": {"anchor_pos": Vector2(0.671, 0.677), "size_ratio": Vector2(0.117, 0.2087)},
}


# _ready — "готово": стартовая настройка окна, предметов, сигналов и первого layout-прохода.
func _ready() -> void:
	info_popup.z_index = 100
	info_popup.clip_contents = true
	info_title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info_title_label.clip_text = true
	info_title_label.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	info_description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info_description_label.clip_text = true
	info_description_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	use_button.custom_minimum_size = Vector2(210.0, 42.0)
	use_button.size_flags_horizontal = Control.SIZE_SHRINK_END
	use_button.size_flags_vertical = Control.SIZE_SHRINK_END
	selected_hint_label.visible = false
	_debug_controller.selected_layer = "equipment.cargo"
	_debug_controller.selected_item_id = "standard_suit"
	_spot_to_item_id = {
		standard_suit_item: "standard_suit",
		future_suit_item: "nova_suit",
		heavy_suit_item: "heavy_rescue_suit",
		ar_visor_item: "ar_visor",
		wave_drone_item: "wave_drone",
		analytic_resonator_item: "analytic_resonator",
		smart_metal_container_item: "smart_metal_container",
		plasma_cutter_item: "plasma_cutter",
		strange_cube_item: "strange_cube",
	}
	for item_node in _spot_to_item_id.keys():
		_item_id_to_node[_spot_to_item_id[item_node]] = item_node

	_setup_item_nodes()
	use_button.pressed.connect(_on_use_button_pressed)
	PlayerState.item_added.connect(_on_item_added)
	PlayerState.suit_changed.connect(_on_suit_changed)
	Localization.language_changed.connect(_on_language_changed)
	await get_tree().process_frame
	_update_item_layout()
	_update_popup_layout()
	refresh()


# refresh — "обновить": синхронизирует видимость, текстуры и выделение предметов с PlayerState.
func refresh() -> void:
	for item_node in _spot_to_item_id.keys():
		var item_id: String = _spot_to_item_id[item_node]
		var item_data: ItemData = ItemDatabase.get_item(item_id)

		if item_data == null:
			item_node.visible = false
			push_error("CargoEquipmentPanel: no ItemData for id='%s'" % item_id)
			continue

		item_node.texture = item_data.equipment_texture
		item_node.visible = PlayerState.has_item(item_id)
		item_node.modulate = _get_item_modulate(item_id)

	if _selected_item_id.is_empty() or not PlayerState.has_item(_selected_item_id):
		_hide_popup()
	else:
		_show_popup_for_item(_selected_item_id)


# _setup_item_nodes — "настроить узлы предметов": включает клики и режим отрисовки иконок.
func _setup_item_nodes() -> void:
	for item_node in _spot_to_item_id.keys():
		item_node.mouse_filter = Control.MOUSE_FILTER_STOP
		item_node.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		item_node.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		item_node.gui_input.connect(_on_item_gui_input.bind(item_node))


# _on_item_gui_input — "при GUI-вводе предмета": обрабатывает левый клик по предмету.
func _on_item_gui_input(event: InputEvent, item_node: TextureRect) -> void:
	var mouse_event := event as InputEventMouseButton
	if mouse_event == null:
		return
	if not mouse_event.pressed or mouse_event.button_index != MOUSE_BUTTON_LEFT:
		return

	var item_id: String = _spot_to_item_id.get(item_node, "")
	if item_id.is_empty() or not PlayerState.has_item(item_id):
		return

	_show_popup_for_item(item_id)


# _show_popup_for_item — "показать окно для предмета": заполняет окно данными выбранного item_id.
func _show_popup_for_item(item_id: String) -> void:
	var item_data: ItemData = ItemDatabase.get_item(item_id)
	if item_data == null:
		return

	_selected_item_id = item_id
	_debug_controller.selected_item_id = item_id
	info_title_label.text = item_data.get_title()
	info_description_label.text = item_data.get_description()
	selected_hint_label.visible = false
	_update_use_button(item_data)
	_update_popup_layout()
	info_popup.visible = true
	call_deferred("_update_popup_layout")
	_refresh_item_selection_visuals()


# _update_use_button — "обновить кнопку использования": показывает кнопку только для костюмов.
func _update_use_button(item_data: ItemData) -> void:
	if not item_data.is_suit:
		use_button.visible = false
		return

	use_button.visible = true
	var is_active := PlayerState.has_active_suit(item_data.item_id)
	use_button.disabled = is_active
	use_button.text = Localization.tr_text("cargo.equipped") if is_active else Localization.tr_text("cargo.use")


# _hide_popup — "скрыть окно": сбрасывает выбор и прячет окно описания.
func _hide_popup() -> void:
	_selected_item_id = ""
	info_popup.visible = false
	selected_hint_label.visible = false
	use_button.visible = false
	_refresh_item_selection_visuals()


# _on_use_button_pressed — "при нажатии кнопки использования": надевает выбранный костюм.
func _on_use_button_pressed() -> void:
	if _selected_item_id.is_empty():
		return

	var item_data: ItemData = ItemDatabase.get_item(_selected_item_id)
	if item_data == null or not item_data.is_suit:
		return

	PlayerState.equip_suit(_selected_item_id)
	_update_use_button(item_data)


# _on_suit_changed — "при изменении костюма": обновляет кнопку, если выбран костюм.
func _on_suit_changed(_active_suit_id: String) -> void:
	if _selected_item_id.is_empty():
		return

	var item_data: ItemData = ItemDatabase.get_item(_selected_item_id)
	if item_data != null:
		_update_use_button(item_data)


# _on_item_added — "при добавлении предмета": обновляет раздел, когда PlayerState получил предмет.
func _on_item_added(_item_id: String) -> void:
	refresh()


func _on_language_changed(_language_code: String) -> void:
	refresh()


# _unhandled_input — "необработанный ввод": ловит debug-клавиши, если панель активна.
func _unhandled_input(event: InputEvent) -> void:
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


# _handle_debug_cycle_input — "обработать debug-переключение": + и - выбирают другой предмет.
func _handle_debug_cycle_input(event: InputEventKey) -> bool:
	var handled := _debug_controller._handle_cargo_cycle_input(event, cargo_visual_data)
	if handled:
		_selected_item_id = _debug_controller.selected_item_id
		_show_popup_for_item(_selected_item_id)
	return handled


# _handle_debug_transform_input — "обработать debug-трансформацию": двигает/масштабирует предмет.
func _handle_debug_transform_input(event: InputEventKey) -> void:
	_debug_controller.handle_cargo_input(event, cargo_visual_data, Callable(self, "_update_item_layout"))
	_selected_item_id = _debug_controller.selected_item_id
	_refresh_item_selection_visuals()


# _cycle_selected_item — "переключить выбранный предмет": старый локальный цикл по списку предметов.
func _cycle_selected_item(direction: int) -> void:
	var selectable_ids := _get_selectable_item_ids()
	if selectable_ids.is_empty():
		return

	var current_index := selectable_ids.find(_selected_item_id)
	if current_index == -1:
		current_index = 0

	var next_index := posmod(current_index + direction, selectable_ids.size())
	_show_popup_for_item(selectable_ids[next_index])
	print("Selected [equipment]: ", selectable_ids[next_index])


# _update_item_layout — "обновить раскладку предметов": ставит предметы на фон по cargo_visual_data.
func _update_item_layout() -> void:
	var background_rect := _get_drawn_background_rect(stand_background)
	if background_rect.size.x <= 0.0 or background_rect.size.y <= 0.0:
		return

	for item_id in cargo_visual_data.keys():
		var item_node := _get_item_node(String(item_id))
		if item_node == null:
			continue

		var data: Dictionary = cargo_visual_data[item_id]
		var anchor_pos: Vector2 = data["anchor_pos"]
		var size_ratio: Vector2 = data["size_ratio"]
		var item_size := _calculate_preserved_item_size(
			item_node.texture,
			background_rect.size * size_ratio
		)

		item_node.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
		item_node.size = item_size
		item_node.position = background_rect.position + Vector2(
			background_rect.size.x * anchor_pos.x - item_size.x * 0.5,
			background_rect.size.y * anchor_pos.y - item_size.y * 0.5
		)

	_update_popup_layout()


# _update_popup_layout — "обновить раскладку окна": приклеивает окно описания к фону склада.
func _update_popup_layout() -> void:
	var background_rect := _get_drawn_background_rect(stand_background)
	if background_rect.size.x <= 0.0 or background_rect.size.y <= 0.0:
		return

	var popup_position := background_rect.position + info_popup_rect.position * background_rect.size
	var popup_size := info_popup_rect.size * background_rect.size

	info_popup.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	info_popup.position = popup_position
	info_popup.size = popup_size
	info_popup.custom_minimum_size = popup_size

	var margin := info_popup.get_node_or_null("MarginContainer") as MarginContainer
	if margin != null:
		margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var vbox := info_popup.get_node_or_null("MarginContainer/VBoxContainer") as VBoxContainer
	if vbox != null:
		vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		vbox.clip_contents = true

	var bottom_row := info_popup.get_node_or_null("MarginContainer/VBoxContainer/BottomRow") as HBoxContainer
	if bottom_row != null:
		bottom_row.size_flags_vertical = Control.SIZE_SHRINK_END


# _get_drawn_background_rect — "получить прямоугольник нарисованного фона": учитывает cover-обрезку.
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


# _calculate_preserved_item_size — "посчитать сохранённый размер": вписывает текстуру без искажений.
func _calculate_preserved_item_size(texture: Texture2D, max_size: Vector2) -> Vector2:
	if texture == null:
		return max_size

	var texture_size := texture.get_size()
	if texture_size.x <= 0.0 or texture_size.y <= 0.0:
		return max_size

	var scale_value: float = min(max_size.x / texture_size.x, max_size.y / texture_size.y)
	return texture_size * scale_value


# _notification — "уведомление": при изменении размера окна пересчитывает предметы и popup.
func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and is_node_ready():
		_update_item_layout()
		_update_popup_layout()


# _get_selectable_item_ids — "получить id выбираемых предметов": возвращает только предметы игрока.
func _get_selectable_item_ids() -> Array[String]:
	var result: Array[String] = []
	for item_id in _ordered_item_ids:
		if PlayerState.has_item(item_id):
			result.append(item_id)
	return result


# _get_item_node — "получить узел предмета": ищет TextureRect по item_id.
func _get_item_node(item_id: String) -> TextureRect:
	for item_node in _spot_to_item_id.keys():
		if _spot_to_item_id[item_node] == item_id:
			return item_node
	return null


# _refresh_item_selection_visuals — "обновить визуал выбора": пересчитывает яркость предметов.
func _refresh_item_selection_visuals() -> void:
	for item_node in _spot_to_item_id.keys():
		var item_id: String = _spot_to_item_id[item_node]
		item_node.modulate = _get_item_modulate(item_id)


# _get_item_modulate — "получить модуляцию предмета": возвращает цвет для выбранного/обычного.
func _get_item_modulate(item_id: String) -> Color:
	if item_id == _selected_item_id:
		return Color(SELECTED_BRIGHTNESS, SELECTED_BRIGHTNESS, SELECTED_BRIGHTNESS, 1.0)
	return Color(NORMAL_BRIGHTNESS, NORMAL_BRIGHTNESS, NORMAL_BRIGHTNESS, 1.0)


# _print_selected_item_debug — "напечатать debug выбранного предмета": старый вывод position/size.
func _print_selected_item_debug() -> void:
	var item_node := _get_item_node(_selected_item_id)
	if item_node == null:
		return

	print("\"", _selected_item_id, "\": {")
	print("\t\"position\": Vector2(", item_node.position.x, ", ", item_node.position.y, "),")
	print("\t\"size\": Vector2(", item_node.size.x, ", ", item_node.size.y, ")")
	print("}")
