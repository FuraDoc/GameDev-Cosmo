class_name ShipDebugPositioningController
extends RefCounted

# Включатель debug-позиционирования: false полностью отключает обработку клавиш.
var enabled := true

# Выбранный слой для ручной настройки: корабль, модуль, питомец, панель или Cargo Bay.
var selected_layer := "interior.ship" # "interior.ship" / "module" / "pet" / "panel" / "*.cargo"

# Выбранный item_id: именно этот визуальный объект двигается стрелками и масштабируется.
var selected_item_id := "interior_plant_001"

# Выбранная зона питомца: индекс варианта позиции/текстуры внутри pet_visual_data.
var selected_pet_zone := 0

# Обычный шаг движения в нормализованных координатах 0..1.
var move_step := 0.01

# Тонкий шаг движения при зажатом Shift.
var move_step_fine := 0.001

# Обычный множитель размера/масштаба при нажатии [ или ].
var scale_step := 1.05

# Тонкий множитель размера/масштаба при зажатом Shift.
var scale_step_fine := 1.01

# Минимальный ratio для старых ship-элементов, чтобы они не схлопнулись в ноль.
var min_ratio := 0.01

# Максимальный ratio для старых ship-элементов, чтобы размер не улетел за разумный предел.
var max_ratio := 1.0

# Минимальный size_ratio для Cargo-элементов, которые задаются шириной и высотой.
var min_size_ratio := 0.01

# Максимальный size_ratio для Cargo-элементов, которые задаются шириной и высотой.
var max_size_ratio := 1.0


# handle_input — «обработать ввод»: распределяет клавиши по выбранному debug-слою корабля.
func handle_input(
	event: InputEventKey,
	module_layer_controller,
	pet_layer_controller,
	interior_visual_data: Dictionary,
	panel_visual_data: Dictionary,
	hardware_layer: Control,
	pet_layer: Control,
	cockpit_layer: Control,
	cockpit_texture: Texture2D,
	clear_layer_callable: Callable,
	refresh_interior_items_callable: Callable,
	update_interior_layer_callable: Callable,
	update_panel_layer_callable: Callable
) -> void:
	if not enabled:
		return

	if selected_layer == "pet":
		_handle_pet_input(
			event,
			pet_layer_controller,
			pet_layer,
			cockpit_layer,
			cockpit_texture,
			clear_layer_callable
		)
		return

	if selected_layer == "module":
		_handle_module_input(
			event,
			module_layer_controller,
			hardware_layer,
			cockpit_layer,
			cockpit_texture
		)
		return

	if selected_layer == "interior" or selected_layer == "interior.ship":
		_handle_interior_input(
			event,
			interior_visual_data,
			refresh_interior_items_callable,
			update_interior_layer_callable
		)
		return

	if selected_layer == "panel":
		_handle_panel_input(
			event,
			panel_visual_data,
			update_panel_layer_callable
		)
		return


# print_selected_data — «напечатать выбранные данные»: выводит координаты ship-объекта в консоль.
func print_selected_data(
	module_layer_controller,
	pet_layer_controller,
	interior_visual_data: Dictionary,
	panel_visual_data: Dictionary
) -> void:
	print("----- DEBUG ITEM DATA -----")
	print("Layer: ", selected_layer)

	if selected_layer == "module":
		var visual_dict: Dictionary = module_layer_controller.module_visual_data
		if not visual_dict.has(selected_item_id):
			return

		var data = visual_dict[selected_item_id]
		print("\"", selected_item_id, "\": {")
		print("\t\"texture_path\": \"", data["texture_path"], "\",")
		print("\t\"anchor_pos\": Vector2(", data["anchor_pos"].x, ", ", data["anchor_pos"].y, "),")
		print("\t\"scale\": ", data.get("scale", 1.0))
		print("}")
		print("---------------------------")
		return

	if selected_layer == "pet":
		var visual_dict_pet: Dictionary = pet_layer_controller.pet_visual_data
		if not visual_dict_pet.has(selected_item_id):
			return

		var pet_data = visual_dict_pet[selected_item_id]
		var zones: Array = pet_data["zones"]

		if selected_pet_zone < 0 or selected_pet_zone >= zones.size():
			return

		var zone_data: Dictionary = zones[selected_pet_zone]
		print("\"", selected_item_id, "\" zone ", selected_pet_zone, ": {")
		print("\t\"texture_path\": \"", zone_data["texture_path"], "\",")
		print("\t\"anchor_pos\": Vector2(", zone_data["anchor_pos"].x, ", ", zone_data["anchor_pos"].y, "),")
		print("\t\"scale\": ", zone_data.get("scale", 1.0))
		print("}")
		print("---------------------------")
		return

	if selected_layer == "interior" or selected_layer == "interior.ship":
		if not interior_visual_data.has(selected_item_id):
			return

		var interior_data = interior_visual_data[selected_item_id]
		print("\"", selected_item_id, "\": {")
		print("\t\"texture_path\": \"", interior_data["texture_path"], "\",")
		print("\t\"zone\": ", interior_data.get("zone", 1), ",")
		print("\t\"anchor_pos\": Vector2(", interior_data["anchor_pos"].x, ", ", interior_data["anchor_pos"].y, "),")
		print("\t\"size_ratio\": Vector2(", interior_data["size_ratio"].x, ", ", interior_data["size_ratio"].y, ")")
		print("}")
		print("---------------------------")
		return

	if selected_layer == "panel":
		if not panel_visual_data.has(selected_item_id):
			return

		var panel_data = panel_visual_data[selected_item_id]
		print("\"", selected_item_id, "\": {")
		print("\t\"texture_path\": \"", panel_data["texture_path"], "\",")
		print("\t\"anchor_pos\": Vector2(", panel_data["anchor_pos"].x, ", ", panel_data["anchor_pos"].y, "),")
		print("\t\"scale\": ", panel_data.get("scale", 1.0))
		print("}")
		print("---------------------------")


# cycle_ship_interior_item — «переключить предмет интерьера корабля»: листает item_id интерьера.
func cycle_ship_interior_item(interior_visual_data: Dictionary, direction: int) -> void:
	var item_ids: Array[String] = []
	for item_id in interior_visual_data.keys():
		item_ids.append(String(item_id))

	item_ids.sort()
	if item_ids.is_empty():
		return

	var current_index := item_ids.find(selected_item_id)
	if current_index == -1:
		current_index = 0

	var next_index := posmod(current_index + direction, item_ids.size())
	selected_item_id = item_ids[next_index]
	print("Selected [interior.ship]: ", selected_item_id)


# handle_cargo_input — «обработать ввод Cargo»: двигает/масштабирует предметы внутри разделов склада.
func handle_cargo_input(event: InputEventKey, visual_data: Dictionary, update_layout_callable: Callable) -> bool:
	if not enabled:
		return false

	if _handle_cargo_cycle_input(event, visual_data):
		return true

	return _handle_cargo_transform_input(event, visual_data, update_layout_callable)


# _handle_cargo_cycle_input — «обработать переключение Cargo»: -/+ выбирают соседний item_id.
func _handle_cargo_cycle_input(event: InputEventKey, visual_data: Dictionary) -> bool:
	if event.keycode == KEY_MINUS or event.keycode == KEY_KP_SUBTRACT:
		cycle_cargo_item(visual_data, -1)
		return true

	if event.keycode == KEY_EQUAL or event.keycode == KEY_PLUS or event.keycode == KEY_KP_ADD:
		cycle_cargo_item(visual_data, 1)
		return true

	return false


# cycle_cargo_item — «переключить предмет Cargo»: сортирует ключи и выбирает следующий/предыдущий.
func cycle_cargo_item(visual_data: Dictionary, direction: int) -> void:
	var item_ids: Array[String] = []
	for item_id in visual_data.keys():
		item_ids.append(String(item_id))

	item_ids.sort()
	if item_ids.is_empty():
		return

	var current_index := item_ids.find(selected_item_id)
	if current_index == -1:
		current_index = 0

	var next_index := posmod(current_index + direction, item_ids.size())
	selected_item_id = item_ids[next_index]
	print("Selected [", selected_layer, "]: ", selected_item_id)


# _handle_cargo_transform_input — «обработать трансформацию Cargo»: меняет anchor_pos и size_ratio.
func _handle_cargo_transform_input(event: InputEventKey, visual_data: Dictionary, update_layout_callable: Callable) -> bool:
	if not visual_data.has(selected_item_id):
		return false

	var current_move_step: float = move_step_fine if event.shift_pressed else move_step
	var current_scale_step: float = scale_step_fine if event.shift_pressed else scale_step
	var data: Dictionary = visual_data[selected_item_id]
	var anchor_pos: Vector2 = data["anchor_pos"]
	var size_ratio: Vector2 = data["size_ratio"]
	var changed := false

	if event.keycode == KEY_LEFT:
		anchor_pos.x -= current_move_step
		changed = true
	elif event.keycode == KEY_RIGHT:
		anchor_pos.x += current_move_step
		changed = true
	elif event.keycode == KEY_UP:
		anchor_pos.y -= current_move_step
		changed = true
	elif event.keycode == KEY_DOWN:
		anchor_pos.y += current_move_step
		changed = true
	elif event.keycode == KEY_BRACKETLEFT:
		size_ratio *= (1.0 / current_scale_step)
		changed = true
	elif event.keycode == KEY_BRACKETRIGHT:
		size_ratio *= current_scale_step
		changed = true
	elif event.keycode == KEY_P:
		print_selected_cargo_data(visual_data)
		return true

	if not changed:
		return false

	anchor_pos.x = clamp(anchor_pos.x, 0.0, 1.0)
	anchor_pos.y = clamp(anchor_pos.y, 0.0, 1.0)
	size_ratio.x = clamp(size_ratio.x, min_size_ratio, max_size_ratio)
	size_ratio.y = clamp(size_ratio.y, min_size_ratio, max_size_ratio)

	visual_data[selected_item_id]["anchor_pos"] = anchor_pos
	visual_data[selected_item_id]["size_ratio"] = size_ratio
	update_layout_callable.call()

	print(
		"Updated [", selected_layer, "] ", selected_item_id,
		" -> anchor_pos=", anchor_pos,
		" size_ratio=", size_ratio
	)
	return true


# print_selected_cargo_data — «напечатать данные Cargo»: выводит готовый фрагмент словаря.
func print_selected_cargo_data(visual_data: Dictionary) -> void:
	if not visual_data.has(selected_item_id):
		return

	var data: Dictionary = visual_data[selected_item_id]
	print("\"", selected_item_id, "\": {")
	if data.has("texture_path"):
		print("\t\"texture_path\": \"", data["texture_path"], "\",")
	print("\t\"anchor_pos\": Vector2(", data["anchor_pos"].x, ", ", data["anchor_pos"].y, "),")
	print("\t\"size_ratio\": Vector2(", data["size_ratio"].x, ", ", data["size_ratio"].y, ")")
	print("}")


# _handle_pet_input — «обработать ввод питомца»: двигает текущую зону питомца в кокпите.
func _handle_pet_input(
	event: InputEventKey,
	pet_layer_controller,
	pet_layer: Control,
	cockpit_layer: Control,
	cockpit_texture: Texture2D,
	clear_layer_callable: Callable
) -> void:
	var visual_dict: Dictionary = pet_layer_controller.pet_visual_data

	if not visual_dict.has(selected_item_id):
		return

	var pet_data = visual_dict[selected_item_id]
	var zones: Array = pet_data["zones"]

	if selected_pet_zone < 0 or selected_pet_zone >= zones.size():
		return

	var current_move_step: float = move_step
	var current_scale_step: float = scale_step

	if event.shift_pressed:
		current_move_step = move_step_fine
		current_scale_step = scale_step_fine

	var changed := false
	var zone_data: Dictionary = zones[selected_pet_zone]
	var anchor_pos: Vector2 = zone_data["anchor_pos"]
	var scale_value: float = zone_data.get("scale", 1.0)

	if event.keycode == KEY_LEFT:
		anchor_pos.x -= current_move_step
		changed = true
	elif event.keycode == KEY_RIGHT:
		anchor_pos.x += current_move_step
		changed = true
	elif event.keycode == KEY_UP:
		anchor_pos.y -= current_move_step
		changed = true
	elif event.keycode == KEY_DOWN:
		anchor_pos.y += current_move_step
		changed = true
	elif event.keycode == KEY_BRACKETLEFT:
		scale_value *= (1.0 / current_scale_step)
		changed = true
	elif event.keycode == KEY_BRACKETRIGHT:
		scale_value *= current_scale_step
		changed = true
	elif event.keycode == KEY_1:
		_set_pet_zone(0, pet_layer_controller, pet_layer, cockpit_layer, cockpit_texture, clear_layer_callable)
		return
	elif event.keycode == KEY_2:
		_set_pet_zone(1, pet_layer_controller, pet_layer, cockpit_layer, cockpit_texture, clear_layer_callable)
		return
	elif event.keycode == KEY_3:
		_set_pet_zone(2, pet_layer_controller, pet_layer, cockpit_layer, cockpit_texture, clear_layer_callable)
		return
	elif event.keycode == KEY_4:
		_set_pet_zone(3, pet_layer_controller, pet_layer, cockpit_layer, cockpit_texture, clear_layer_callable)
		return
	elif event.keycode == KEY_5:
		_set_pet_zone(4, pet_layer_controller, pet_layer, cockpit_layer, cockpit_texture, clear_layer_callable)
		return
	elif event.keycode == KEY_6:
		_set_pet_zone(5, pet_layer_controller, pet_layer, cockpit_layer, cockpit_texture, clear_layer_callable)
		return
	elif event.keycode == KEY_7:
		_set_pet_zone(6, pet_layer_controller, pet_layer, cockpit_layer, cockpit_texture, clear_layer_callable)
		return
	elif event.keycode == KEY_8:
		_set_pet_zone(7, pet_layer_controller, pet_layer, cockpit_layer, cockpit_texture, clear_layer_callable)
		return

	anchor_pos.x = clamp(anchor_pos.x, 0.0, 1.0)
	anchor_pos.y = clamp(anchor_pos.y, 0.0, 1.0)
	scale_value = clamp(scale_value, 0.01, 10.0)

	zone_data["anchor_pos"] = anchor_pos
	zone_data["scale"] = scale_value
	zones[selected_pet_zone] = zone_data
	pet_data["zones"] = zones
	visual_dict[selected_item_id] = pet_data

	if changed:
		pet_layer_controller.update_layer(pet_layer, cockpit_layer, cockpit_texture)
		print(
			"Updated [pet] ", selected_item_id,
			" zone=", selected_pet_zone,
			" -> anchor_pos=", anchor_pos,
			" scale=", scale_value
		)


# _handle_module_input — «обработать ввод модуля»: двигает и масштабирует модуль на слое кокпита.
func _handle_module_input(
	event: InputEventKey,
	module_layer_controller,
	hardware_layer: Control,
	cockpit_layer: Control,
	cockpit_texture: Texture2D
) -> void:
	var visual_dict: Dictionary = module_layer_controller.module_visual_data

	if not visual_dict.has(selected_item_id):
		return

	var current_move_step: float = move_step
	var current_scale_step: float = scale_step

	if event.shift_pressed:
		current_move_step = move_step_fine
		current_scale_step = scale_step_fine

	var changed := false
	var anchor_pos: Vector2 = visual_dict[selected_item_id]["anchor_pos"]
	var scale_value: float = visual_dict[selected_item_id].get("scale", 1.0)

	if event.keycode == KEY_LEFT:
		anchor_pos.x -= current_move_step
		changed = true
	elif event.keycode == KEY_RIGHT:
		anchor_pos.x += current_move_step
		changed = true
	elif event.keycode == KEY_UP:
		anchor_pos.y -= current_move_step
		changed = true
	elif event.keycode == KEY_DOWN:
		anchor_pos.y += current_move_step
		changed = true
	elif event.keycode == KEY_BRACKETLEFT:
		scale_value *= (1.0 / current_scale_step)
		changed = true
	elif event.keycode == KEY_BRACKETRIGHT:
		scale_value *= current_scale_step
		changed = true

	anchor_pos.x = clamp(anchor_pos.x, 0.0, 1.0)
	anchor_pos.y = clamp(anchor_pos.y, 0.0, 1.0)
	scale_value = clamp(scale_value, 0.01, 10.0)

	visual_dict[selected_item_id]["anchor_pos"] = anchor_pos
	visual_dict[selected_item_id]["scale"] = scale_value

	if changed:
		module_layer_controller.update_layer(hardware_layer, cockpit_layer, cockpit_texture)
		print(
			"Updated [module] ", selected_item_id,
			" -> anchor_pos=", visual_dict[selected_item_id]["anchor_pos"],
			" scale=", visual_dict[selected_item_id]["scale"]
		)


# _handle_interior_input — «обработать ввод интерьера»: двигает интерьер корабля и меняет зону 1-8.
func _handle_interior_input(
	event: InputEventKey,
	interior_visual_data: Dictionary,
	refresh_interior_items_callable: Callable,
	update_interior_layer_callable: Callable
) -> void:
	if not interior_visual_data.has(selected_item_id):
		return

	var current_move_step: float = move_step
	var current_scale_step: float = scale_step

	if event.shift_pressed:
		current_move_step = move_step_fine
		current_scale_step = scale_step_fine

	var changed := false
	var anchor_pos: Vector2 = interior_visual_data[selected_item_id]["anchor_pos"]
	var size_ratio: Vector2 = interior_visual_data[selected_item_id]["size_ratio"]
	var zone_id: int = int(interior_visual_data[selected_item_id].get("zone", 1))

	if event.keycode == KEY_LEFT:
		anchor_pos.x -= current_move_step
		changed = true
	elif event.keycode == KEY_RIGHT:
		anchor_pos.x += current_move_step
		changed = true
	elif event.keycode == KEY_UP:
		anchor_pos.y -= current_move_step
		changed = true
	elif event.keycode == KEY_DOWN:
		anchor_pos.y += current_move_step
		changed = true
	elif event.keycode == KEY_BRACKETLEFT:
		size_ratio *= (1.0 / current_scale_step)
		changed = true
	elif event.keycode == KEY_BRACKETRIGHT:
		size_ratio *= current_scale_step
		changed = true
	elif event.keycode >= KEY_1 and event.keycode <= KEY_8:
		zone_id = int(event.keycode - KEY_0)
		interior_visual_data[selected_item_id]["zone"] = zone_id
		PlayerState.set_interior_item_zone(selected_item_id, zone_id)
		refresh_interior_items_callable.call()
		print("Assigned [interior.ship] ", selected_item_id, " -> zone=", zone_id)
		return

	anchor_pos.x = clamp(anchor_pos.x, 0.0, 1.0)
	anchor_pos.y = clamp(anchor_pos.y, 0.0, 1.0)
	size_ratio.x = clamp(size_ratio.x, min_ratio, max_ratio)
	size_ratio.y = clamp(size_ratio.y, min_ratio, max_ratio)

	interior_visual_data[selected_item_id]["anchor_pos"] = anchor_pos
	interior_visual_data[selected_item_id]["size_ratio"] = size_ratio
	interior_visual_data[selected_item_id]["zone"] = zone_id

	if changed:
		update_interior_layer_callable.call()
		print(
			"Updated [interior.ship] ", selected_item_id,
			" -> zone=", zone_id,
			" anchor_pos=", anchor_pos,
			" size_ratio=", size_ratio
		)


# _handle_panel_input — «обработать ввод панели»: двигает и масштабирует декоративные панели кокпита.
func _handle_panel_input(
	event: InputEventKey,
	panel_visual_data: Dictionary,
	update_panel_layer_callable: Callable
) -> void:
	if not panel_visual_data.has(selected_item_id):
		return

	var current_move_step: float = move_step
	var current_scale_step: float = scale_step

	if event.shift_pressed:
		current_move_step = move_step_fine
		current_scale_step = scale_step_fine

	var changed := false
	var anchor_pos: Vector2 = panel_visual_data[selected_item_id]["anchor_pos"]
	var scale_value: float = panel_visual_data[selected_item_id].get("scale", 1.0)

	if event.keycode == KEY_LEFT:
		anchor_pos.x -= current_move_step
		changed = true
	elif event.keycode == KEY_RIGHT:
		anchor_pos.x += current_move_step
		changed = true
	elif event.keycode == KEY_UP:
		anchor_pos.y -= current_move_step
		changed = true
	elif event.keycode == KEY_DOWN:
		anchor_pos.y += current_move_step
		changed = true
	elif event.keycode == KEY_BRACKETLEFT:
		scale_value *= (1.0 / current_scale_step)
		changed = true
	elif event.keycode == KEY_BRACKETRIGHT:
		scale_value *= current_scale_step
		changed = true

	anchor_pos.x = clamp(anchor_pos.x, 0.0, 1.0)
	anchor_pos.y = clamp(anchor_pos.y, 0.0, 1.2)
	scale_value = clamp(scale_value, 0.01, 10.0)

	panel_visual_data[selected_item_id]["anchor_pos"] = anchor_pos
	panel_visual_data[selected_item_id]["scale"] = scale_value

	if changed:
		update_panel_layer_callable.call()
		print(
			"Updated [panel] ", selected_item_id,
			" -> anchor_pos=", panel_visual_data[selected_item_id]["anchor_pos"],
			" scale=", panel_visual_data[selected_item_id]["scale"]
		)


# _set_pet_zone — «задать зону питомца»: выбирает индекс зоны и сразу обновляет слой питомцев.
func _set_pet_zone(
	zone_index: int,
	pet_layer_controller,
	pet_layer: Control,
	cockpit_layer: Control,
	cockpit_texture: Texture2D,
	clear_layer_callable: Callable
) -> void:
	selected_pet_zone = zone_index
	pet_layer_controller.active_pet_zone_indices[selected_item_id] = zone_index
	pet_layer_controller.refresh_items(pet_layer, clear_layer_callable)
	pet_layer_controller.update_layer(pet_layer, cockpit_layer, cockpit_texture)
	print("Selected pet zone: ", zone_index)
