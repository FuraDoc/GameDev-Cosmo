extends Control

@onready var title_label = $MarginContainer/VBoxContainer/TitleLabel
@onready var story_label = $MarginContainer/VBoxContainer/ScrollContainer/StoryLabel
@onready var choices_container = $MarginContainer/VBoxContainer/ChoicesContainer

var quest_data = {}
var current_node_id = ""

func _ready():
	load_quest("res://data/quests/test_quest.json")

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
	
	current_node_id = quest_data["start"]
	show_node(current_node_id)

func show_node(node_id: String):
	if not quest_data["nodes"].has(node_id):
		push_error("Узел не найден: " + node_id)
		return
	
	current_node_id = node_id
	var node = quest_data["nodes"][node_id]
	
	title_label.text = quest_data.get("title", "Текстовый квест")
	story_label.text = node.get("text", "")
	
	for child in choices_container.get_children():
		child.queue_free()
	
	var choices = node.get("choices", [])
	for choice in choices:
		var button = Button.new()
		button.text = choice.get("text", "Далее")
		button.pressed.connect(func(): show_node(choice.get("next", "")))
		choices_container.add_child(button)


func _on_close_button_pressed():
	queue_free()
