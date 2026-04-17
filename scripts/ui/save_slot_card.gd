extends Control

signal new_game_requested(slot_id: int, pilot_name: String)
signal continue_requested(slot_id: int)

@onready var panel_background = $PanelBackground
@onready var slot_title_label = $ContentMargin/VBox/SlotTitleLabel
@onready var status_label = $ContentMargin/VBox/StatusLabel
@onready var pilot_name_label = $ContentMargin/VBox/PilotNameLabel
@onready var location_label = $ContentMargin/VBox/LocationLabel
@onready var progress_label = $ContentMargin/VBox/ProgressLabel
@onready var time_label = $ContentMargin/VBox/TimeLabel
@onready var name_prompt_label = $ContentMargin/VBox/NamePromptLabel
@onready var name_line_edit = $ContentMargin/VBox/NameLineEdit
@onready var action_button = $ContentMargin/VBox/ActionButton

var mode: String = "new_game"
var slot_data: Dictionary = {}
var slot_id: int = 0

# Если уже есть текстура монитора — впиши путь сюда
var monitor_texture_path := ""

func _ready():
	action_button.pressed.connect(_on_action_button_pressed)
	apply_monitor_texture()
	refresh()


func setup(new_mode: String, new_slot_data: Dictionary) -> void:
	mode = new_mode
	slot_data = new_slot_data
	slot_id = slot_data.get("slot_id", 0)


func apply_monitor_texture() -> void:
	if monitor_texture_path.is_empty():
		return
	
	var texture = load(monitor_texture_path)
	if texture != null:
		panel_background.texture = texture


func refresh() -> void:
	var exists = slot_data.get("exists", false)
	
	slot_title_label.text = "Слот %d" % slot_id
	
	if mode == "new_game":
		_setup_new_game_mode(exists)
	else:
		_setup_continue_mode(exists)


func _setup_new_game_mode(exists: bool) -> void:
	status_label.visible = true
	name_prompt_label.visible = true
	name_line_edit.visible = true
	action_button.visible = true
	
	pilot_name_label.visible = false
	location_label.visible = false
	progress_label.visible = false
	time_label.visible = false
	
	if exists:
		var pilot_name = slot_data.get("pilot_name", "Без имени")
		status_label.text = "Занят: %s" % pilot_name
	else:
		status_label.text = "Пустой слот"
	
	name_prompt_label.text = "Введите имя пилота"
	action_button.text = "Подтвердить"
	action_button.disabled = false


func _setup_continue_mode(exists: bool) -> void:
	name_prompt_label.visible = false
	name_line_edit.visible = false
	
	status_label.visible = true
	pilot_name_label.visible = true
	location_label.visible = true
	progress_label.visible = true
	time_label.visible = true
	action_button.visible = true
	
	if not exists:
		status_label.text = "Пустой слот"
		pilot_name_label.text = ""
		location_label.text = ""
		progress_label.text = ""
		time_label.text = ""
		action_button.text = "Загрузить"
		action_button.disabled = true
		return
	
	var pilot_name = slot_data.get("pilot_name", "Без имени")
	var location_name = slot_data.get("current_adventure_id", "Неизвестно")
	var completed = slot_data.get("completed_quests_count", 0)
	var play_time_seconds = slot_data.get("play_time_seconds", 0)
	
	status_label.text = "Сохранение найдено"
	pilot_name_label.text = "Пилот: %s" % pilot_name
	location_label.text = "Локация: %s" % location_name
	progress_label.text = "Квестов пройдено: %d" % completed
	time_label.text = "Время в игре: %s" % _format_play_time(play_time_seconds)
	
	action_button.text = "Загрузить"
	action_button.disabled = false


func _format_play_time(total_seconds: int) -> String:
	var hours = total_seconds / 3600
	var minutes = (total_seconds % 3600) / 60
	return "%02d:%02d" % [hours, minutes]


func _on_action_button_pressed() -> void:
	if mode == "new_game":
		var pilot_name = name_line_edit.text.strip_edges()
		if pilot_name.is_empty():
			return
		new_game_requested.emit(slot_id, pilot_name)
	else:
		if not slot_data.get("exists", false):
			return
		continue_requested.emit(slot_id)
