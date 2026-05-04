extends Control

# Подключаем общий debug-контроллер: он двигает предметы Cargo по anchor_pos и size_ratio.
const ShipDebugPositioningController = preload("res://scripts/ship/ship_debug_positioning_controller.gd")

# Фон раздела «Интерьер»: по нему считается drawn rect для привязки предметов.
@onready var storage_background: TextureRect = $StorageBackground

# Корень предметов: сюда создаются кнопки-иконки интерьера.
@onready var items_root: Control = $ItemsRoot

# Панель описания выбранного предмета.
@onready var tooltip_panel: Panel = $TopInfoContainer/TooltipPanel

# Заголовок popup-окна: название выбранного предмета.
@onready var item_name_label: Label = $TopInfoContainer/TooltipPanel/VBoxContainer/ItemNameLabel

# Текст popup-окна: описание и текущий статус установки.
@onready var item_description_label: Label = $TopInfoContainer/TooltipPanel/VBoxContainer/ItemDescriptionLabel

# Кнопка действия popup-окна: «Установить» или «Убрать».
@onready var action_button: Button = $TopInfoContainer/TooltipPanel/VBoxContainer/ActionButton

# Количество предметов интерьера: item_id строятся от interior_plant_001 до _040.
const ITEM_COUNT := 40

# Яркость выбранного предмета.
const SELECTED_BRIGHTNESS := 1.2

# Яркость обычного предмета.
const NORMAL_BRIGHTNESS := 1.0

# Прозрачность уже установленного предмета.
const INSTALLED_ALPHA := 0.5

# Прозрачность обычного предмета.
const NORMAL_ALPHA := 1.0

# Debug-шаг движения, оставлен рядом с панелью для быстрой настройки.
const MOVE_STEP := 0.01

# Debug-тонкий шаг движения.
const MOVE_STEP_FINE := 0.001

# Debug-множитель размера.
const SCALE_STEP := 1.05

# Debug-тонкий множитель размера.
const SCALE_STEP_FINE := 1.01

# Минимальный size_ratio предмета в Cargo.
const MIN_SIZE_RATIO := 0.02

# Максимальный size_ratio предмета в Cargo.
const MAX_SIZE_RATIO := 0.25

# Выбранный предмет интерьера: используется popup-окном и debug-позиционированием.
var selected_item_id := "interior_plant_001"

# Экземпляр общего debug-контроллера для движения предметов на фоне раздела.
var debug_controller := ShipDebugPositioningController.new()

# Словарь item_id -> Button, чтобы обновлять позиции и визуальное состояние.
var item_nodes: Dictionary = {}

# Словарь описаний предметов: title и description для popup-окна.
var item_data: Dictionary = {}

# Позиция и размер popup-окна в координатах фона: 0..1 от drawn rect background.
var info_popup_rect := Rect2(Vector2(0.360, 0.095), Vector2(0.280, 0.19))

# Визуальные данные предметов Cargo: путь к текстуре, центр anchor_pos и размер size_ratio.
var cargo_visual_data := {
	"interior_plant_001": {"texture_path": "res://assets/items/interior/plant001.png", "anchor_pos": Vector2(0.16, 0.857), "size_ratio": Vector2(0.138982, 0.227425)},
	"interior_plant_002": {"texture_path": "res://assets/items/interior/plant002.png", "anchor_pos": Vector2(0.266, 0.784), "size_ratio": Vector2(0.226387, 0.370452)},
	"interior_plant_003": {"texture_path": "res://assets/items/interior/plant003.png", "anchor_pos": Vector2(0.321, 0.515), "size_ratio": Vector2(0.070239, 0.114937)},
	"interior_plant_004": {"texture_path": "res://assets/items/interior/plant004.png", "anchor_pos": Vector2(0.353, 0.807), "size_ratio": Vector2(0.055, 0.09)},
	"interior_plant_005": {"texture_path": "res://assets/items/interior/plant005.png", "anchor_pos": Vector2(0.58, 0.75), "size_ratio": Vector2(0.063669, 0.104186)},
	"interior_plant_006": {"texture_path": "res://assets/items/interior/plant006.png", "anchor_pos": Vector2(0.705, 0.879), "size_ratio": Vector2(0.145931, 0.238797)},
	"interior_plant_007": {"texture_path": "res://assets/items/interior/plant007.png", "anchor_pos": Vector2(0.689, 0.223), "size_ratio": Vector2(0.16065, 0.2625)},
	"interior_plant_008": {"texture_path": "res://assets/items/interior/plant008.png", "anchor_pos": Vector2(0.51, 0.528), "size_ratio": Vector2(0.044272, 0.072445)},
	"interior_plant_009": {"texture_path": "res://assets/items/interior/plant009.png", "anchor_pos": Vector2(0.685, 0.699), "size_ratio": Vector2(0.052381, 0.085714)},
	"interior_plant_010": {"texture_path": "res://assets/items/interior/plant010.png", "anchor_pos": Vector2(0.315, 0.17), "size_ratio": Vector2(0.138982, 0.227425)},
	"interior_plant_011": {"texture_path": "res://assets/items/interior/plant011.png", "anchor_pos": Vector2(0.447, 0.362), "size_ratio": Vector2(0.055, 0.09)},
	"interior_plant_012": {"texture_path": "res://assets/items/interior/plant012.png", "anchor_pos": Vector2(0.862, 0.861), "size_ratio": Vector2(0.188293, 0.308115)},
	"interior_plant_013": {"texture_path": "res://assets/items/interior/plant013.png", "anchor_pos": Vector2(0.543, 0.364), "size_ratio": Vector2(0.055, 0.09)},
	"interior_plant_014": {"texture_path": "res://assets/items/interior/plant014.png", "anchor_pos": Vector2(0.644, 0.365), "size_ratio": Vector2(0.055, 0.09)},
	"interior_plant_015": {"texture_path": "res://assets/items/interior/plant015.png", "anchor_pos": Vector2(0.625, 0.521), "size_ratio": Vector2(0.052331, 0.085632)},
	"interior_plant_016": {"texture_path": "res://assets/items/interior/plant016.png", "anchor_pos": Vector2(0.359, 0.361), "size_ratio": Vector2(0.055, 0.09)},
	"interior_plant_017": {"texture_path": "res://assets/items/interior/plant017.png", "anchor_pos": Vector2(0.563, 0.518), "size_ratio": Vector2(0.055, 0.09)},
	"interior_plant_018": {"texture_path": "res://assets/items/interior/plant018.png", "anchor_pos": Vector2(0.469, 0.668), "size_ratio": Vector2(0.056558, 0.092549)},
	"interior_plant_019": {"texture_path": "res://assets/items/interior/plant019.png", "anchor_pos": Vector2(0.389, 0.517), "size_ratio": Vector2(0.055, 0.09)},
	"interior_plant_020": {"texture_path": "res://assets/items/interior/plant020.png", "anchor_pos": Vector2(0.449, 0.516), "size_ratio": Vector2(0.055, 0.09)},
	"interior_plant_021": {"texture_path": "res://assets/items/interior/plant021.png", "anchor_pos": Vector2(0.733, 0.536), "size_ratio": Vector2(0.064824, 0.106076)},
	"interior_plant_022": {"texture_path": "res://assets/items/interior/plant022.png", "anchor_pos": Vector2(0.783, 0.541), "size_ratio": Vector2(0.087373, 0.142975)},
	"interior_plant_023": {"texture_path": "res://assets/items/interior/plant023.png", "anchor_pos": Vector2(0.693, 0.534), "size_ratio": Vector2(0.055, 0.09)},
	"interior_plant_024": {"texture_path": "res://assets/items/interior/plant024.png", "anchor_pos": Vector2(0.554, 0.668), "size_ratio": Vector2(0.6615, 0.11025)},
	"interior_plant_025": {"texture_path": "res://assets/items/interior/plant025.png", "anchor_pos": Vector2(0.51, 0.693), "size_ratio": Vector2(0.098772, 0.161627)},
	"interior_plant_026": {"texture_path": "res://assets/items/interior/plant026.png", "anchor_pos": Vector2(0.605, 0.678), "size_ratio": Vector2(0.055, 0.09)},
	"interior_plant_027": {"texture_path": "res://assets/items/interior/plant027.png", "anchor_pos": Vector2(0.379, 0.676), "size_ratio": Vector2(0.127444, 0.208545)},
	"interior_plant_028": {"texture_path": "res://assets/items/interior/plant028.png", "anchor_pos": Vector2(0.633, 0.78), "size_ratio": Vector2(0.125685, 0.206167)},
	"interior_plant_029": {"texture_path": "res://assets/items/interior/plant029.png", "anchor_pos": Vector2(0.235, 0.552), "size_ratio": Vector2(0.069011, 0.112927)},
	"interior_plant_030": {"texture_path": "res://assets/items/interior/plant030.png", "anchor_pos": Vector2(0.1, 0.203), "size_ratio": Vector2(0.093676, 0.153288)},
	"interior_plant_031": {"texture_path": "res://assets/items/interior/plant031.png", "anchor_pos": Vector2(0.19, 0.18), "size_ratio": Vector2(0.186249, 0.304772)},
	"interior_plant_032": {"texture_path": "res://assets/items/interior/plant032.png", "anchor_pos": Vector2(0.765, 0.17), "size_ratio": Vector2(0.17738, 0.290259)},
	"interior_plant_033": {"texture_path": "res://assets/items/interior/plant033.png", "anchor_pos": Vector2(0.142, 0.53), "size_ratio": Vector2(0.13232, 0.216523)},
	"interior_plant_034": {"texture_path": "res://assets/items/interior/plant034.png", "anchor_pos": Vector2(0.859, 0.56), "size_ratio": Vector2(0.114341, 0.187103)},
	"interior_plant_035": {"texture_path": "res://assets/items/interior/plant035.png", "anchor_pos": Vector2(0.607, 0.315), "size_ratio": Vector2(0.101667, 0.166364)},
	"interior_plant_036": {"texture_path": "res://assets/items/interior/plant036.png", "anchor_pos": Vector2(0.871, 0.156), "size_ratio": Vector2(0.153228, 0.250736)},
	"interior_plant_037": {"texture_path": "res://assets/items/interior/plant037.png", "anchor_pos": Vector2(0.77, 0.763), "size_ratio": Vector2(0.108844, 0.177951)},
	"interior_plant_038": {"texture_path": "res://assets/items/interior/plant038.png", "anchor_pos": Vector2(0.285, 0.547), "size_ratio": Vector2(0.047848, 0.078297)},
	"interior_plant_039": {"texture_path": "res://assets/items/interior/plant039.png", "anchor_pos": Vector2(0.432, 0.668), "size_ratio": Vector2(0.060637, 0.099225)},
	"interior_plant_040": {"texture_path": "res://assets/items/interior/plant040.png", "anchor_pos": Vector2(0.396, 0.297), "size_ratio": Vector2(0.073705, 0.120609)}
}

# Включатель debug-позиционирования предметов интерьера в Cargo.
var debug_enabled := true

# _ready — «готово»: настраивает popup, debug-контроллер, создает предметы и подключает сигналы.
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
	debug_controller.selected_layer = "interior.cargo"
	debug_controller.selected_item_id = selected_item_id
	PlayerState.set_debug_selected_interior_item(selected_item_id)
	items_root.clip_contents = true
	items_root.z_index = 0
	$TopInfoContainer.z_index = 100
	_build_item_data()
	await get_tree().process_frame
	_create_item_nodes()
	_update_popup_layout()
	action_button.pressed.connect(_on_action_button_pressed)

	if PlayerState.has_signal("interior_changed"):
		PlayerState.interior_changed.connect(_on_player_interior_changed)
	Localization.language_changed.connect(_on_language_changed)

	refresh()


# _build_item_data — «построить данные предметов»: создает временные названия и описания.
func _build_item_data() -> void:
	item_data.clear()
	for i in range(1, ITEM_COUNT + 1):
		var item_id := _item_id_from_index(i - 1)
		item_data[item_id] = {
			"title": Localization.format_text("cargo.interior_item_title", [i]),
			"description": Localization.format_text("cargo.interior_item_description", [i])
		}


# _create_item_nodes — «создать узлы предметов»: строит кнопки с TextureRect для всех растений.
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
		button.gui_input.connect(_on_item_gui_input.bind(item_id))

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


# refresh — «обновить»: применяет selected/installed-состояние и показывает popup.
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


# _apply_item_visual_state — «применить визуальное состояние»: яркость выбранного и alpha installed.
func _apply_item_visual_state(node: Control, is_selected: bool, installed: bool) -> void:
	var brightness := SELECTED_BRIGHTNESS if is_selected else NORMAL_BRIGHTNESS
	var alpha := INSTALLED_ALPHA if installed else NORMAL_ALPHA
	node.modulate = Color(brightness, brightness, brightness, alpha)


# _show_selected_item_info — «показать информацию выбранного»: заполняет popup и кнопку действия.
func _show_selected_item_info() -> void:
	var data: Dictionary = item_data.get(selected_item_id, {})
	var zone_id: int = PlayerState.get_interior_item_zone(selected_item_id)
	var installed: bool = zone_id != -1
	item_name_label.text = String(data.get("title", Localization.tr_text("cargo.unknown_item")))
	item_description_label.text = String(data.get("description", Localization.tr_text("cargo.no_description")))
	if installed:
		item_description_label.text += "\n\n" + Localization.format_text("cargo.installed_zone", [zone_id])
	else:
		item_description_label.text += "\n\n" + Localization.tr_text("cargo.not_installed")

	action_button.text = Localization.tr_text("cargo.remove") if installed else Localization.tr_text("cargo.install")
	action_button.disabled = false
	_update_popup_layout()
	tooltip_panel.visible = true
	call_deferred("_update_popup_layout")


# _on_item_pressed — «нажат предмет»: выбирает item_id, синхронизирует debug и обновляет UI.
func _on_item_pressed(item_id: String) -> void:
	_select_item(item_id)


# _on_item_gui_input — «ввод по предмету»: правый клик тоже выбирает предмет без установки.
func _on_item_gui_input(event: InputEvent, item_id: String) -> void:
	if not (event is InputEventMouseButton):
		return

	var mouse_event := event as InputEventMouseButton
	if mouse_event.button_index != MOUSE_BUTTON_RIGHT or not mouse_event.pressed:
		return

	_select_item(item_id)
	accept_event()


# _select_item — «выбрать предмет»: подсвечивает item_id и делает его debug-целью кокпита.
func _select_item(item_id: String) -> void:
	selected_item_id = item_id
	debug_controller.selected_item_id = item_id
	PlayerState.set_debug_selected_interior_item(item_id)
	refresh()


# _on_action_button_pressed — «нажата кнопка действия»: устанавливает или снимает интерьер.
func _on_action_button_pressed() -> void:
	if selected_item_id.is_empty():
		return

	PlayerState.set_debug_selected_interior_item(selected_item_id)

	if PlayerState.is_interior_item_installed(selected_item_id):
		PlayerState.uninstall_interior_item(selected_item_id)
	else:
		PlayerState.request_debug_interior_install(selected_item_id)

	refresh()


# _on_player_interior_changed — «изменился интерьер игрока»: полностью обновляет панель.
func _on_player_interior_changed() -> void:
	refresh()


func _on_language_changed(_language_code: String) -> void:
	_build_item_data()
	refresh()


# _unhandled_input — «необработанный ввод»: пропускает debug-клавиши для текущей панели.
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


# _handle_debug_cycle_input — «обработать debug-переключение»: -/+ выбирают следующий предмет.
func _handle_debug_cycle_input(event: InputEventKey) -> bool:
	var handled := debug_controller._handle_cargo_cycle_input(event, cargo_visual_data)
	if handled:
		selected_item_id = debug_controller.selected_item_id
		PlayerState.set_debug_selected_interior_item(selected_item_id)
		refresh()
	return handled


# _handle_debug_transform_input — «обработать debug-трансформацию»: двигает и масштабирует предмет.
func _handle_debug_transform_input(event: InputEventKey) -> void:
	debug_controller.handle_cargo_input(event, cargo_visual_data, Callable(self, "_update_item_layout"))
	selected_item_id = debug_controller.selected_item_id
	PlayerState.set_debug_selected_interior_item(selected_item_id)
	refresh()


# _cycle_selected_item — «переключить выбранный предмет»: старый локальный переключатель по индексу.
func _cycle_selected_item(direction: int) -> void:
	var current_index := _index_from_item_id(selected_item_id)
	var next_index := posmod(current_index + direction, ITEM_COUNT)
	selected_item_id = _item_id_from_index(next_index)
	PlayerState.set_debug_selected_interior_item(selected_item_id)
	refresh()
	print("Selected [interior.cargo]: ", selected_item_id)


# _update_item_layout — «обновить раскладку предметов»: приклеивает иконки к drawn rect фона.
func _update_item_layout() -> void:
	if storage_background == null or not is_instance_valid(storage_background):
		return
	if items_root == null or not is_instance_valid(items_root):
		return

	var background_rect := _get_drawn_background_rect(storage_background)
	if background_rect.size.x <= 0.0 or background_rect.size.y <= 0.0:
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
			background_rect.size * size_ratio
		)

		node.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
		node.size = item_size
		node.position = background_rect.position + Vector2(
			background_rect.size.x * anchor_pos.x - item_size.x * 0.5,
			background_rect.size.y * anchor_pos.y - item_size.y * 0.5
		)

	_update_popup_layout()


# _update_popup_layout — «обновить раскладку popup»: ставит окно описания по info_popup_rect.
func _update_popup_layout() -> void:
	var background_rect := _get_drawn_background_rect(storage_background)
	if background_rect.size.x <= 0.0 or background_rect.size.y <= 0.0:
		return

	var popup_position := background_rect.position + info_popup_rect.position * background_rect.size
	var popup_size := info_popup_rect.size * background_rect.size

	$TopInfoContainer.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	$TopInfoContainer.custom_minimum_size = Vector2.ZERO
	$TopInfoContainer.position = popup_position
	$TopInfoContainer.size = popup_size
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
		vbox.offset_top = 12.0
		vbox.offset_right = -14.0
		vbox.offset_bottom = -12.0


# _get_drawn_background_rect — «получить нарисованный прямоугольник фона»: учитывает cover-растяжение.
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


# print_selected_debug_item — «напечатать выбранный debug-предмет»: выводит словарь координат.
func print_selected_debug_item() -> void:
	if not cargo_visual_data.has(selected_item_id):
		return

	var data: Dictionary = cargo_visual_data[selected_item_id]
	print("\"", selected_item_id, "\": {")
	print("\t\"texture_path\": \"", data["texture_path"], "\",")
	print("\t\"anchor_pos\": Vector2(", data["anchor_pos"].x, ", ", data["anchor_pos"].y, "),")
	print("\t\"size_ratio\": Vector2(", data["size_ratio"].x, ", ", data["size_ratio"].y, ")")
	print("}")


# _notification — «уведомление»: при resize пересчитывает предметы и popup.
func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_update_item_layout()
		_update_popup_layout()


# _item_id_from_index — «ID предмета по индексу»: строит interior_plant_001..040.
func _item_id_from_index(index: int) -> String:
	return "interior_plant_%03d" % (index + 1)


# _texture_path_from_index — «путь текстуры по индексу»: строит путь plant001.png..plant040.png.
func _texture_path_from_index(index: int) -> String:
	return "res://assets/items/interior/plant%03d.png" % (index + 1)


# _index_from_item_id — «индекс из ID предмета»: достает номер из последней части строки.
func _index_from_item_id(item_id: String) -> int:
	var parts := item_id.split("_")
	if parts.size() == 0:
		return 0
	return clamp(int(parts[parts.size() - 1]) - 1, 0, ITEM_COUNT - 1)


# _calculate_preserved_item_size — «рассчитать сохраненный размер»: вписывает текстуру без искажения.
func _calculate_preserved_item_size(texture: Texture2D, max_size: Vector2) -> Vector2:
	if texture == null:
		return max_size

	var texture_size := texture.get_size()
	if texture_size.x <= 0.0 or texture_size.y <= 0.0:
		return max_size

	var scale_value: float = min(max_size.x / texture_size.x, max_size.y / texture_size.y)
	return texture_size * scale_value
