extends Node

# Этот контроллер отвечает только за данные приключений.
# Он НЕ занимается UI, НЕ управляет слоями и НЕ открывает окна.
# Его задача — хранить список приключений и отдавать текущее активное приключение.


# Список приключений: каждый словарь хранит id, title, background и quest для локации.
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

# get_current_adventure_id — «получить ID текущего приключения»: читает id активной локации.
func get_current_adventure_id() -> String:
	var adventure = get_current_adventure()
	if adventure.is_empty():
		return ""
	
	return adventure.get("id", "")

# Индекс текущего приключения в массиве adventures: меняется при переходе к следующей локации.
var current_adventure_index: int = 0


# get_current_adventure — «получить текущее приключение»: возвращает словарь активной локации.
func get_current_adventure() -> Dictionary:
	if adventures.is_empty():
		return {}
	
	return adventures[current_adventure_index]


# get_current_background_path — «получить путь текущего фона»: отдает картинку космоса.
func get_current_background_path() -> String:
	var adventure = get_current_adventure()
	if adventure.is_empty():
		return ""
	
	return adventure.get("background", "")


# get_current_quest_path — «получить путь текущего квеста»: отдает путь к JSON квеста.
func get_current_quest_path() -> String:
	var adventure = get_current_adventure()
	if adventure.is_empty():
		return ""
	
	return adventure.get("quest", "")


# go_to_next_adventure — «перейти к следующему приключению»: циклически меняет активный индекс.
func go_to_next_adventure() -> void:
	if adventures.is_empty():
		return
	
	current_adventure_index += 1
	
	if current_adventure_index >= adventures.size():
		current_adventure_index = 0


# debug_print_current_adventure — «debug-печать текущего приключения»: выводит индекс, фон и квест.
func debug_print_current_adventure() -> void:
	print("Текущий индекс приключения: ", current_adventure_index)
	print("Текущий фон: ", get_current_background_path())
	print("Текущий квест: ", get_current_quest_path())
