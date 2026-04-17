extends Node

# PlayerState — это глобальное состояние игрока.

signal item_added(item_id: String)
signal interior_changed
signal hardware_changed
signal pets_changed
signal modules_changed

var found_items: Dictionary = {}

var dev_give_all_items := true

var found_interior_items: Array[String] = []
var installed_interior_items: Array[String] = []

var found_hardware_items: Array[String] = []
var installed_hardware_items: Array[String] = []

var found_pet_ids: Array[String] = []
var active_pet_id: String = ""

var found_module_ids: Array[String] = []

var active_modules := {
	"sleep": "",
	"workzone": "",
	"front": ""
}


func has_found_interior_item(item_id: String) -> bool:
	return item_id in found_interior_items


func is_interior_item_installed(item_id: String) -> bool:
	return item_id in installed_interior_items


func add_found_interior_item(item_id: String) -> void:
	if item_id not in found_interior_items:
		found_interior_items.append(item_id)
		interior_changed.emit()


func install_interior_item(item_id: String) -> void:
	if item_id not in found_interior_items:
		push_warning("Нельзя установить ненайденный интерьерный предмет: " + item_id)
		return
	
	if item_id not in installed_interior_items:
		installed_interior_items.append(item_id)
		interior_changed.emit()


func uninstall_interior_item(item_id: String) -> void:
	if item_id in installed_interior_items:
		installed_interior_items.erase(item_id)
		interior_changed.emit()


func has_found_hardware_item(item_id: String) -> bool:
	return item_id in found_hardware_items


func is_hardware_item_installed(item_id: String) -> bool:
	return item_id in installed_hardware_items


func add_found_hardware_item(item_id: String) -> void:
	if item_id not in found_hardware_items:
		found_hardware_items.append(item_id)
		hardware_changed.emit()


func install_hardware_item(item_id: String) -> void:
	if item_id not in found_hardware_items:
		push_warning("Нельзя установить ненайденный hardware-предмет: " + item_id)
		return
	
	if item_id not in installed_hardware_items:
		installed_hardware_items.append(item_id)
		hardware_changed.emit()


func uninstall_hardware_item(item_id: String) -> void:
	if item_id in installed_hardware_items:
		installed_hardware_items.erase(item_id)
		hardware_changed.emit()


func has_found_pet(pet_id: String) -> bool:
	return pet_id in found_pet_ids


func add_found_pet(pet_id: String) -> void:
	if pet_id not in found_pet_ids:
		found_pet_ids.append(pet_id)
		pets_changed.emit()


func is_pet_active(pet_id: String) -> bool:
	return active_pet_id == pet_id


func summon_pet(pet_id: String) -> void:
	if pet_id not in found_pet_ids:
		push_warning("Нельзя призвать ненайденного питомца: " + pet_id)
		return

	if active_pet_id == pet_id:
		return

	active_pet_id = pet_id
	pets_changed.emit()


func return_active_pet() -> void:
	if active_pet_id.is_empty():
		return

	active_pet_id = ""
	pets_changed.emit()


# =========================
# MODULES
# =========================

func has_found_module(module_id: String) -> bool:
	return module_id in found_module_ids


func add_found_module(module_id: String) -> void:
	if module_id not in found_module_ids:
		found_module_ids.append(module_id)
		modules_changed.emit()


func get_active_module_for_zone(zone_id: String) -> String:
	return active_modules.get(zone_id, "")


func is_module_installed(module_id: String, zone_id: String) -> bool:
	return active_modules.get(zone_id, "") == module_id


func install_module(module_id: String, zone_id: String) -> void:
	if module_id not in found_module_ids:
		push_warning("Нельзя установить ненайденный модуль: " + module_id)
		return

	if not active_modules.has(zone_id):
		push_warning("Неизвестная зона модуля: " + zone_id)
		return

	if active_modules[zone_id] == module_id:
		return

	active_modules[zone_id] = module_id
	modules_changed.emit()


func uninstall_module(zone_id: String) -> void:
	if not active_modules.has(zone_id):
		push_warning("Неизвестная зона модуля: " + zone_id)
		return

	if String(active_modules[zone_id]).is_empty():
		return

	active_modules[zone_id] = ""
	modules_changed.emit()


func clear_module(module_id: String, zone_id: String) -> void:
	if not active_modules.has(zone_id):
		return

	if active_modules[zone_id] == module_id:
		active_modules[zone_id] = ""
		modules_changed.emit()


func _ready():
	if dev_give_all_items:
		debug_give_all_items()
		debug_give_all_interior_items()
		debug_give_all_modules()
		debug_give_all_pets()


func has_item(item_id: String) -> bool:
	return found_items.get(item_id, false)


func add_item(item_id: String) -> void:
	if item_id.is_empty():
		push_error("PlayerState.add_item(): пустой item_id")
		return
	
	if not ItemDatabase.has_item_definition(item_id):
		push_error("PlayerState.add_item(): неизвестный item_id: " + item_id)
		return
	
	if has_item(item_id):
		return
	
	found_items[item_id] = true
	item_added.emit(item_id)
	print("PlayerState: найден предмет -> ", item_id)


func remove_item(item_id: String) -> void:
	if found_items.has(item_id):
		found_items.erase(item_id)


func get_found_item_ids() -> Array[String]:
	var result: Array[String] = []
	for item_id in found_items.keys():
		result.append(item_id)
	return result


func get_found_items_data() -> Array[ItemData]:
	var result: Array[ItemData] = []
	
	for item_id in found_items.keys():
		var item = ItemDatabase.get_item(item_id)
		if item != null:
			result.append(item)
	
	return result


func debug_give_all_items() -> void:
	add_item("rescue_suit")
	add_item("ar_visor")
	add_item("wave_drone")
	add_item("analytic_resonator")
	add_item("smart_metal_container")


func debug_give_all_interior_items() -> void:
	add_found_interior_item("small_plant")
	add_found_interior_item("sleep_zone")
	add_found_interior_item("stool")


func debug_give_all_modules() -> void:
	for i in range(1, 9):
		add_found_module("module_sleep_%03d" % i)

	for i in range(1, 9):
		add_found_module("module_workzone_%03d" % i)

	for i in range(1, 9):
		add_found_module("module_front_%03d" % i)


func debug_give_all_pets() -> void:
	add_found_pet("alien_jelly")
	add_found_pet("marta_cat")
	add_found_pet("robo_crab")
