extends Control

# Главное меню: показывает фон, fade-in, кнопки новой игры, продолжения, настроек и выхода.

# Узлы фона и затемнения; fade_overlay используется для плавного входа из чёрного.
@onready var background_texture = $BackgroundTexture
@onready var fade_overlay = $FadeOverlay

# Кнопки главного меню; обработчики подключаются в _ready.
@onready var new_game_button = $UI/VBoxContainer/MenuPanel/MarginContainer/ButtonsContainer/NewGameButton
@onready var continue_button = $UI/VBoxContainer/MenuPanel/MarginContainer/ButtonsContainer/ContinueButton
@onready var settings_button = $UI/VBoxContainer/MenuPanel/MarginContainer/ButtonsContainer/SettingsButton
@onready var exit_button = $UI/VBoxContainer/MenuPanel/MarginContainer/ButtonsContainer/ExitButton

# background_path — "путь фона": картинка, которая ставится на главный экран меню.
var background_path = "res://assets/backgrounds/space/ship-frontwiew.jpg"

# save_slots_popup_scene — "сцена окна слотов": переиспользуется для новой игры и продолжения.
var save_slots_popup_scene = preload("res://scenes/ui/save_slots_popup.tscn")


# _ready — "готово": запускает фон, fade-in, подключает кнопки и обновляет Continue.
func _ready():
	show_background()
	fade_overlay.color.a = 1.0
	await fade_from_black(2.0)
	new_game_button.pressed.connect(_on_new_game_pressed)
	continue_button.pressed.connect(_on_continue_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	exit_button.pressed.connect(_on_exit_pressed)
	update_continue_button()


# show_background — "показать фон": загружает texture из background_path и ставит её в TextureRect.
func show_background():
	var texture = load(background_path)
	if texture == null:
		push_error("Не удалось загрузить фон: " + background_path)
		return
	background_texture.texture = texture


# fade_from_black — "проявиться из чёрного": плавно уменьшает альфу чёрного overlay.
func fade_from_black(duration: float) -> void:
	var tween = create_tween()
	tween.tween_property(fade_overlay, "color:a", 0.0, duration)
	await tween.finished


# update_continue_button — "обновить кнопку продолжения": включает её, если есть сохранение.
func update_continue_button():
	continue_button.disabled = not SaveManager.has_any_save()


# _on_new_game_pressed — "при нажатии новой игры": открывает выбор слота в режиме new_game.
func _on_new_game_pressed():
	var popup = save_slots_popup_scene.instantiate()
	popup.mode = "new_game"
	add_child(popup)
	popup.new_game_confirmed.connect(_on_new_game_slot_confirmed)


# _on_continue_pressed — "при нажатии продолжить": открывает выбор слота в режиме continue.
func _on_continue_pressed():
	var popup = save_slots_popup_scene.instantiate()
	popup.mode = "continue"
	add_child(popup)
	popup.continue_confirmed.connect(_on_continue_slot_confirmed)


# _on_new_game_slot_confirmed — "подтверждён слот новой игры": создаёт save и открывает корабль.
func _on_new_game_slot_confirmed(slot_id: int, pilot_name: String) -> void:
	SaveManager.create_new_game(slot_id, pilot_name)
	PlayerState.apply_default_modules()
	update_continue_button()
	get_tree().change_scene_to_file("res://scenes/ship/ship_scene.tscn")


# _on_continue_slot_confirmed — "подтверждён слот продолжения": проверяет save и открывает корабль.
func _on_continue_slot_confirmed(slot_id: int) -> void:
	var save_data = SaveManager.load_slot(slot_id)
	if save_data.is_empty():
		return
	get_tree().change_scene_to_file("res://scenes/ship/ship_scene.tscn")


# _on_settings_pressed — "при нажатии настроек": временная заглушка будущего окна настроек.
func _on_settings_pressed():
	print("Открыть настройки")


# _on_exit_pressed — "при нажатии выхода": завершает приложение.
func _on_exit_pressed():
	get_tree().quit()
