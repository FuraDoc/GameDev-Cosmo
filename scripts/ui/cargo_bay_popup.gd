extends Control

signal popup_closed

# --- Узлы сцены ---
@onready var title_label: Label = $CenterContainer/Panel/MarginContainer/VBoxContainer/TitleLabel

@onready var equipment_button: Button = $CenterContainer/Panel/MarginContainer/VBoxContainer/ButtonsRow/EquipmentButton
@onready var interior_button: Button = $CenterContainer/Panel/MarginContainer/VBoxContainer/ButtonsRow/InteriorButton
@onready var hardware_button: Button = $CenterContainer/Panel/MarginContainer/VBoxContainer/ButtonsRow/HardwareButton
@onready var pets_button: Button = $CenterContainer/Panel/MarginContainer/VBoxContainer/ButtonsRow/PetsButton

@onready var section_background: TextureRect = $CenterContainer/Panel/MarginContainer/VBoxContainer/ContentArea/SectionBackground
@onready var content_root: Control = $CenterContainer/Panel/MarginContainer/VBoxContainer/ContentArea/ContentLayer/ContentRoot

@onready var close_button: Button = $CenterContainer/Panel/MarginContainer/VBoxContainer/CloseButton

# --- Текущая активная секция ---
var current_section: String = "equipment"

# --- Словарь: id секции → сцена панели контента ---
# Если для секции нет сцены — будет показан placeholder-текст
const SECTION_SCENES := {
	"equipment": preload("res://scenes/ui/cargo_equipment_panel.tscn"),
	"interior":  preload("res://scenes/ui/cargo_interior_panel.tscn"),
	"hardware":  preload("res://scenes/ui/cargo_hardware_panel.tscn"),
	"pets":      preload("res://scenes/ui/cargo_pets_panel.tscn"),
}

# --- Словарь: id секции → заголовок окна ---
const SECTION_TITLES := {
	"equipment": "Грузовой отсек — Снаряжение",
	"interior":  "Грузовой отсек — Интерьер",
	"hardware":  "Грузовой отсек — Модули",
	"pets":      "Грузовой отсек — Питомцы",
}

# --- Словарь: id секции → путь к фоновой текстуре (пустая строка = нет фона) ---
# load() используется намеренно: фоны могут меняться динамически или отсутствовать
var backgrounds := {
	"equipment": "",
	"interior":  "",
	"hardware":  "",
	"pets":      "",
}


func _ready() -> void:
	# Растягиваем на весь экран
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	# Подключаем кнопки секций через лямбды — все делают одно и то же
	equipment_button.pressed.connect(func(): show_section("equipment"))
	interior_button.pressed.connect(func(): show_section("interior"))
	hardware_button.pressed.connect(func(): show_section("hardware"))
	pets_button.pressed.connect(func(): show_section("pets"))

	close_button.pressed.connect(close_popup)

	# Показываем начальную секцию
	show_section("equipment")


# Главная точка входа при смене вкладки
func show_section(section_id: String) -> void:
	current_section = section_id
	_update_title()
	_update_background()
	_rebuild_content()


# Обновляем заголовок окна по словарю
func _update_title() -> void:
	title_label.text = SECTION_TITLES.get(current_section, "Грузовой отсек")


# Загружаем фоновую текстуру для секции (если задана)
func _update_background() -> void:
	var path: String = backgrounds.get(current_section, "")

	if path.is_empty():
		section_background.texture = null
		return

	var texture = load(path)
	if texture == null:
		push_error("CargoBayPopup: не удалось загрузить фон секции: " + path)
		section_background.texture = null
		return

	section_background.texture = texture


# Очищаем контент и создаём панель нужной секции
func _rebuild_content() -> void:
	# Удаляем все старые дочерние узлы
	for child in content_root.get_children():
		child.free()

	# Берём сцену из словаря
	var scene: PackedScene = SECTION_SCENES.get(current_section, null)

	if scene != null:
		# Instantiate и стандартная настройка панели
		var panel: Control = scene.instantiate()
		content_root.add_child(panel)
		panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		panel.mouse_filter = Control.MOUSE_FILTER_STOP
		return

	# Запасной вариант — текстовый placeholder для неизвестных секций
	var label := Label.new()
	label.text = "Пустой раздел."
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_root.add_child(label)


# Закрытие по Escape
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		close_popup()


# Испускаем сигнал и уничтожаем попап
func close_popup() -> void:
	popup_closed.emit()
	queue_free()
