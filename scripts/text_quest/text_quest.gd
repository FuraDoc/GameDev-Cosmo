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

# Сигнал закрытия окна: квест не обязательно завершен, ShipUI обновит кнопки.
signal quest_closed

# Сигнал завершения квеста: ShipUI обновит кнопки после финального узла.
signal quest_completed

# =========================
# UI
# =========================
# Заголовок окна: берет title из JSON-квеста.
@onready var title_label = $CenterContainer/QuestPanel/MarginContainer/VBoxContainer/HeaderRow/TitleLabel

# Текст текущего узла квеста.
@onready var story_label = $CenterContainer/QuestPanel/MarginContainer/VBoxContainer/ScrollContainer/StoryLabel

# Контейнер кнопок выбора: пересобирается при каждом переходе узла.
@onready var choices_container = $CenterContainer/QuestPanel/MarginContainer/VBoxContainer/ChoicesContainer

# ScrollContainer текста: сбрасывается наверх при переходе на новый узел.
@onready var scroll_container = $CenterContainer/QuestPanel/MarginContainer/VBoxContainer/ScrollContainer

# Кнопка закрытия в заголовке окна.
@onready var close_button = $CenterContainer/QuestPanel/MarginContainer/VBoxContainer/HeaderRow/CloseButton

# =========================
# DATA
# =========================
# Загруженный JSON-квест: содержит start, title и nodes.
var quest_data = {}

# Текущий node_id: сохраняется в QuestRuntime для продолжения.
var current_node_id = ""

# Путь к JSON-файлу квеста: задается перед открытием окна.
var quest_path = ""

# Режим продолжения: true начинает с QuestRuntime.current_node_id, false — с JSON start.
var continue_from_runtime: bool = false


# _ready — «готово»: подключает кнопку закрытия и загружает квест по quest_path.
func _ready():
	close_button.pressed.connect(_on_header_close_button_pressed)
	Localization.language_changed.connect(_on_language_changed)
	_apply_localization()
	
	if quest_path != "":
		load_quest(quest_path)
	else:
		push_error("Не задан путь к квесту")


# load_quest — «загрузить квест»: читает JSON, проверяет start/nodes и выбирает стартовый узел.
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
	
	# В режиме продолжения идем на сохраненный узел, иначе стартуем с поля start.
	if continue_from_runtime and QuestRuntime.current_node_id != "":
		show_node(QuestRuntime.current_node_id)
	else:
		current_node_id = quest_data["start"]
		QuestRuntime.mark_started(current_node_id)
		show_node(current_node_id)


# show_node — «показать узел»: обновляет текст, choices и состояние QuestRuntime.
func show_node(node_id: String):
	if not quest_data["nodes"].has(node_id):
		push_error("Узел не найден: " + node_id)
		return
	
	current_node_id = node_id
	QuestRuntime.update_current_node(current_node_id)
	
	var node = quest_data["nodes"][node_id]
	
	title_label.text = quest_data.get("title", Localization.tr_text("quest.default_title"))
	story_label.text = node.get("text", "")
	scroll_container.scroll_vertical = 0
	
	clear_choices()
	
	var choices = get_available_choices(node)
	
	# Если choices не осталось, это конец: квест завершается и появляется кнопка «Завершить».
	if choices.is_empty():
		QuestRuntime.mark_completed(current_node_id)
		add_finish_button()
		return
	
	for choice in choices:
		add_choice_button(choice)


# get_available_choices — «получить доступные выборы»: фильтрует choices по required_item/suit.
func get_available_choices(node_data: Dictionary) -> Array:
	var result: Array = []
	var choices = node_data.get("choices", [])
	
	for choice in choices:
		var required_item = choice.get("required_item", "")
		var required_suit = choice.get("required_suit", "")
		
		if not required_item.is_empty() and not PlayerState.has_item(required_item):
			continue
		
		if not required_suit.is_empty() and not PlayerState.has_active_suit(required_suit):
			continue

		result.append(choice)
	
	return result


# clear_choices — «очистить выборы»: удаляет старые кнопки перед показом нового узла.
func clear_choices():
	for child in choices_container.get_children():
		child.queue_free()


# add_finish_button — «добавить кнопку завершения»: создает финальную кнопку закрытия квеста.
func add_finish_button():
	var finish_button = Button.new()
	finish_button.text = Localization.tr_text("quest.finish")
	finish_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	finish_button.custom_minimum_size = Vector2(0, 44)
	finish_button.pressed.connect(_on_finish_button_pressed)
	choices_container.add_child(finish_button)


# add_choice_button — «добавить кнопку выбора»: создает кнопку перехода на next-узел.
func add_choice_button(choice: Dictionary):
	var button = Button.new()
	button.text = choice.get("text", Localization.tr_text("quest.next"))
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.custom_minimum_size = Vector2(0, 44)
	
	var next_node_id = choice.get("next", "")
	button.pressed.connect(_on_choice_pressed.bind(next_node_id))
	
	choices_container.add_child(button)


# _on_choice_pressed — «нажат выбор»: проверяет next и показывает следующий узел.
func _on_choice_pressed(next_node_id: String):
	if next_node_id.is_empty():
		push_error("У выбора отсутствует поле next")
		return
	
	show_node(next_node_id)


# _on_header_close_button_pressed — «нажата кнопка закрытия»: закрывает окно без завершения.
func _on_header_close_button_pressed():
	quest_closed.emit()
	queue_free()


# _on_finish_button_pressed — «нажата кнопка завершения»: закрывает уже завершенный квест.
func _on_finish_button_pressed():
	quest_completed.emit()
	queue_free()


func _apply_localization() -> void:
	close_button.text = Localization.tr_text("quest.close")


func _on_language_changed(_language_code: String) -> void:
	_apply_localization()
