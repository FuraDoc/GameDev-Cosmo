extends Node

# =========================================================
# SAVE MANAGER
# =========================================================
# Глобальный менеджер сохранений.
#
# Отвечает за:
# - чтение и запись 3 слотов
# - создание нового сохранения
# - проверку, есть ли сохранения
# - выдачу краткой информации по слотам для UI
#
# Пока делаем простую и надежную схему:
# один слот = один json-файл в user://
# =========================================================

# Максимальное количество слотов сохранения, которое показывает экран новой/продолженной игры.
const MAX_SLOTS := 3

# Папка сохранений внутри user://, Godot сам хранит ее в пользовательских данных проекта.
const SAVE_DIR := "user://saves/"


# _ready — «готово»: при старте автозагрузки убеждается, что папка сохранений создана.
func _ready():
	_ensure_save_dir()


# _ensure_save_dir — «убедиться, что папка сохранений есть»: создает каталог, если его нет.
func _ensure_save_dir() -> void:
	if not DirAccess.dir_exists_absolute(SAVE_DIR):
		DirAccess.make_dir_recursive_absolute(SAVE_DIR)


# get_slot_path — «получить путь слота»: собирает полный путь json-файла по номеру слота.
func get_slot_path(slot_id: int) -> String:
	return SAVE_DIR + "slot_%d.json" % slot_id


# slot_exists — «слот существует»: проверяет, есть ли файл сохранения для указанного слота.
func slot_exists(slot_id: int) -> bool:
	return FileAccess.file_exists(get_slot_path(slot_id))


# has_any_save — «есть любое сохранение»: ищет хотя бы один заполненный слот.
func has_any_save() -> bool:
	for slot_id in range(1, MAX_SLOTS + 1):
		if slot_exists(slot_id):
			return true
	return false


# get_all_slots_summary — «получить сводку всех слотов»: дает UI данные по каждому слоту.
func get_all_slots_summary() -> Array[Dictionary]:
	# Даже если слот пустой, возвращаем запись о нем, чтобы UI всегда показывал все 3 слота.
	var result: Array[Dictionary] = []
	
	for slot_id in range(1, MAX_SLOTS + 1):
		if slot_exists(slot_id):
			var data = load_slot(slot_id)
			result.append({
				"slot_id": slot_id,
				"exists": true,
				"pilot_name": data.get("pilot_name", "Без имени"),
				"current_adventure_id": data.get("current_adventure_id", ""),
				"completed_quests_count": data.get("completed_quests_count", 0),
				"play_time_seconds": data.get("play_time_seconds", 0)
			})
		else:
			result.append({
				"slot_id": slot_id,
				"exists": false,
				"pilot_name": "",
				"current_adventure_id": "",
				"completed_quests_count": 0,
				"play_time_seconds": 0
			})
	
	return result


# create_new_game — «создать новую игру»: собирает стартовые данные и записывает слот.
func create_new_game(slot_id: int, pilot_name: String) -> Dictionary:
	# Пока стартуем с первого приключения и выдаем стандартный костюм как базовый предмет.
	var save_data := {
		"slot_id": slot_id,
		"pilot_name": pilot_name.strip_edges(),
		"current_adventure_id": "signal_derelict",
		"completed_quests_count": 0,
		"play_time_seconds": 0,
		"found_items": ["standard_suit"],
		"active_suit_id": "standard_suit",
		"last_saved_at": Time.get_datetime_string_from_system()
	}
	
	save_slot(slot_id, save_data)
	return save_data


# save_slot — «сохранить слот»: записывает словарь сохранения в json-файл.
func save_slot(slot_id: int, data: Dictionary) -> void:
	var path = get_slot_path(slot_id)
	var file = FileAccess.open(path, FileAccess.WRITE)
	
	if file == null:
		push_error("SaveManager: не удалось открыть файл для записи: " + path)
		return
	
	var json_text = JSON.stringify(data, "\t")
	file.store_string(json_text)


# load_slot — «загрузить слот»: читает json-файл и возвращает словарь данных сохранения.
func load_slot(slot_id: int) -> Dictionary:
	var path = get_slot_path(slot_id)
	
	if not FileAccess.file_exists(path):
		return {}
	
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("SaveManager: не удалось открыть файл сохранения: " + path)
		return {}
	
	var content = file.get_as_text()
	var json = JSON.new()
	var result = json.parse(content)
	
	if result != OK:
		push_error("SaveManager: ошибка чтения json сохранения: " + path)
		return {}
	
	return json.data


# delete_slot — «удалить слот»: стирает файл сохранения, если он существует.
func delete_slot(slot_id: int) -> void:
	var path = get_slot_path(slot_id)
	
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
