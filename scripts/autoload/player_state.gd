extends Node

signal item_added(item_id: String)
signal suit_changed(active_suit_id: String)
signal interior_changed
signal hardware_changed
signal pets_changed
signal modules_changed

const DEFAULT_SUIT_ID := "standard_suit"
const DEFAULT_ACTIVE_MODULES := {
	"sleep": "module_sleep_001",
	"workzone": "module_workzone_001",
	"front": "module_front_001",
	"panel": "module_panel_001"
}

var found_items: Dictionary = {}
var active_suit_id: String = ""

var found_interior_items: Array[String] = []
var installed_interior_by_zone := {
	1: "",
	2: "",
	3: "",
	4: "",
	5: "",
	6: "",
	7: "",
	8: ""
}

var found_hardware_items: Array[String] = []
var installed_hardware_items: Array[String] = []

var found_pet_ids: Array[String] = []
var active_pet_id: String = ""

var found_module_ids: Array[String] = []
var active_modules := {
	"sleep": "",
	"workzone": "",
	"front": "",
	"panel": ""
}

var dev_give_all_items := true


func _ready() -> void:
	ensure_starting_equipment()
	apply_default_modules(false)

	if dev_give_all_items:
		debug_give_all_items()
		debug_give_all_interior_items()
		debug_give_all_modules()
		debug_give_all_pets()
		apply_default_modules()


func ensure_starting_equipment() -> void:
	if not has_item(DEFAULT_SUIT_ID):
		add_item(DEFAULT_SUIT_ID)

	if active_suit_id.is_empty():
		active_suit_id = DEFAULT_SUIT_ID


func has_item(item_id: String) -> bool:
	return found_items.get(item_id, false)


func add_item(item_id: String) -> void:
	if item_id.is_empty():
		push_error("PlayerState.add_item(): empty item_id")
		return

	if not ItemDatabase.has_item_definition(item_id):
		push_error("PlayerState.add_item(): unknown item_id: '%s'" % item_id)
		return

	if has_item(item_id):
		return

	found_items[item_id] = true
	item_added.emit(item_id)

	if active_suit_id.is_empty() and _is_suit_item(item_id):
		equip_suit(item_id)


func remove_item(item_id: String) -> void:
	if not found_items.has(item_id):
		return

	found_items.erase(item_id)

	if active_suit_id == item_id:
		active_suit_id = ""
		ensure_starting_equipment()
		suit_changed.emit(active_suit_id)


func get_found_item_ids() -> Array[String]:
	return Array(found_items.keys(), TYPE_STRING, "", null)


func get_found_items_data() -> Array[ItemData]:
	var result: Array[ItemData] = []
	for item_id in found_items.keys():
		var item = ItemDatabase.get_item(item_id)
		if item != null:
			result.append(item)
	return result


func has_active_suit(suit_id: String) -> bool:
	return active_suit_id == suit_id


func get_active_suit_id() -> String:
	return active_suit_id


func equip_suit(suit_id: String) -> void:
	if suit_id.is_empty():
		push_warning("PlayerState.equip_suit(): empty suit_id")
		return

	if not has_item(suit_id):
		push_warning("PlayerState.equip_suit(): suit not found: '%s'" % suit_id)
		return

	if not _is_suit_item(suit_id):
		push_warning("PlayerState.equip_suit(): item is not a suit: '%s'" % suit_id)
		return

	if active_suit_id == suit_id:
		return

	active_suit_id = suit_id
	suit_changed.emit(active_suit_id)


func _is_suit_item(item_id: String) -> bool:
	var item_data := ItemDatabase.get_item(item_id)
	return item_data != null and item_data.is_suit


func has_found_interior_item(item_id: String) -> bool:
	return item_id in found_interior_items


func is_interior_item_installed(item_id: String) -> bool:
	return get_interior_item_zone(item_id) != -1


func get_interior_item_zone(item_id: String) -> int:
	for zone_id in range(1, 9):
		if String(installed_interior_by_zone[zone_id]) == item_id:
			return zone_id
	return -1


func get_interior_item_for_zone(zone_id: int) -> String:
	return String(installed_interior_by_zone.get(zone_id, ""))


func get_installed_interior_items() -> Array[String]:
	var result: Array[String] = []
	for zone_id in range(1, 9):
		var item_id := get_interior_item_for_zone(zone_id)
		if not item_id.is_empty():
			result.append(item_id)
	return result


func get_installed_interior_zone_map() -> Dictionary:
	return installed_interior_by_zone.duplicate(true)


func is_interior_zone_occupied(zone_id: int) -> bool:
	return not get_interior_item_for_zone(zone_id).is_empty()


func get_first_free_interior_zone() -> int:
	for zone_id in range(1, 9):
		if get_interior_item_for_zone(zone_id).is_empty():
			return zone_id
	return -1


func add_found_interior_item(item_id: String) -> void:
	if item_id not in found_interior_items:
		found_interior_items.append(item_id)
		interior_changed.emit()


func install_interior_item(item_id: String, zone_id: int = -1) -> void:
	if item_id not in found_interior_items:
		push_warning("Cannot install unknown interior item: '%s'" % item_id)
		return

	var target_zone := zone_id
	if target_zone == -1:
		target_zone = get_first_free_interior_zone()

	if not installed_interior_by_zone.has(target_zone):
		push_warning("Unknown interior zone: '%s'" % target_zone)
		return

	var current_zone := get_interior_item_zone(item_id)
	if current_zone == target_zone:
		return

	if current_zone != -1:
		installed_interior_by_zone[current_zone] = ""

	installed_interior_by_zone[target_zone] = item_id
	interior_changed.emit()


func uninstall_interior_item(item_id: String) -> void:
	var zone_id := get_interior_item_zone(item_id)
	if zone_id != -1:
		installed_interior_by_zone[zone_id] = ""
		interior_changed.emit()


func uninstall_interior_zone(zone_id: int) -> void:
	if not installed_interior_by_zone.has(zone_id):
		return
	if get_interior_item_for_zone(zone_id).is_empty():
		return
	installed_interior_by_zone[zone_id] = ""
	interior_changed.emit()


func set_interior_item_zone(item_id: String, zone_id: int) -> void:
	install_interior_item(item_id, zone_id)


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
		push_warning("Cannot install unknown hardware item: '%s'" % item_id)
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
		push_warning("Cannot summon unknown pet: '%s'" % pet_id)
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
		push_warning("Cannot install unknown module: '%s'" % module_id)
		return
	if not active_modules.has(zone_id):
		push_warning("Unknown module zone: '%s'" % zone_id)
		return
	if active_modules[zone_id] == module_id:
		return
	active_modules[zone_id] = module_id
	modules_changed.emit()


func uninstall_module(zone_id: String) -> void:
	if not active_modules.has(zone_id):
		push_warning("Unknown module zone: '%s'" % zone_id)
		return
	if active_modules[zone_id] == "":
		return
	active_modules[zone_id] = ""
	modules_changed.emit()


func clear_module(module_id: String, zone_id: String) -> void:
	if not active_modules.has(zone_id):
		return
	if active_modules[zone_id] == module_id:
		active_modules[zone_id] = ""
		modules_changed.emit()


func apply_default_modules(emit_signal: bool = true) -> void:
	for zone_id in DEFAULT_ACTIVE_MODULES:
		var module_id: String = DEFAULT_ACTIVE_MODULES[zone_id]
		if module_id not in found_module_ids:
			found_module_ids.append(module_id)

	var changed := false
	for zone_id in DEFAULT_ACTIVE_MODULES:
		var module_id: String = DEFAULT_ACTIVE_MODULES[zone_id]
		if active_modules.get(zone_id, "") != module_id:
			active_modules[zone_id] = module_id
			changed = true

	if changed and emit_signal:
		modules_changed.emit()


func debug_give_all_items() -> void:
	add_item("standard_suit")
	add_item("heavy_rescue_suit")
	add_item("nova_suit")
	add_item("ar_visor")
	add_item("wave_drone")
	add_item("analytic_resonator")
	add_item("smart_metal_container")
	add_item("plasma_cutter")
	add_item("strange_cube")


func debug_give_all_interior_items() -> void:
	for i in range(1, 41):
		add_found_interior_item("interior_plant_%03d" % i)


func debug_give_all_modules() -> void:
	for prefix in ["module_sleep", "module_workzone", "module_front", "module_panel"]:
		for i in range(1, 11):
			add_found_module("%s_%03d" % [prefix, i])


func debug_give_all_pets() -> void:
	add_found_pet("alien_jelly")
	add_found_pet("marta_cat")
	add_found_pet("robo_crab")
