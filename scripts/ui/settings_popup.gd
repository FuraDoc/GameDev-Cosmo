extends Control

# Сигнал закрытия настроек: MainScene может снова принимать ввод меню.
signal settings_closed

# Выпадающий список разрешений: хранит варианты 1080/1440/2160.
@onready var resolution_option: OptionButton = $CenterContainer/Panel/MarginContainer/VBoxContainer/ResolutionRow/ResolutionOption
@onready var title_label: Label = $CenterContainer/Panel/MarginContainer/VBoxContainer/TitleLabel
@onready var resolution_label: Label = $CenterContainer/Panel/MarginContainer/VBoxContainer/ResolutionRow/ResolutionLabel
@onready var language_label: Label = $CenterContainer/Panel/MarginContainer/VBoxContainer/LanguageRow/LanguageLabel
@onready var language_option: OptionButton = $CenterContainer/Panel/MarginContainer/VBoxContainer/LanguageRow/LanguageOption

# Кнопка применения выбранного разрешения.
@onready var apply_button: Button = $CenterContainer/Panel/MarginContainer/VBoxContainer/ButtonsRow/ApplyButton

# Кнопка выхода без изменений.
@onready var cancel_button: Button = $CenterContainer/Panel/MarginContainer/VBoxContainer/ButtonsRow/CancelButton

# Доступные разрешения: подпись в списке и реальный размер окна.
var resolution_presets: Array[Dictionary] = [
	{"label": "1080", "size": Vector2i(1920, 1080)},
	{"label": "1440", "size": Vector2i(2560, 1440)},
	{"label": "2160", "size": Vector2i(3840, 2160)},
]


# _ready — «готово»: растягивает popup, заполняет список и подключает кнопки.
func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_populate_resolution_options()
	_select_current_resolution()
	_populate_language_options()
	_select_current_language()
	_apply_localization()
	apply_button.pressed.connect(_on_apply_button_pressed)
	cancel_button.pressed.connect(_on_cancel_button_pressed)
	language_option.item_selected.connect(_on_language_option_selected)
	Localization.language_changed.connect(_on_language_changed)


# _populate_resolution_options — «заполнить варианты разрешения»: добавляет 3 пункта в OptionButton.
func _populate_resolution_options() -> void:
	resolution_option.clear()
	for index in range(resolution_presets.size()):
		resolution_option.add_item(String(resolution_presets[index]["label"]), index)


func _populate_language_options() -> void:
	language_option.clear()
	language_option.add_item(Localization.tr_text("language.ru"), 0)
	language_option.set_item_metadata(0, Localization.LANGUAGE_RU)
	language_option.add_item(Localization.tr_text("language.en"), 1)
	language_option.set_item_metadata(1, Localization.LANGUAGE_EN)
	language_option.add_item(Localization.tr_text("language.zh_cn"), 2)
	language_option.set_item_metadata(2, Localization.LANGUAGE_ZH_CN)


func _select_current_language() -> void:
	for index in range(language_option.get_item_count()):
		if String(language_option.get_item_metadata(index)) == Localization.get_language():
			language_option.select(index)
			return


func _apply_localization() -> void:
	title_label.text = Localization.tr_text("settings.title")
	resolution_label.text = Localization.tr_text("settings.resolution")
	language_label.text = Localization.tr_text("settings.language")
	apply_button.text = Localization.tr_text("settings.apply")
	cancel_button.text = Localization.tr_text("settings.cancel")
	_populate_language_options()
	_select_current_language()


# _select_current_resolution — «выбрать текущее разрешение»: подсвечивает ближайший пункт.
func _select_current_resolution() -> void:
	var current_size: Vector2i = DisplayServer.window_get_size()
	var selected_index: int = 0

	for index in range(resolution_presets.size()):
		var preset_size: Vector2i = resolution_presets[index]["size"] as Vector2i
		if current_size.y >= preset_size.y:
			selected_index = index

	resolution_option.select(selected_index)


# _on_apply_button_pressed — «нажата применить»: меняет размер окна и закрывает настройки.
func _on_apply_button_pressed() -> void:
	var selected_index: int = resolution_option.get_selected_id()
	if selected_index < 0 or selected_index >= resolution_presets.size():
		return

	var selected_language := _get_selected_language()
	Localization.set_language(selected_language)
	var selected_size: Vector2i = resolution_presets[selected_index]["size"] as Vector2i
	await _apply_resolution(selected_size)
	_close()


func _on_language_option_selected(_index: int) -> void:
	var selected_language := _get_selected_language()
	Localization.set_language(selected_language)


func _on_language_changed(_language_code: String) -> void:
	_apply_localization()


func _get_selected_language() -> String:
	var selected_index := language_option.selected
	if selected_index < 0:
		return Localization.get_language()
	return String(language_option.get_item_metadata(selected_index))


# _apply_resolution — «применить разрешение»: меняет размер корневого окна и центрирует его.
func _apply_resolution(selected_size: Vector2i) -> void:
	var window: Window = get_window()
	var screen_size: Vector2i = DisplayServer.screen_get_size(window.current_screen)
	var screen_position: Vector2i = DisplayServer.screen_get_position(window.current_screen)
	var centered_position: Vector2i = screen_position + (screen_size - selected_size) / 2

	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	window.mode = Window.MODE_WINDOWED
	await get_tree().process_frame

	DisplayServer.window_set_size(selected_size)
	window.size = selected_size
	DisplayServer.window_set_position(centered_position)
	window.position = centered_position


# _on_cancel_button_pressed — «нажата отмена»: закрывает настройки без применения.
func _on_cancel_button_pressed() -> void:
	_close()


# _unhandled_input — «необработанный ввод»: Escape закрывает окно без изменений.
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_close()


# _close — «закрыть»: сообщает наружу и удаляет окно настроек.
func _close() -> void:
	settings_closed.emit()
	queue_free()
