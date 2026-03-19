extends Control

# Ссылки на элементы интерфейса окна квеста
@onready var title_label = $CenterContainer/QuestPanel/MarginContainer/VBoxContainer/HeaderRow/TitleLabel
@onready var story_label = $CenterContainer/QuestPanel/MarginContainer/VBoxContainer/ScrollContainer/StoryLabel
@onready var choices_container = $CenterContainer/QuestPanel/MarginContainer/VBoxContainer/ChoicesContainer
@onready var scroll_container = $CenterContainer/QuestPanel/MarginContainer/VBoxContainer/ScrollContainer
# Данные загруженного квеста
var quest_data = {}

# ID текущего узла
var current_node_id = ""

# Путь к файлу квеста, который передается из сцены корабля
var quest_path = ""


func _ready():
	# Загружаем квест, если путь был передан
	if quest_path != "":
		load_quest(quest_path)
	else:
		push_error("Не задан путь к квесту")


func load_quest(path: String):
	# Открываем JSON-файл
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Не удалось открыть файл квеста: " + path)
		return
	
	# Читаем содержимое файла
	var content = file.get_as_text()
	
	# Парсим JSON
	var json = JSON.new()
	var result = json.parse(content)
	
	if result != OK:
		push_error("Ошибка парсинга JSON: " + path)
		return
	
	# Сохраняем данные
	quest_data = json.data
	
	# Проверяем обязательные поля
	if not quest_data.has("start"):
		push_error("В квесте нет поля start")
		return
	
	if not quest_data.has("nodes"):
		push_error("В квесте нет поля nodes")
		return
	
	# Показываем стартовый узел
	current_node_id = quest_data["start"]
	show_node(current_node_id)


func show_node(node_id: String):
	# Проверяем, существует ли узел
	if not quest_data["nodes"].has(node_id):
		push_error("Узел не найден: " + node_id)
		return
	
	current_node_id = node_id
	var node = quest_data["nodes"][node_id]
	
	# Обновляем заголовок и текст
	title_label.text = quest_data.get("title", "Текстовый квест")
	story_label.text = node.get("text", "")
	scroll_container.scroll_vertical = 0
	
	# Удаляем старые кнопки
	for child in choices_container.get_children():
		child.queue_free()
	
	var choices = node.get("choices", [])
	
	# Если это концовка - показываем кнопку закрытия
	if choices.is_empty():
		var close_button = Button.new()
		close_button.text = "Закрыть"
		close_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		close_button.custom_minimum_size = Vector2(0, 44)
		close_button.pressed.connect(_on_close_button_pressed)
		choices_container.add_child(close_button)
		return
	
	# Иначе создаем кнопки выбора
	for choice in choices:
		var button = Button.new()
		button.text = choice.get("text", "Далее")
		# Растягиваем кнопку по ширине контейнера
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		# Делаем одинаковую удобную высоту
		button.custom_minimum_size = Vector2(0, 44)
		button.pressed.connect(func(): show_node(choice.get("next", "")))
		choices_container.add_child(button)


func _on_close_button_pressed():
	# Закрываем окно квеста
	queue_free()
