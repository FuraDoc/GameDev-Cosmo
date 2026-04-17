extends Control

# =========================================================
# TEXT QUEST WINDOW
# =========================================================
# Этот скрипт управляет окном текстового квеста.
#
# Он умеет:
# - загружать JSON-квест
# - показывать узлы
# - создавать кнопки выборов
# - фильтровать choices по required_item
# - сохранять текущий узел в QuestRuntime
# - завершать квест корректно
#
# Важно:
# само окно НЕ хранит прогресс как источник истины.
# Прогресс хранится в QuestRuntime.
# =========================================================

signal quest_closed
signal quest_completed

# =========================
# UI
# =========================
@onready var title_label = $CenterContainer/QuestPanel/MarginContainer/VBoxContainer/HeaderRow/TitleLabel
@onready var story_label = $CenterContainer/QuestPanel/MarginContainer/VBoxContainer/ScrollContainer/StoryLabel
@onready var choices_container = $CenterContainer/QuestPanel/MarginContainer/VBoxContainer/ChoicesContainer
@onready var scroll_container = $CenterContainer/QuestPanel/MarginContainer/VBoxContainer/ScrollContainer
@onready var close_button = $CenterContainer/QuestPanel/MarginContainer/VBoxContainer/HeaderRow/CloseButton

# =========================
# DATA
# =========================
var quest_data = {}
var current_node_id = ""
var quest_path = ""

# Если true — начинаем с сохраненного узла из QuestRuntime
# Если false — начинаем с поля "start" в JSON
var continue_from_runtime: bool = false


func _ready():
	# Кнопка в заголовке просто закрывает окно.
	close_button.pressed.connect(_on_header_close_button_pressed)
	
	if quest_path != "":
		load_quest(quest_path)
	else:
		push_error("Не задан путь к квесту")


func load_quest(path: String):
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Не удалось открыть файл квеста: " + path)
		return
	
	var content = file.get_as_text()
	
	var json = JSON.new()
	var result = json.parse(content)
	
	if result != OK:
		push_error("Ошибка парсинга JSON: " + path)
		return
	
	quest_data = json.data
	
	if not quest_data.has("start"):
		push_error("В квесте нет поля start")
		return
	
	if not quest_data.has("nodes"):
		push_error("В квесте нет поля nodes")
		return
	
	# Если открываем квест в режиме "продолжить",
	# идем на сохраненный узел.
	if continue_from_runtime and QuestRuntime.current_node_id != "":
		show_node(QuestRuntime.current_node_id)
	else:
		# Иначе это новый запуск.
		current_node_id = quest_data["start"]
		QuestRuntime.mark_started(current_node_id)
		show_node(current_node_id)


func show_node(node_id: String):
	if not quest_data["nodes"].has(node_id):
		push_error("Узел не найден: " + node_id)
		return
	
	current_node_id = node_id
	QuestRuntime.update_current_node(current_node_id)
	
	var node = quest_data["nodes"][node_id]
	
	title_label.text = quest_data.get("title", "Текстовый квест")
	story_label.text = node.get("text", "")
	scroll_container.scroll_vertical = 0
	
	clear_choices()
	
	var choices = get_available_choices(node)
	
	# Если choices не осталось, это конец.
	# Значит квест завершён окончательно.
	if choices.is_empty():
		QuestRuntime.mark_completed(current_node_id)
		add_finish_button()
		return
	
	for choice in choices:
		add_choice_button(choice)


func get_available_choices(node_data: Dictionary) -> Array:
	var result: Array = []
	var choices = node_data.get("choices", [])
	
	for choice in choices:
		var required_item = choice.get("required_item", "")
		
		if required_item.is_empty():
			result.append(choice)
			continue
		
		if PlayerState.has_item(required_item):
			result.append(choice)
	
	return result


func clear_choices():
	for child in choices_container.get_children():
		child.queue_free()


func add_finish_button():
	# Эта кнопка показывается только на финальном узле.
	# То есть квест уже завершен.
	var finish_button = Button.new()
	finish_button.text = "Завершить"
	finish_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	finish_button.custom_minimum_size = Vector2(0, 44)
	finish_button.pressed.connect(_on_finish_button_pressed)
	choices_container.add_child(finish_button)


func add_choice_button(choice: Dictionary):
	var button = Button.new()
	button.text = choice.get("text", "Далее")
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.custom_minimum_size = Vector2(0, 44)
	
	var next_node_id = choice.get("next", "")
	button.pressed.connect(_on_choice_pressed.bind(next_node_id))
	
	choices_container.add_child(button)


func _on_choice_pressed(next_node_id: String):
	if next_node_id.is_empty():
		push_error("У выбора отсутствует поле next")
		return
	
	show_node(next_node_id)


func _on_header_close_button_pressed():
	# Игрок просто закрыл окно.
	# Если квест не завершён, его можно будет продолжить позже.
	quest_closed.emit()
	queue_free()


func _on_finish_button_pressed():
	# Игрок закрыл уже завершенный квест.
	quest_completed.emit()
	queue_free()
