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

const MAX_SLOTS := 3

# Папка сохранений внутри user://
const SAVE_DIR := "user://saves/"


func _ready():
	# При старте убеждаемся, что папка сохранений существует.
	_ensure_save_dir()


func _ensure_save_dir() -> void:
	if not DirAccess.dir_exists_absolute(SAVE_DIR):
		DirAccess.make_dir_recursive_absolute(SAVE_DIR)


func get_slot_path(slot_id: int) -> String:
	return SAVE_DIR + "slot_%d.json" % slot_id


func slot_exists(slot_id: int) -> bool:
	return FileAccess.file_exists(get_slot_path(slot_id))


func has_any_save() -> bool:
	for slot_id in range(1, MAX_SLOTS + 1):
		if slot_exists(slot_id):
			return true
	return false


func get_all_slots_summary() -> Array[Dictionary]:
	# Возвращает краткую информацию по всем слотам.
	# Даже если слот пустой, возвращаем запись о нем,
	# чтобы UI всегда мог показать все 3 слота.
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


func create_new_game(slot_id: int, pilot_name: String) -> Dictionary:
	# Создаем новое сохранение "с нуля".
	# Пока стартуем с первого приключения.
	var save_data := {
		"slot_id": slot_id,
		"pilot_name": pilot_name.strip_edges(),
		"current_adventure_id": "signal_derelict",
		"completed_quests_count": 0,
		"play_time_seconds": 0,
		"found_items": [],
		"last_saved_at": Time.get_datetime_string_from_system()
	}
	
	save_slot(slot_id, save_data)
	return save_data


func save_slot(slot_id: int, data: Dictionary) -> void:
	var path = get_slot_path(slot_id)
	var file = FileAccess.open(path, FileAccess.WRITE)
	
	if file == null:
		push_error("SaveManager: не удалось открыть файл для записи: " + path)
		return
	
	var json_text = JSON.stringify(data, "\t")
	file.store_string(json_text)


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


func delete_slot(slot_id: int) -> void:
	var path = get_slot_path(slot_id)
	
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
