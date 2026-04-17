extends Control

# =========================================================
# SHIP SCENE
# =========================================================
# Главная сцена координирует:
# - визуальный контроллер
# - приключения
# - UI
# - текущее состояние квеста через QuestRuntime
# =========================================================

@onready var view_controller = $ViewportRoot
@onready var adventure_controller = $AdventureController
@onready var ui_controller = $UI

var is_transitioning := false

var cargo_bay_popup_scene = preload("res://scenes/ui/cargo_bay_popup.tscn")


func _ready():
	connect_ui_signals()
	show_current_adventure()
	setup_current_adventure_quest_state()


func connect_ui_signals() -> void:
	ui_controller.menu_requested.connect(_on_menu_requested)
	ui_controller.next_adventure_requested.connect(_on_next_adventure_requested)
	ui_controller.text_quest_requested.connect(_on_text_quest_requested)
	ui_controller.continue_quest_requested.connect(_on_continue_quest_requested)
	ui_controller.cargo_bay_requested.connect(_on_cargo_bay_requested)


func _on_cargo_bay_requested() -> void:
	ui_controller.set_main_buttons_enabled(false)
	
	var popup = cargo_bay_popup_scene.instantiate()
	add_child(popup)
	
	popup.popup_closed.connect(_on_cargo_bay_closed)
	
	
func _on_cargo_bay_closed() -> void:
	ui_controller.set_main_buttons_enabled(true)


func show_current_adventure() -> void:
	var background_path = adventure_controller.get_current_background_path()
	
	if background_path.is_empty():
		push_error("Пустой путь к фону текущего приключения")
		return
	
	view_controller.set_space_background(background_path)
	adventure_controller.debug_print_current_adventure()


func setup_current_adventure_quest_state() -> void:
	# Каждый раз, когда мы оказываемся в новой локации,
	# инициализируем состояние ее квеста.
	var adventure_id = adventure_controller.get_current_adventure_id()
	var quest_path = adventure_controller.get_current_quest_path()
	
	if adventure_id.is_empty():
		push_error("Пустой adventure_id")
		return
	
	if quest_path.is_empty():
		push_error("Пустой quest_path")
		return
	
	QuestRuntime.setup_for_adventure(adventure_id, quest_path)
	ui_controller.update_quest_buttons()


func _on_menu_requested() -> void:
	get_tree().change_scene_to_file("res://scenes/main/main_scene.tscn")


func _on_text_quest_requested() -> void:
	var quest_path = adventure_controller.get_current_quest_path()
	
	if quest_path.is_empty():
		push_error("Пустой путь к квесту текущего приключения")
		return
	
	ui_controller.open_text_quest(quest_path, false)
	ui_controller.update_quest_buttons()


func _on_continue_quest_requested() -> void:
	var quest_path = adventure_controller.get_current_quest_path()
	
	if quest_path.is_empty():
		push_error("Пустой путь к квесту текущего приключения")
		return
	
	if not QuestRuntime.can_continue():
		return
	
	ui_controller.open_text_quest(quest_path, true)
	ui_controller.update_quest_buttons()


func _on_next_adventure_requested() -> void:
	if is_transitioning:
		return
	
	var confirm_message := ""
	
	if QuestRuntime.is_completed():
		confirm_message = "Совершить прыжок в другую локацию?"
	else:
		confirm_message = "Здесь еще есть кое-что интересное! Оставить локацию и лететь дальше?"
	
	ui_controller.confirm_next_adventure(confirm_message, Callable(self, "_confirm_and_start_next_adventure"))


func _confirm_and_start_next_adventure() -> void:
	if is_transitioning:
		return
	
	is_transitioning = true
	
	await ui_controller.play_transition()
	adventure_controller.go_to_next_adventure()
	show_current_adventure()
	setup_current_adventure_quest_state()
	await ui_controller.play_fade_in()
	
	is_transitioning = false
