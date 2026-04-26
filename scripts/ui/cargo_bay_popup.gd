extends Control

signal popup_closed

@onready var content_root: Control = $ContentRoot
@onready var cargo_frame: TextureRect = $CargoFrame
@onready var button_layer: Control = $ButtonLayer

@onready var equipment_button: Button = $ButtonLayer/EquipmentButton
@onready var interior_button: Button = $ButtonLayer/InteriorButton
@onready var hardware_button: Button = $ButtonLayer/HardwareButton
@onready var pets_button: Button = $ButtonLayer/PetsButton
@onready var close_button: Button = $ButtonLayer/CloseButton

const SECTION_SCENES := {
	"equipment": preload("res://scenes/ui/cargo_equipment_panel.tscn"),
	"interior": preload("res://scenes/ui/cargo_interior_panel.tscn"),
	"hardware": preload("res://scenes/ui/cargo_hardware_panel.tscn"),
	"pets": preload("res://scenes/ui/cargo_pets_panel.tscn"),
}

const BUTTON_ORDER: Array[String] = [
	"equipment",
	"interior",
	"hardware",
	"pets",
	"close",
]

const MOVE_STEP := 0.002
const MOVE_STEP_FINE := 0.0005
const SIZE_STEP := 0.002
const SIZE_STEP_FINE := 0.0005
const MIN_BUTTON_SIZE := Vector2(0.02, 0.02)

var current_section: String = "equipment"
var debug_buttons_enabled := false
var debug_selected_button_id := "equipment"

var button_nodes: Dictionary = {}

# Rect2 values are normalized frame-texture coordinates: 0..1 across the source frame.
var button_rects := {
	"equipment": Rect2(Vector2(0.281, 0.037), Vector2(0.095, 0.044)),
	"interior": Rect2(Vector2(0.396, 0.037), Vector2(0.095, 0.043)),
	"hardware": Rect2(Vector2(0.510, 0.037), Vector2(0.095, 0.044)),
	"pets": Rect2(Vector2(0.624, 0.037), Vector2(0.095, 0.044)),
	"close": Rect2(Vector2(0.457, 0.902), Vector2(0.087, 0.044)),
}


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	z_index = 100

	content_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	content_root.z_index = 0

	cargo_frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	cargo_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cargo_frame.z_index = 20

	button_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	button_layer.z_index = 30

	button_nodes = {
		"equipment": equipment_button,
		"interior": interior_button,
		"hardware": hardware_button,
		"pets": pets_button,
		"close": close_button,
	}

	equipment_button.text = "Снаряжение"
	interior_button.text = "Интерьер"
	hardware_button.text = "Оборудование"
	pets_button.text = "Питомцы"
	close_button.text = "Закрыть"

	equipment_button.pressed.connect(func(): show_section("equipment"))
	interior_button.pressed.connect(func(): show_section("interior"))
	hardware_button.pressed.connect(func(): show_section("hardware"))
	pets_button.pressed.connect(func(): show_section("pets"))
	close_button.pressed.connect(close_popup)

	_update_button_layout()
	show_section("equipment")


func show_section(section_id: String) -> void:
	if not SECTION_SCENES.has(section_id):
		return

	current_section = section_id
	_update_section_buttons()
	_rebuild_content()


func _update_section_buttons() -> void:
	equipment_button.disabled = current_section == "equipment"
	interior_button.disabled = current_section == "interior"
	hardware_button.disabled = current_section == "hardware"
	pets_button.disabled = current_section == "pets"
	close_button.disabled = false


func _rebuild_content() -> void:
	for child in content_root.get_children():
		child.free()

	var scene: PackedScene = SECTION_SCENES[current_section]
	var panel: Control = scene.instantiate()
	content_root.add_child(panel)
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.z_index = 0
	panel.mouse_filter = Control.MOUSE_FILTER_STOP


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and is_node_ready():
		_update_button_layout()


func _update_button_layout() -> void:
	var frame_rect := _get_drawn_frame_rect()
	if frame_rect.size.x <= 0.0 or frame_rect.size.y <= 0.0:
		return

	for button_id in button_nodes.keys():
		var button := button_nodes[button_id] as Button
		var normalized_rect: Rect2 = button_rects[button_id]

		button.position = frame_rect.position + normalized_rect.position * frame_rect.size
		button.size = normalized_rect.size * frame_rect.size
		button.custom_minimum_size = Vector2.ZERO
		button.focus_mode = Control.FOCUS_NONE


func _get_drawn_frame_rect() -> Rect2:
	var viewport_size := size
	if cargo_frame.texture == null:
		return Rect2(Vector2.ZERO, viewport_size)

	var texture_size := cargo_frame.texture.get_size()
	if texture_size.x <= 0.0 or texture_size.y <= 0.0 or viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return Rect2(Vector2.ZERO, viewport_size)

	var scale_value: float = max(viewport_size.x / texture_size.x, viewport_size.y / texture_size.y)
	var drawn_size := texture_size * scale_value
	var drawn_position := (viewport_size - drawn_size) * 0.5
	return Rect2(drawn_position, drawn_size)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		close_popup()
		return

	if not debug_buttons_enabled:
		return

	if not (event is InputEventKey):
		return

	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return

	if _handle_debug_cycle_input(key_event):
		get_viewport().set_input_as_handled()
		return

	if _handle_debug_transform_input(key_event):
		get_viewport().set_input_as_handled()


func _handle_debug_cycle_input(event: InputEventKey) -> bool:
	if event.keycode == KEY_MINUS or event.keycode == KEY_KP_SUBTRACT:
		_cycle_debug_button(-1)
		return true

	if event.keycode == KEY_EQUAL or event.keycode == KEY_PLUS or event.keycode == KEY_KP_ADD:
		_cycle_debug_button(1)
		return true

	return false


func _handle_debug_transform_input(event: InputEventKey) -> bool:
	if not button_rects.has(debug_selected_button_id):
		return false

	var move_step := MOVE_STEP_FINE if event.shift_pressed else MOVE_STEP
	var size_step := SIZE_STEP_FINE if event.shift_pressed else SIZE_STEP
	var rect: Rect2 = button_rects[debug_selected_button_id]
	var changed := false

	if event.keycode == KEY_LEFT:
		rect.position.x -= move_step
		changed = true
	elif event.keycode == KEY_RIGHT:
		rect.position.x += move_step
		changed = true
	elif event.keycode == KEY_UP:
		rect.position.y -= move_step
		changed = true
	elif event.keycode == KEY_DOWN:
		rect.position.y += move_step
		changed = true
	elif event.keycode == KEY_BRACKETLEFT:
		rect.size -= Vector2(size_step, size_step)
		changed = true
	elif event.keycode == KEY_BRACKETRIGHT:
		rect.size += Vector2(size_step, size_step)
		changed = true
	elif event.keycode == KEY_P:
		_print_debug_button_rect()
		return true

	if not changed:
		return false

	rect.size.x = max(rect.size.x, MIN_BUTTON_SIZE.x)
	rect.size.y = max(rect.size.y, MIN_BUTTON_SIZE.y)
	button_rects[debug_selected_button_id] = rect
	_update_button_layout()

	print(
		"Updated [cargo_button] ", debug_selected_button_id,
		" -> position=", rect.position,
		" size=", rect.size
	)
	return true


func _cycle_debug_button(direction: int) -> void:
	var current_index := BUTTON_ORDER.find(debug_selected_button_id)
	if current_index == -1:
		current_index = 0

	var next_index := posmod(current_index + direction, BUTTON_ORDER.size())
	debug_selected_button_id = BUTTON_ORDER[next_index]
	print("Selected [cargo_button]: ", debug_selected_button_id)


func _print_debug_button_rect() -> void:
	var rect: Rect2 = button_rects[debug_selected_button_id]
	print("\"", debug_selected_button_id, "\": Rect2(")
	print("\tVector2(", rect.position.x, ", ", rect.position.y, "),")
	print("\tVector2(", rect.size.x, ", ", rect.size.y, ")")
	print("),")


func close_popup() -> void:
	popup_closed.emit()
	queue_free()
