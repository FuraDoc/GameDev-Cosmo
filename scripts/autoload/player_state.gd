extends Node

# Сигнал получения предмета снаряжения: UI может обновить список найденных вещей.
signal item_added(item_id: String)

# Сигнал смены активного костюма: нужен панелям и квестовым проверкам required_suit.
signal suit_changed(active_suit_id: String)

# Сигнал изменения интерьера: обновляет Cargo Interior и слой интерьера в корабле.
signal interior_changed

# Сигнал выбора интерьера для debug в кокпите: ShipViewController подхватывает item_id.
signal debug_interior_selection_changed(item_id: String)

# Сигнал запроса установки интерьера: ShipViewController берет зону из interior_visual_data.
signal debug_interior_install_requested(item_id: String)

# Сигнал изменения оборудования: обновляет Cargo Hardware и связанные панели.
signal hardware_changed

# Сигнал изменения питомцев: обновляет Cargo Pets и активного питомца в корабле.
signal pets_changed

# Сигнал изменения модулей корабля: обновляет установленные модули на слоях кокпита.
signal modules_changed

# ID стандартного костюма: стартовый и запасной костюм игрока.
const DEFAULT_SUIT_ID := "standard_suit"

# Стартовые активные модули по зонам корабля: применяются при создании/в dev-режиме.
const DEFAULT_ACTIVE_MODULES := {
	"sleep": "module_sleep_001",
	"workzone": "module_workzone_001",
	"front": "module_front_001",
	"panel": "module_panel_001"
}

# Найденные предметы снаряжения: словарь item_id -> true для быстрых проверок.
var found_items: Dictionary = {}

# Активный костюм: один item_id, который сейчас используется игроком.
var active_suit_id: String = ""

# Найденные предметы интерьера: список item_id, доступных в Cargo Interior.
var found_interior_items: Array[String] = []

# Активный предмет интерьера для debug-позиционирования в кокпите.
var debug_selected_interior_item_id: String = ""

# Установленный интерьер по зонам: ключ зоны -> item_id, пустая строка означает свободно.
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

# Найденные предметы оборудования старой системы: оставлено для совместимости.
var found_hardware_items: Array[String] = []

# Установленное оборудование старой системы: список активных item_id.
var installed_hardware_items: Array[String] = []

# Найденные питомцы: список pet_id, доступных в Cargo Pets.
var found_pet_ids: Array[String] = []

# Активный питомец: один pet_id, который сейчас призван.
var active_pet_id: String = ""

# Найденные модули корабля: список module_id, доступных в Cargo Hardware.
var found_module_ids: Array[String] = []

# Активные модули по зонам: зона -> module_id, пустая строка означает пустой слот.
var active_modules := {
	"sleep": "",
	"workzone": "",
	"front": "",
	"panel": ""
}

# Dev-режим выдачи всего: временно нужен для отладки Cargo Bay без прохождения.
var dev_give_all_items := true


# _ready — «готово»: выдает стартовое снаряжение и dev-набор, затем применяет модули.
func _ready() -> void:
	ensure_starting_equipment()
	apply_default_modules(false)

	if dev_give_all_items:
		debug_give_all_items()
		debug_give_all_interior_items()
		debug_give_all_modules()
		debug_give_all_pets()
		apply_default_modules()


# ensure_starting_equipment — «убедиться в стартовом снаряжении»: добавляет базовый костюм.
func ensure_starting_equipment() -> void:
	if not has_item(DEFAULT_SUIT_ID):
		add_item(DEFAULT_SUIT_ID)

	if active_suit_id.is_empty():
		active_suit_id = DEFAULT_SUIT_ID


# has_item — «есть предмет»: проверяет, найден ли предмет снаряжения по item_id.
func has_item(item_id: String) -> bool:
	return found_items.get(item_id, false)


# add_item — «добавить предмет»: валидирует item_id, добавляет его и активирует первый костюм.
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


# remove_item — «удалить предмет»: убирает item_id и возвращает стандартный костюм при необходимости.
func remove_item(item_id: String) -> void:
	if not found_items.has(item_id):
		return

	found_items.erase(item_id)

	if active_suit_id == item_id:
		active_suit_id = ""
		ensure_starting_equipment()
		suit_changed.emit(active_suit_id)


# get_found_item_ids — «получить ID найденных предметов»: возвращает типизированный список ключей.
func get_found_item_ids() -> Array[String]:
	return Array(found_items.keys(), TYPE_STRING, "", null)


# get_found_items_data — «получить данные найденных предметов»: превращает item_id в ItemData.
func get_found_items_data() -> Array[ItemData]:
	var result: Array[ItemData] = []
	for item_id in found_items.keys():
		var item = ItemDatabase.get_item(item_id)
		if item != null:
			result.append(item)
	return result


# has_active_suit — «есть активный костюм»: проверяет, совпадает ли текущий костюм с suit_id.
func has_active_suit(suit_id: String) -> bool:
	return active_suit_id == suit_id


# get_active_suit_id — «получить ID активного костюма»: нужен квестам и UI.
func get_active_suit_id() -> String:
	return active_suit_id


# equip_suit — «надеть костюм»: делает найденный item_id единственным активным костюмом.
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


# _is_suit_item — «является предмет костюмом»: читает ItemData и проверяет флаг is_suit.
func _is_suit_item(item_id: String) -> bool:
	var item_data := ItemDatabase.get_item(item_id)
	return item_data != null and item_data.is_suit


# has_found_interior_item — «найден предмет интерьера»: проверяет наличие item_id в списке.
func has_found_interior_item(item_id: String) -> bool:
	return item_id in found_interior_items


# is_interior_item_installed — «предмет интерьера установлен»: ищет его в любой зоне.
func is_interior_item_installed(item_id: String) -> bool:
	return get_interior_item_zone(item_id) != -1


# get_interior_item_zone — «получить зону предмета интерьера»: возвращает номер зоны или -1.
func get_interior_item_zone(item_id: String) -> int:
	for zone_id in range(1, 9):
		if String(installed_interior_by_zone[zone_id]) == item_id:
			return zone_id
	return -1


# get_interior_item_for_zone — «получить предмет интерьера для зоны»: читает item_id по номеру.
func get_interior_item_for_zone(zone_id: int) -> String:
	return String(installed_interior_by_zone.get(zone_id, ""))


# get_installed_interior_items — «получить установленные предметы интерьера»: собирает непустые зоны.
func get_installed_interior_items() -> Array[String]:
	var result: Array[String] = []
	for zone_id in range(1, 9):
		var item_id := get_interior_item_for_zone(zone_id)
		if not item_id.is_empty():
			result.append(item_id)
	return result


# get_installed_interior_zone_map — «получить карту зон интерьера»: возвращает копию словаря.
func get_installed_interior_zone_map() -> Dictionary:
	return installed_interior_by_zone.duplicate(true)


# is_interior_zone_occupied — «зона интерьера занята»: проверяет, есть ли item_id в зоне.
func is_interior_zone_occupied(zone_id: int) -> bool:
	return not get_interior_item_for_zone(zone_id).is_empty()


# get_first_free_interior_zone — «получить первую свободную зону интерьера»: возвращает 1-8 или -1.
func get_first_free_interior_zone() -> int:
	for zone_id in range(1, 9):
		if get_interior_item_for_zone(zone_id).is_empty():
			return zone_id
	return -1


# add_found_interior_item — «добавить найденный интерьер»: кладет item_id в список и обновляет UI.
func add_found_interior_item(item_id: String) -> void:
	if item_id not in found_interior_items:
		found_interior_items.append(item_id)
		interior_changed.emit()


# install_interior_item — «установить предмет интерьера»: ставит item_id в зону или первую свободную.
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


# uninstall_interior_item — «снять предмет интерьера»: очищает зону, где сейчас стоит item_id.
func uninstall_interior_item(item_id: String) -> void:
	var zone_id := get_interior_item_zone(item_id)
	if zone_id != -1:
		installed_interior_by_zone[zone_id] = ""
		interior_changed.emit()


# uninstall_interior_zone — «очистить зону интерьера»: снимает предмет из конкретной зоны.
func uninstall_interior_zone(zone_id: int) -> void:
	if not installed_interior_by_zone.has(zone_id):
		return
	if get_interior_item_for_zone(zone_id).is_empty():
		return
	installed_interior_by_zone[zone_id] = ""
	interior_changed.emit()


# set_interior_item_zone — «задать зону предмета интерьера»: короткий alias для установки.
func set_interior_item_zone(item_id: String, zone_id: int) -> void:
	install_interior_item(item_id, zone_id)


# set_debug_selected_interior_item — «задать debug-интерьер»: выбирает предмет для кокпита.
func set_debug_selected_interior_item(item_id: String) -> void:
	if item_id == debug_selected_interior_item_id:
		return

	debug_selected_interior_item_id = item_id
	debug_interior_selection_changed.emit(debug_selected_interior_item_id)


# get_debug_selected_interior_item — «получить debug-интерьер»: возвращает активный item_id.
func get_debug_selected_interior_item() -> String:
	return debug_selected_interior_item_id


# request_debug_interior_install — «запросить установку debug-интерьера»: просит корабль поставить.
func request_debug_interior_install(item_id: String) -> void:
	if item_id.is_empty():
		return

	debug_interior_install_requested.emit(item_id)


# has_found_hardware_item — «найден предмет оборудования»: проверка старого списка оборудования.
func has_found_hardware_item(item_id: String) -> bool:
	return item_id in found_hardware_items


# is_hardware_item_installed — «оборудование установлено»: проверка старого installed-списка.
func is_hardware_item_installed(item_id: String) -> bool:
	return item_id in installed_hardware_items


# add_found_hardware_item — «добавить найденное оборудование»: сохраняет item_id и обновляет UI.
func add_found_hardware_item(item_id: String) -> void:
	if item_id not in found_hardware_items:
		found_hardware_items.append(item_id)
		hardware_changed.emit()


# install_hardware_item — «установить оборудование»: добавляет найденный item_id в installed-список.
func install_hardware_item(item_id: String) -> void:
	if item_id not in found_hardware_items:
		push_warning("Cannot install unknown hardware item: '%s'" % item_id)
		return
	if item_id not in installed_hardware_items:
		installed_hardware_items.append(item_id)
		hardware_changed.emit()


# uninstall_hardware_item — «снять оборудование»: удаляет item_id из installed-списка.
func uninstall_hardware_item(item_id: String) -> void:
	if item_id in installed_hardware_items:
		installed_hardware_items.erase(item_id)
		hardware_changed.emit()


# has_found_pet — «найден питомец»: проверяет наличие pet_id в списке питомцев.
func has_found_pet(pet_id: String) -> bool:
	return pet_id in found_pet_ids


# add_found_pet — «добавить найденного питомца»: сохраняет pet_id и обновляет панель питомцев.
func add_found_pet(pet_id: String) -> void:
	if pet_id not in found_pet_ids:
		found_pet_ids.append(pet_id)
		pets_changed.emit()


# is_pet_active — «питомец активен»: проверяет, является ли pet_id призванным питомцем.
func is_pet_active(pet_id: String) -> bool:
	return active_pet_id == pet_id


# summon_pet — «призвать питомца»: делает найденного питомца единственным активным.
func summon_pet(pet_id: String) -> void:
	if pet_id not in found_pet_ids:
		push_warning("Cannot summon unknown pet: '%s'" % pet_id)
		return
	if active_pet_id == pet_id:
		return
	active_pet_id = pet_id
	pets_changed.emit()


# return_active_pet — «вернуть активного питомца»: снимает текущего питомца с корабля.
func return_active_pet() -> void:
	if active_pet_id.is_empty():
		return
	active_pet_id = ""
	pets_changed.emit()


# has_found_module — «найден модуль»: проверяет наличие module_id в списке модулей.
func has_found_module(module_id: String) -> bool:
	return module_id in found_module_ids


# add_found_module — «добавить найденный модуль»: сохраняет module_id и обновляет оборудование.
func add_found_module(module_id: String) -> void:
	if module_id not in found_module_ids:
		found_module_ids.append(module_id)
		modules_changed.emit()


# get_active_module_for_zone — «получить активный модуль зоны»: возвращает module_id по зоне.
func get_active_module_for_zone(zone_id: String) -> String:
	return active_modules.get(zone_id, "")


# is_module_installed — «модуль установлен»: проверяет, стоит ли module_id в указанной зоне.
func is_module_installed(module_id: String, zone_id: String) -> bool:
	return active_modules.get(zone_id, "") == module_id


# install_module — «установить модуль»: ставит найденный module_id в одну из зон корабля.
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


# uninstall_module — «снять модуль»: очищает активный модуль в указанной зоне.
func uninstall_module(zone_id: String) -> void:
	if not active_modules.has(zone_id):
		push_warning("Unknown module zone: '%s'" % zone_id)
		return
	if active_modules[zone_id] == "":
		return
	active_modules[zone_id] = ""
	modules_changed.emit()


# clear_module — «очистить модуль»: снимает module_id только если он стоит в указанной зоне.
func clear_module(module_id: String, zone_id: String) -> void:
	if not active_modules.has(zone_id):
		return
	if active_modules[zone_id] == module_id:
		active_modules[zone_id] = ""
		modules_changed.emit()


# apply_default_modules — «применить модули по умолчанию»: выдает и ставит стартовые модули.
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


# debug_give_all_items — «debug-выдать все предметы»: добавляет все предметы снаряжения.
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


# debug_give_all_interior_items — «debug-выдать весь интерьер»: добавляет 40 предметов интерьера.
func debug_give_all_interior_items() -> void:
	for i in range(1, 41):
		add_found_interior_item("interior_plant_%03d" % i)


# debug_give_all_modules — «debug-выдать все модули»: добавляет 4 зоны по 10 модулей.
func debug_give_all_modules() -> void:
	for prefix in ["module_sleep", "module_workzone", "module_front", "module_panel"]:
		for i in range(1, 11):
			add_found_module("%s_%03d" % [prefix, i])


# debug_give_all_pets — «debug-выдать всех питомцев»: добавляет текущий набор питомцев.
func debug_give_all_pets() -> void:
	add_found_pet("alien_jelly")
	add_found_pet("marta_cat")
	add_found_pet("robo_crab")
