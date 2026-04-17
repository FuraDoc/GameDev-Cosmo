extends Control

signal popup_closed

@onready var title_label = $CenterContainer/Panel/MarginContainer/VBoxContainer/TitleLabel

@onready var equipment_button = $CenterContainer/Panel/MarginContainer/VBoxContainer/ButtonsRow/EquipmentButton
@onready var interior_button = $CenterContainer/Panel/MarginContainer/VBoxContainer/ButtonsRow/InteriorButton
@onready var hardware_button = $CenterContainer/Panel/MarginContainer/VBoxContainer/ButtonsRow/HardwareButton
@onready var pets_button = $CenterContainer/Panel/MarginContainer/VBoxContainer/ButtonsRow/PetsButton

@onready var section_background = $CenterContainer/Panel/MarginContainer/VBoxContainer/ContentArea/SectionBackground
@onready var content_root = $CenterContainer/Panel/MarginContainer/VBoxContainer/ContentArea/ContentLayer/ContentRoot

@onready var close_button = $CenterContainer/Panel/MarginContainer/VBoxContainer/CloseButton

var current_section: String = "equipment"

var cargo_equipment_panel_scene = preload("res://scenes/ui/cargo_equipment_panel.tscn")
var cargo_interior_panel_scene = preload("res://scenes/ui/cargo_interior_panel.tscn")
var cargo_hardware_panel_scene = preload("res://scenes/ui/cargo_hardware_panel.tscn")
var cargo_pets_panel_scene = preload("res://scenes/ui/cargo_pets_panel.tscn")


var backgrounds := {
	"equipment": "",
	"interior": "",
	"hardware": "",
	"pets": ""
}


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	equipment_button.pressed.connect(_on_equipment_pressed)
	interior_button.pressed.connect(_on_interior_pressed)
	hardware_button.pressed.connect(_on_hardware_pressed)
	pets_button.pressed.connect(_on_pets_pressed)

	close_button.pressed.connect(_on_close_pressed)

	show_section("equipment")


func show_section(section_id: String) -> void:
	current_section = section_id
	update_title()
	update_background()
	rebuild_content()


func update_title() -> void:
	match current_section:
		"equipment":
			title_label.text = "Грузовой отсек — Снаряжение"
		"interior":
			title_label.text = "Грузовой отсек — Интерьер"
		"hardware":
			title_label.text = "Грузовой отсек — Модули"
		"pets":
			title_label.text = "Грузовой отсек — Питомцы"
		_:
			title_label.text = "Грузовой отсек"


func update_background() -> void:
	var path = backgrounds.get(current_section, "")

	if path.is_empty():
		section_background.texture = null
		return

	var texture = load(path)
	if texture == null:
		push_error("CargoBayPopup: не удалось загрузить фон секции: " + path)
		section_background.texture = null
		return

	section_background.texture = texture


func rebuild_content() -> void:
	for child in content_root.get_children():
		content_root.remove_child(child)
		child.free()

	if current_section == "equipment":
		var equipment_panel = cargo_equipment_panel_scene.instantiate()
		content_root.add_child(equipment_panel)
		equipment_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		equipment_panel.mouse_filter = Control.MOUSE_FILTER_STOP
		return

	if current_section == "interior":
		var interior_panel = cargo_interior_panel_scene.instantiate()
		content_root.add_child(interior_panel)
		interior_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		interior_panel.mouse_filter = Control.MOUSE_FILTER_STOP
		return

	if current_section == "hardware":
		var hardware_panel = cargo_hardware_panel_scene.instantiate()
		content_root.add_child(hardware_panel)
		hardware_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		hardware_panel.mouse_filter = Control.MOUSE_FILTER_STOP
		return
	if current_section == "pets":
		var pets_panel = cargo_pets_panel_scene.instantiate()
		content_root.add_child(pets_panel)
		pets_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		pets_panel.mouse_filter = Control.MOUSE_FILTER_STOP
		return

	var label = Label.new()
	label.text = _get_placeholder_text()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_root.add_child(label)


func _get_placeholder_text() -> String:
	match current_section:
		"equipment":
			return "Раздел снаряжения."
		"interior":
			return "Раздел интерьера."
		"hardware":
			return "Раздел модулей."
		"pets":
			return "Раздел питомцев.\nЗдесь позже будет выбор активного питомца."
		_:
			return "Пустой раздел."


func _on_equipment_pressed() -> void:
	show_section("equipment")


func _on_interior_pressed() -> void:
	show_section("interior")


func _on_hardware_pressed() -> void:
	show_section("hardware")


func _on_pets_pressed() -> void:
	show_section("pets")


func _on_close_pressed() -> void:
	close_popup()


func _unhandled_input(event) -> void:
	if event.is_action_pressed("ui_cancel"):
		close_popup()


func close_popup() -> void:
	popup_closed.emit()
	queue_free()
