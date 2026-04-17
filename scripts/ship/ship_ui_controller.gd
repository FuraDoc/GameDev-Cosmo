extends CanvasLayer

# =========================================================
# SHIP UI CONTROLLER
# =========================================================
# Этот контроллер отвечает за:
# - кнопки в ship_scene
# - fade
# - открытие окна квеста
# - подтверждение перехода в следующую локацию
# - запрос на открытие Cargo Bay
# =========================================================

signal menu_requested
signal next_adventure_requested
signal text_quest_requested
signal continue_quest_requested
signal cargo_bay_requested

@onready var fade_overlay = $FadeOverlay

@onready var text_quest_button = $ButtonsRoot/VBoxContainer/TextQuestButton
@onready var continue_quest_button = $ButtonsRoot/VBoxContainer/ContinueQuestButton
@onready var next_adventure_button = $ButtonsRoot/VBoxContainer/NextAdventureButton
@onready var equipment_button = $ButtonsRoot/VBoxContainer/EquipmentButton
@onready var menu_button = $ButtonsRoot/VBoxContainer/MenuButton
@onready var cargo_bay_button = $ButtonsRoot/VBoxContainer/CargoBayButton
@onready var windows_root = $WindowsRoot

var text_quest_scene_path := "res://scenes/text_quest/text_quest.tscn"


func _ready():
	fade_overlay.color.a = 0.0

	menu_button.pressed.connect(_on_menu_button_pressed)
	next_adventure_button.pressed.connect(_on_next_adventure_button_pressed)
	text_quest_button.pressed.connect(_on_text_quest_button_pressed)
	continue_quest_button.pressed.connect(_on_continue_quest_button_pressed)
	cargo_bay_button.pressed.connect(_on_cargo_bay_button_pressed)

	# Если старая кнопка EquipmentButton еще остается в сцене,
	# можно временно просто скрыть или отключить ее позже.
	# Сейчас она больше не участвует в новой логике Cargo Bay.

	update_quest_buttons()


func update_quest_buttons() -> void:
	if QuestRuntime.can_start():
		text_quest_button.disabled = false
		continue_quest_button.disabled = true
	elif QuestRuntime.can_continue():
		text_quest_button.disabled = true
		continue_quest_button.disabled = false
	else:
		text_quest_button.disabled = true
		continue_quest_button.disabled = true


func _on_menu_button_pressed() -> void:
	menu_requested.emit()


func _on_next_adventure_button_pressed() -> void:
	next_adventure_requested.emit()


func _on_text_quest_button_pressed() -> void:
	text_quest_requested.emit()


func _on_continue_quest_button_pressed() -> void:
	continue_quest_requested.emit()


func _on_cargo_bay_button_pressed() -> void:
	cargo_bay_requested.emit()


func open_text_quest(path: String, continue_from_runtime: bool = false) -> void:
	if windows_root.has_node("TextQuest"):
		return

	var quest_scene = load(text_quest_scene_path)
	if quest_scene == null:
		push_error("Не удалось загрузить сцену текстового квеста")
		return

	var quest_instance = quest_scene.instantiate()
	quest_instance.name = "TextQuest"
	quest_instance.quest_path = path
	quest_instance.continue_from_runtime = continue_from_runtime

	quest_instance.quest_closed.connect(_on_text_quest_window_closed)
	quest_instance.quest_completed.connect(_on_text_quest_window_completed)

	windows_root.add_child(quest_instance)
	quest_instance.move_to_front()


func _on_text_quest_window_closed() -> void:
	update_quest_buttons()


func _on_text_quest_window_completed() -> void:
	update_quest_buttons()


func confirm_next_adventure(message: String, on_confirm: Callable) -> void:
	var dialog = ConfirmationDialog.new()
	dialog.title = "Подтверждение"
	dialog.dialog_text = message

	windows_root.add_child(dialog)

	dialog.get_ok_button().text = "Принять"
	dialog.get_cancel_button().text = "Отклонить"

	dialog.confirmed.connect(func():
		if on_confirm.is_valid():
			on_confirm.call()
		dialog.queue_free()
	)

	dialog.canceled.connect(func():
		dialog.queue_free()
	)

	dialog.popup_centered()


func _wait_for_confirmation_result(dialog: ConfirmationDialog) -> bool:
	var pressed_ok := false

	dialog.confirmed.connect(func():
		pressed_ok = true
	)

	dialog.popup_centered()
	await dialog.visibility_changed

	return pressed_ok
	
	
func set_main_buttons_enabled(enabled: bool) -> void:
	next_adventure_button.disabled = not enabled
	menu_button.disabled = not enabled
	cargo_bay_button.disabled = not enabled
	
	if is_instance_valid(equipment_button):
		equipment_button.disabled = not enabled
	
	if enabled:
		update_quest_buttons()
	else:
		text_quest_button.disabled = true
		continue_quest_button.disabled = true


func play_transition() -> void:
	var tween = create_tween()
	tween.tween_property(fade_overlay, "color:a", 1.0, 1.0)
	await tween.finished
	await get_tree().create_timer(1.0).timeout


func play_fade_in() -> void:
	var tween = create_tween()
	tween.tween_property(fade_overlay, "color:a", 0.0, 1.0)
	await tween.finished
