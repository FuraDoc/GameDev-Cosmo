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

# Визуальный контроллер корабля: отвечает за фон космоса, кокпит, слои и перископ.
@onready var view_controller = $ViewportRoot

# Контроллер приключений: хранит список локаций, фон и путь к JSON-квесту.
@onready var adventure_controller = $AdventureController

# UI-контроллер корабля: кнопки HUD, fade, окна квеста и Cargo Bay.
@onready var ui_controller = $UI

# Флаг перехода между приключениями: защищает от повторного нажатия во время fade.
var is_transitioning := false

# Флаг перехода перископа: защищает от повторного Space во время анимации.
var is_periscope_transitioning := false

# Сцена полноэкранного грузового отсека: инстанцируется при нажатии кнопки Cargo Bay.
var cargo_bay_popup_scene = preload("res://scenes/ui/cargo_bay_popup.tscn")


# _ready — «готово»: подключает UI, показывает текущую локацию и настраивает квест.
func _ready():
	connect_ui_signals()
	show_current_adventure()
	setup_current_adventure_quest_state()


# _unhandled_input — «необработанный ввод»: Space включает/выключает режим перископа.
func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey):
		return

	var key_event := event as InputEventKey

	if not key_event.pressed or key_event.echo:
		return

	if key_event.keycode != KEY_SPACE:
		return

	if is_transitioning or is_periscope_transitioning:
		return

	get_viewport().set_input_as_handled()
	toggle_periscope_mode()


# connect_ui_signals — «подключить сигналы UI»: связывает кнопки HUD с методами сцены.
func connect_ui_signals() -> void:
	ui_controller.menu_requested.connect(_on_menu_requested)
	ui_controller.next_adventure_requested.connect(_on_next_adventure_requested)
	ui_controller.text_quest_requested.connect(_on_text_quest_requested)
	ui_controller.continue_quest_requested.connect(_on_continue_quest_requested)
	ui_controller.cargo_bay_requested.connect(_on_cargo_bay_requested)


# _on_cargo_bay_requested — «запрошен грузовой отсек»: открывает fullscreen Cargo Bay popup.
func _on_cargo_bay_requested() -> void:
	ui_controller.set_main_buttons_enabled(false)
	view_controller.visible = false
	
	var popup = cargo_bay_popup_scene.instantiate()
	ui_controller.windows_root.add_child(popup)
	popup.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	popup.move_to_front()
	
	popup.popup_closed.connect(_on_cargo_bay_closed)
	

# _on_cargo_bay_closed — «грузовой отсек закрыт»: возвращает вид корабля и кнопки HUD.
func _on_cargo_bay_closed() -> void:
	view_controller.visible = true
	ui_controller.set_main_buttons_enabled(true)


# show_current_adventure — «показать текущее приключение»: ставит фон космоса текущей локации.
func show_current_adventure() -> void:
	var background_path = adventure_controller.get_current_background_path()
	
	if background_path.is_empty():
		push_error("Пустой путь к фону текущего приключения")
		return
	
	view_controller.set_space_background(background_path)
	adventure_controller.debug_print_current_adventure()


# setup_current_adventure_quest_state — «настроить состояние квеста»: сбрасывает QuestRuntime.
func setup_current_adventure_quest_state() -> void:
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


# _on_menu_requested — «запрошено меню»: возвращает игрока в main_scene.
func _on_menu_requested() -> void:
	get_tree().change_scene_to_file("res://scenes/main/main_scene.tscn")


# _on_text_quest_requested — «запрошен текстовый квест»: открывает квест с начала.
func _on_text_quest_requested() -> void:
	var quest_path = adventure_controller.get_current_quest_path()
	
	if quest_path.is_empty():
		push_error("Пустой путь к квесту текущего приключения")
		return
	
	ui_controller.open_text_quest(quest_path, false)
	ui_controller.update_quest_buttons()


# _on_continue_quest_requested — «запрошено продолжение квеста»: открывает сохраненный узел.
func _on_continue_quest_requested() -> void:
	var quest_path = adventure_controller.get_current_quest_path()
	
	if quest_path.is_empty():
		push_error("Пустой путь к квесту текущего приключения")
		return
	
	if not QuestRuntime.can_continue():
		return
	
	ui_controller.open_text_quest(quest_path, true)
	ui_controller.update_quest_buttons()


# _on_next_adventure_requested — «запрошено следующее приключение»: показывает подтверждение.
func _on_next_adventure_requested() -> void:
	if is_transitioning:
		return
	
	var confirm_message := ""
	
	if QuestRuntime.is_completed():
		confirm_message = Localization.tr_text("ship.jump_confirm_completed")
	else:
		confirm_message = Localization.tr_text("ship.jump_confirm_unfinished")
	
	ui_controller.confirm_next_adventure(confirm_message, Callable(self, "_confirm_and_start_next_adventure"))


# _confirm_and_start_next_adventure — «подтвердить и начать следующее приключение»: делает прыжок.
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


# toggle_periscope_mode — «переключить режим перископа»: fade, скрытие HUD и смена вида.
func toggle_periscope_mode() -> void:
	if is_periscope_transitioning:
		return

	is_periscope_transitioning = true
	ui_controller.set_main_buttons_enabled(false)

	await ui_controller.fade_to(1.0, 0.5)

	if view_controller.is_periscope_active():
		view_controller.set_periscope_active(false)
		ui_controller.set_ship_hud_visible(true)
		ui_controller.set_main_buttons_enabled(true)
	else:
		ui_controller.set_ship_hud_visible(false)
		view_controller.set_periscope_active(true)

	await ui_controller.fade_to(0.0, 0.5)

	if not view_controller.is_periscope_active():
		ui_controller.set_ship_hud_visible(true)
		ui_controller.set_main_buttons_enabled(true)

	is_periscope_transitioning = false
