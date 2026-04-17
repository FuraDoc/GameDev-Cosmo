extends Control

# =========================================================
# MAIN MENU
# =========================================================
# Главная сцена меню.
#
# Сейчас она отвечает за:
# - фон
# - fade-in
# - кнопки меню
# - открытие окна выбора слотов сохранения
# =========================================================

@onready var background_texture = $BackgroundTexture
@onready var fade_overlay = $FadeOverlay

@onready var new_game_button = $UI/VBoxContainer/MenuPanel/MarginContainer/ButtonsContainer/NewGameButton
@onready var continue_button = $UI/VBoxContainer/MenuPanel/MarginContainer/ButtonsContainer/ContinueButton
@onready var settings_button = $UI/VBoxContainer/MenuPanel/MarginContainer/ButtonsContainer/SettingsButton
@onready var exit_button = $UI/VBoxContainer/MenuPanel/MarginContainer/ButtonsContainer/ExitButton

var background_path = "res://assets/backgrounds/space/ship-frontwiew.jpg"
var save_slots_popup_scene = preload("res://scenes/ui/save_slots_popup.tscn")


func _ready():
	show_background()
	
	fade_overlay.color.a = 1.0
	await fade_from_black(2.0)
	
	new_game_button.pressed.connect(_on_new_game_pressed)
	continue_button.pressed.connect(_on_continue_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	exit_button.pressed.connect(_on_exit_pressed)
	
	update_continue_button()


func show_background():
	var texture = load(background_path)
	
	if texture == null:
		push_error("Не удалось загрузить фон: " + background_path)
		return
	
	background_texture.texture = texture


func fade_from_black(duration: float) -> void:
	var tween = create_tween()
	tween.tween_property(fade_overlay, "color:a", 0.0, duration)
	await tween.finished


func update_continue_button():
	# Кнопка Continue активна, если есть хотя бы одно сохранение
	continue_button.disabled = not SaveManager.has_any_save()


func _on_new_game_pressed():
	var popup = save_slots_popup_scene.instantiate()
	popup.mode = "new_game"
	
	add_child(popup)
	popup.new_game_confirmed.connect(_on_new_game_slot_confirmed)


func _on_continue_pressed():
	var popup = save_slots_popup_scene.instantiate()
	popup.mode = "continue"
	
	add_child(popup)
	popup.continue_confirmed.connect(_on_continue_slot_confirmed)


func _on_new_game_slot_confirmed(slot_id: int, pilot_name: String) -> void:
	# Создаем новое сохранение в выбранном слоте.
	# Пока без интро — сразу переходим в ship_scene.
	SaveManager.create_new_game(slot_id, pilot_name)
	update_continue_button()
	
	get_tree().change_scene_to_file("res://scenes/ship/ship_scene.tscn")


func _on_continue_slot_confirmed(slot_id: int) -> void:
	# Пока просто открываем ship_scene.
	# На следующем этапе свяжем это с реальной загрузкой состояния.
	var save_data = SaveManager.load_slot(slot_id)
	
	if save_data.is_empty():
		return
	
	get_tree().change_scene_to_file("res://scenes/ship/ship_scene.tscn")


func _on_settings_pressed():
	print("Открыть настройки")


func _on_exit_pressed():
	get_tree().quit()
