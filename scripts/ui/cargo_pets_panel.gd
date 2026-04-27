extends Control

# Подключаем общий debug-контроллер для ручного позиционирования питомцев в Cargo.
const ShipDebugPositioningController = preload("res://scripts/ship/ship_debug_positioning_controller.gd")

# Фон раздела «Питомцы»: по нему считаются координаты капсул и popup.
@onready var storage_background = $StorageBackground

# Капсула медузки в Cargo Pets.
@onready var alien_jelly_capsule = $AlienJellyCapsule

# Капсула Марты в Cargo Pets.
@onready var marta_cat_capsule = $MartaCatCapsule

# Капсула робо-краба в Cargo Pets.
@onready var robo_crab_capsule = $RoboCrabCapsule

# Панель подробного описания питомца.
@onready var tooltip_panel = $BottomInfoContainer/TooltipPanel

# Заголовок popup-окна: имя питомца.
@onready var pet_name_label = $BottomInfoContainer/TooltipPanel/VBoxContainer/PetNameLabel

# Основное описание питомца.
@onready var pet_description_label = $BottomInfoContainer/TooltipPanel/VBoxContainer/PetDescriptionLabel

# История питомца: отдельный текстовый блок в большом popup.
@onready var pet_history_label = $BottomInfoContainer/TooltipPanel/VBoxContainer/PetHistoryLabel

# Кнопка действия: «Призвать» или «Вернуть».
@onready var action_button = $BottomInfoContainer/TooltipPanel/VBoxContainer/ActionButton


# Выбранный pet_id: используется popup-окном и debug-позиционированием.
var selected_pet_id: String = ""

# Словарь pet_id -> TextureRect капсулы.
var pet_nodes: Dictionary = {}

# Экземпляр общего debug-контроллера для движения питомцев по фону раздела.
var debug_controller := ShipDebugPositioningController.new()

# Позиция и размер popup-окна в нормализованных координатах drawn rect фона.
var info_popup_rect := Rect2(Vector2(0.260, 0.095), Vector2(0.480, 0.300))

# Визуальные данные капсул: anchor_pos задает центр, size_ratio задает область размера.
var cargo_visual_data := {
	"alien_jelly": {"anchor_pos": Vector2(0.225, 0.616), "size_ratio": Vector2(0.232, 0.483)},
	"marta_cat": {"anchor_pos": Vector2(0.512, 0.666), "size_ratio": Vector2(0.276, 0.340)},
	"robo_crab": {"anchor_pos": Vector2(0.804, 0.619), "size_ratio": Vector2(0.280, 0.525)},
}

# Текстовые данные питомцев: имя, описание и история для popup-окна.
var pet_data := {
	"alien_jelly": {
		"name": "Левитирующая медузка",
		"description": "Мягко светящееся существо, способное бесшумно дрейфовать по кабине часами.",
		"history": "Найдена в старом биоконтейнере среди груза, который давно должен был быть списан. Похоже, медузка решила, что корабль теперь её дом."
	},
	"marta_cat": {
		"name": "Марта",
		"description": "Рыжая кошка с независимым характером и удивительным талантом устраиваться в самых неожиданных местах.",
		"history": "Найдена в гибернационной камере дрейфующего модуля и спасена игроком. С тех пор считает корабль своей территорией, а экипаж — персоналом."
	},
	"robo_crab": {
		"name": "Мистер Крабс",
		"description": "Экспериментальный сервисный дрон с повышенным интеллектом и чувством собственного величия.",
		"history": "Найден на заброшенной станции, и благополучно доставлен на борт вместе со своей станцией."
	}
}


# _ready — «готово»: настраивает popup, словари питомцев, сигналы и первичную раскладку.
func _ready() -> void:
	tooltip_panel.visible = false
	tooltip_panel.clip_contents = true
	pet_name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	pet_name_label.clip_text = true
	pet_description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	pet_description_label.clip_text = true
	pet_description_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	pet_history_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	pet_history_label.clip_text = true
	pet_history_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	action_button.size_flags_horizontal = Control.SIZE_SHRINK_END
	action_button.size_flags_vertical = Control.SIZE_SHRINK_END
	$BottomInfoContainer.z_index = 100
	debug_controller.selected_layer = "pets.cargo"
	debug_controller.selected_item_id = "alien_jelly"

	pet_nodes = {
		"alien_jelly": alien_jelly_capsule,
		"marta_cat": marta_cat_capsule,
		"robo_crab": robo_crab_capsule
	}

	for pet_id in pet_nodes.keys():
		var node = pet_nodes[pet_id]
		node.mouse_entered.connect(_on_pet_mouse_entered.bind(pet_id))

	action_button.pressed.connect(_on_action_button_pressed)

	if PlayerState.has_signal("pets_changed"):
		PlayerState.pets_changed.connect(_on_player_pets_changed)

	await get_tree().process_frame
	_update_item_layout()
	_update_popup_layout()
	refresh()


# refresh — «обновить»: показывает найденных питомцев и состояние активного питомца.
func refresh() -> void:
	for pet_id in pet_nodes.keys():
		var node = pet_nodes[pet_id]
		var found = PlayerState.has_found_pet(pet_id)
		var active = PlayerState.is_pet_active(pet_id)

		node.visible = found
		node.mouse_filter = Control.MOUSE_FILTER_STOP if found else Control.MOUSE_FILTER_IGNORE

		if found:
			node.modulate.a = 0.5 if active else 1.0
		else:
			node.modulate.a = 1.0

	if selected_pet_id.is_empty():
		tooltip_panel.visible = false
		return

	if not PlayerState.has_found_pet(selected_pet_id):
		selected_pet_id = ""
		tooltip_panel.visible = false
		return

	_show_selected_pet_info()


# _on_pet_mouse_entered — «мышь вошла в питомца»: выбирает найденного питомца для popup.
func _on_pet_mouse_entered(pet_id: String) -> void:
	if not PlayerState.has_found_pet(pet_id):
		return

	selected_pet_id = pet_id
	debug_controller.selected_item_id = pet_id
	_show_selected_pet_info()


# _show_selected_pet_info — «показать информацию питомца»: заполняет имя, описание, историю и кнопку.
func _show_selected_pet_info() -> void:
	if selected_pet_id.is_empty():
		tooltip_panel.visible = false
		return

	var data = pet_data.get(selected_pet_id, null)
	if data == null:
		pet_name_label.text = "Неизвестный питомец"
		pet_description_label.text = "Описание отсутствует."
		pet_history_label.text = ""
	else:
		pet_name_label.text = data.name
		pet_description_label.text = data.description
		pet_history_label.text = data.history

	var active = PlayerState.is_pet_active(selected_pet_id)
	action_button.text = "Вернуть" if active else "Призвать"

	_update_popup_layout()
	tooltip_panel.visible = true
	call_deferred("_update_popup_layout")


# _on_action_button_pressed — «нажата кнопка действия»: призывает или возвращает питомца.
func _on_action_button_pressed() -> void:
	if selected_pet_id.is_empty():
		return

	if not PlayerState.has_found_pet(selected_pet_id):
		return

	if PlayerState.is_pet_active(selected_pet_id):
		PlayerState.return_active_pet()
	else:
		PlayerState.summon_pet(selected_pet_id)

	refresh()


# _on_player_pets_changed — «изменились питомцы игрока»: обновляет капсулы и popup.
func _on_player_pets_changed() -> void:
	refresh()


# _unhandled_input — «необработанный ввод»: передает debug-клавиши питомцев в общий контроллер.
func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if not (event is InputEventKey):
		return

	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return

	var handled := debug_controller.handle_cargo_input(key_event, cargo_visual_data, Callable(self, "_update_item_layout"))
	if handled:
		selected_pet_id = debug_controller.selected_item_id
		refresh()
		get_viewport().set_input_as_handled()


# _update_item_layout — «обновить раскладку предметов»: ставит капсулы по anchor_pos и size_ratio.
func _update_item_layout() -> void:
	var background_rect := _get_drawn_background_rect(storage_background)
	if background_rect.size.x <= 0.0 or background_rect.size.y <= 0.0:
		return

	for pet_id in pet_nodes.keys():
		if not cargo_visual_data.has(pet_id):
			continue

		var node := pet_nodes[pet_id] as TextureRect
		var data: Dictionary = cargo_visual_data[pet_id]
		var anchor_pos: Vector2 = data["anchor_pos"]
		var size_ratio: Vector2 = data["size_ratio"]
		var item_size := _calculate_preserved_item_size(node.texture, background_rect.size * size_ratio)

		node.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
		node.size = item_size
		node.position = background_rect.position + Vector2(
			background_rect.size.x * anchor_pos.x - item_size.x * 0.5,
			background_rect.size.y * anchor_pos.y - item_size.y * 0.5
		)

	_update_popup_layout()


# _update_popup_layout — «обновить раскладку popup»: привязывает окно описания к drawn rect фона.
func _update_popup_layout() -> void:
	var background_rect := _get_drawn_background_rect(storage_background)
	if background_rect.size.x <= 0.0 or background_rect.size.y <= 0.0:
		return

	var popup_position := background_rect.position + info_popup_rect.position * background_rect.size
	var popup_size := info_popup_rect.size * background_rect.size

	$BottomInfoContainer.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	$BottomInfoContainer.custom_minimum_size = Vector2.ZERO
	$BottomInfoContainer.position = popup_position
	$BottomInfoContainer.size = popup_size
	tooltip_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tooltip_panel.offset_left = 0.0
	tooltip_panel.offset_top = 0.0
	tooltip_panel.offset_right = 0.0
	tooltip_panel.offset_bottom = 0.0
	var vbox := tooltip_panel.get_node_or_null("VBoxContainer") as VBoxContainer
	if vbox != null:
		vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		vbox.clip_contents = true
		vbox.offset_left = 18.0
		vbox.offset_top = 16.0
		vbox.offset_right = -18.0
		vbox.offset_bottom = -16.0

# _get_drawn_background_rect — «получить нарисованный прямоугольник фона»: учитывает cover-растяжение.
func _get_drawn_background_rect(background: TextureRect) -> Rect2:
	if background == null or not is_instance_valid(background):
		return Rect2()

	var viewport_size := background.size
	if background.texture == null:
		return Rect2(Vector2.ZERO, viewport_size)

	var texture_size := background.texture.get_size()
	if texture_size.x <= 0.0 or texture_size.y <= 0.0 or viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return Rect2(Vector2.ZERO, viewport_size)

	var scale_value: float = max(viewport_size.x / texture_size.x, viewport_size.y / texture_size.y)
	var drawn_size := texture_size * scale_value
	var drawn_position := (viewport_size - drawn_size) * 0.5
	return Rect2(drawn_position, drawn_size)


# _calculate_preserved_item_size — «рассчитать сохраненный размер»: вписывает капсулу без искажения.
func _calculate_preserved_item_size(texture: Texture2D, max_size: Vector2) -> Vector2:
	if texture == null:
		return max_size

	var texture_size := texture.get_size()
	if texture_size.x <= 0.0 or texture_size.y <= 0.0:
		return max_size

	var scale_value: float = min(max_size.x / texture_size.x, max_size.y / texture_size.y)
	return texture_size * scale_value


# _notification — «уведомление»: при resize пересчитывает капсулы и popup.
func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and is_node_ready():
		_update_item_layout()
		_update_popup_layout()
