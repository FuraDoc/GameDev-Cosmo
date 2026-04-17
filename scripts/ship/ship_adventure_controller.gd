extends Node

# Этот контроллер отвечает только за данные приключений.
# Он НЕ занимается UI, НЕ управляет слоями и НЕ открывает окна.
# Его задача — хранить список приключений и отдавать текущее активное приключение.


# Список приключений.
# Каждый элемент — это словарь:
# - background: путь к изображению космоса
# - quest: путь к JSON текстового квеста

var adventures = [
	{
		"id": "signal_derelict",
		"title": "Сигнал из пустоты",
		"background": "res://assets/backgrounds/space/cosmo-structure 5.jpg",
		"quest": "res://data/quests/quest_signal.json"
	},
	{
		"id": "derelict_station",
		"title": "Планетарный шпиль",
		"background": "res://assets/backgrounds/space/cosmos 8.jpg",
		"quest": "res://data/quests/quest_derelict.json"
	},
	{
		"id": "ice_ring_relay",
		"title": "Голос подо льдом",
		"background": "res://assets/backgrounds/space/cosmo-structure 4.jpg",
		"quest": "res://data/quests/quest_ice_ring_relay.json"
	},
	{
		"id": "smugglers_route",
		"title": "Тестовое название",
		"background": "res://assets/backgrounds/space/cosmos 21.jpg",
		"quest": "res://data/quests/quest_smugglers.json"
	},
	{
		"id": "Space_station_qh",
		"title": "Станция Тихий Порог",
		"background": "res://assets/backgrounds/space/cosmo-structure 9.jpg",
		"quest": "res://data/quests/space_st_qh.json"
	},
	{
		"id": "accretion_edge",
		"title": "Край аккреции",
		"background":"res://assets/backgrounds/quest backgrounds/quest_accretion_edge.jpg" ,
		"quest": "res://data/quests/quest_accretion_edge.json"
	},
	{
		"id": "photon_reef",
		"title": "Фотонный риф",
		"background":"res://assets/backgrounds/quest backgrounds/quest_photon_reef.jpg",
		"quest": "res://data/quests/quest_photon_reef.json"
	}
]

func get_current_adventure_id() -> String:
	var adventure = get_current_adventure()
	if adventure.is_empty():
		return ""
	
	return adventure.get("id", "")

# Индекс текущего приключения в массиве adventures
var current_adventure_index: int = 0


func get_current_adventure() -> Dictionary:
	# Возвращает словарь текущего приключения.
	# Если список пустой, возвращаем пустой словарь, чтобы не словить ошибку.
	if adventures.is_empty():
		return {}
	
	return adventures[current_adventure_index]


func get_current_background_path() -> String:
	# Возвращает путь к текущему фону космоса.
	var adventure = get_current_adventure()
	if adventure.is_empty():
		return ""
	
	return adventure.get("background", "")


func get_current_quest_path() -> String:
	# Возвращает путь к текущему JSON-квесту.
	var adventure = get_current_adventure()
	if adventure.is_empty():
		return ""
	
	return adventure.get("quest", "")


func go_to_next_adventure() -> void:
	# Переключаем индекс на следующее приключение.
	# Если дошли до конца массива — начинаем снова с нуля.
	if adventures.is_empty():
		return
	
	current_adventure_index += 1
	
	if current_adventure_index >= adventures.size():
		current_adventure_index = 0


func debug_print_current_adventure() -> void:
	# Небольшой служебный вывод для отладки.
	# Удобно во время разработки.
	print("Текущий индекс приключения: ", current_adventure_index)
	print("Текущий фон: ", get_current_background_path())
	print("Текущий квест: ", get_current_quest_path())
