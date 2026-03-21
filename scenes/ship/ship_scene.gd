extends Control

# Ссылка на узел, который показывает космос за окном кабины
@onready var space_view = $SpaceView

# Ссылка на черный слой затемнения для анимации перехода
@onready var fade_overlay = $UI/FadeOverlay


# Список приключений.
# У каждого приключения есть:
# - background: путь к картинке космоса
# - quest: путь к JSON-файлу текстового квеста
var adventures = [
	{
		"background": "res://assets/backgrounds/space/cosmo 6.jpg",
		"quest": "res://data/quests/quest_signal.json"
	},
	{
		"background": "res://assets/backgrounds/space/cosmo 7.jpg",
		"quest": "res://data/quests/quest_derelict.json"
	},
	{
		"background": "res://assets/backgrounds/space/cosmo 21.jpg",
		"quest": "res://data/quests/quest_smugglers.json"
	}
]

# Индекс текущего приключения в массиве adventures
var current_adventure_index = 0

# Флаг, который не дает нажимать кнопку перехода много раз подряд,
# пока еще идет анимация затемнения/осветления
var is_transitioning = false


func _ready():
	# При запуске сцены сразу показываем первое приключение
	update_adventure()


func _on_menu_button_pressed():
	# Возврат в главное меню
	get_tree().change_scene_to_file("res://scenes/main/main_scene.tscn")


func _on_text_quest_button_pressed():
	# Берем текущее приключение по индексу
	var adventure = adventures[current_adventure_index]
	
	# Открываем квест, привязанный к текущему приключению
	open_text_quest(adventure["quest"])


func open_text_quest(path: String):
	# Если окно квеста уже открыто, не создаем второе
	if $UI.has_node("TextQuest"):
		return
	
	# Загружаем сцену текстового квеста
	var quest_scene = load("res://scenes/text_quest/text_quest.tscn")
	
	# Создаем экземпляр сцены
	var quest_instance = quest_scene.instantiate()
	
	# Даем экземпляру имя, чтобы потом можно было проверить,
	# открыт он уже или нет
	quest_instance.name = "TextQuest"
	
	# Передаем путь к нужному квесту
	quest_instance.quest_path = path
	
	# Добавляем окно квеста в UI-слой поверх сцены корабля
	$UI.add_child(quest_instance)
	
	# Поднимаем квест поверх остальных UI-элементов
	quest_instance.move_to_front()


func _on_next_adventure_button_pressed():
	# Если переход уже идет, повторное нажатие игнорируем
	if is_transitioning:
		return
	
	is_transitioning = true
	
	# 1. Затемняем экран
	await play_transition()
	
	# 2. Переключаемся на следующее приключение
	current_adventure_index += 1
	
	# Если вышли за пределы массива, начинаем снова с первого
	if current_adventure_index >= adventures.size():
		current_adventure_index = 0
	
	# Для отладки выводим текущий индекс
	print("Текущий индекс приключения: ", current_adventure_index)
	
	# 3. Обновляем фон под новое приключение
	update_adventure()
	
	# 4. Возвращаем изображение из темноты
	await play_fade_in()
	
	is_transitioning = false


func update_adventure():
	# Берем данные текущего приключения
	var adventure = adventures[current_adventure_index]
	
	# Получаем путь к фону
	var background_path = adventure["background"]
	
	# Загружаем картинку
	var texture = load(background_path)
	
	# Если картинка не загрузилась, выводим ошибку
	if texture == null:
		push_error("Не удалось загрузить фон: " + background_path)
		return
	
	# Если все хорошо - назначаем картинку в SpaceView
	space_view.texture = texture
	
	# Для проверки выводим путь в консоль
	print("Текущий фон: ", background_path)


func play_transition() -> void:
	# Создаем анимацию плавного затемнения
	var tween = create_tween()
	
	# За 1 секунду делаем черный слой полностью непрозрачным
	tween.tween_property(fade_overlay, "color:a", 1.0, 1.0)
	
	# Ждем окончания затемнения
	await tween.finished
	
	# Держим черный экран еще 1 секунду
	await get_tree().create_timer(1.0).timeout


func play_fade_in() -> void:
	# Создаем анимацию плавного возвращения изображения
	var tween = create_tween()
	
	# За 1 секунду убираем затемнение
	tween.tween_property(fade_overlay, "color:a", 0.0, 1.0)
	
	# Ждем окончания анимации
	await tween.finished
