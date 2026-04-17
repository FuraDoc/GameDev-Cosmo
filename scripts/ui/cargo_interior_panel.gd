extends Control

@onready var storage_background = $StorageBackground
@onready var test_item = $TestInteriorItem
@onready var sleep_zone_item = $SleepZoneItem
@onready var stool_item = $StoolItem

@onready var tooltip_panel = $BottomInfoContainer/TooltipPanel
@onready var item_name_label = $BottomInfoContainer/TooltipPanel/VBoxContainer/ItemNameLabel
@onready var item_description_label = $BottomInfoContainer/TooltipPanel/VBoxContainer/ItemDescriptionLabel
@onready var action_button = $BottomInfoContainer/TooltipPanel/VBoxContainer/ActionButton

var selected_item_id: String = ""

var item_nodes: Dictionary = {}
var item_data := {
	"small_plant": {
		"title": "Декоративное растение",
		"description": "Небольшой интерьерный предмет для кокпита."
	},
	"sleep_zone": {
		"title": "Sleep Zone",
		"description": "Компактная зона отдыха для длительных перелётов."
	},
	"stool": {
		"title": "Stool",
		"description": "Небольшой табурет для внутреннего пространства кокпита."
	}
}


func _ready() -> void:
	tooltip_panel.visible = false

	item_nodes = {
		"small_plant": test_item,
		"sleep_zone": sleep_zone_item,
		"stool": stool_item
	}

	for item_id in item_nodes.keys():
		var node = item_nodes[item_id]
		node.mouse_entered.connect(_on_item_mouse_entered.bind(item_id))

	action_button.pressed.connect(_on_action_button_pressed)

	if PlayerState.has_signal("interior_changed"):
		PlayerState.interior_changed.connect(_on_player_interior_changed)

	refresh()


func refresh() -> void:
	for item_id in item_nodes.keys():
		var node = item_nodes[item_id]
		var found = PlayerState.has_found_interior_item(item_id)
		var installed = PlayerState.is_interior_item_installed(item_id)

		node.visible = found
		node.mouse_filter = Control.MOUSE_FILTER_STOP if found else Control.MOUSE_FILTER_IGNORE

		if found:
			node.modulate.a = 0.5 if installed else 1.0
		else:
			node.modulate.a = 1.0

	if selected_item_id.is_empty():
		tooltip_panel.visible = false
		return

	if not PlayerState.has_found_interior_item(selected_item_id):
		selected_item_id = ""
		tooltip_panel.visible = false
		return

	_show_selected_item_info()


func _on_item_mouse_entered(item_id: String) -> void:
	if not PlayerState.has_found_interior_item(item_id):
		return

	selected_item_id = item_id
	_show_selected_item_info()


func _show_selected_item_info() -> void:
	if selected_item_id.is_empty():
		tooltip_panel.visible = false
		return

	var data = item_data.get(selected_item_id, null)
	if data == null:
		item_name_label.text = "Неизвестный предмет"
		item_description_label.text = "Описание отсутствует."
	else:
		item_name_label.text = data.title
		item_description_label.text = data.description

	var installed = PlayerState.is_interior_item_installed(selected_item_id)
	action_button.text = "Убрать" if installed else "Установить"

	tooltip_panel.visible = true


func _on_action_button_pressed() -> void:
	if selected_item_id.is_empty():
		return

	if not PlayerState.has_found_interior_item(selected_item_id):
		return

	if PlayerState.is_interior_item_installed(selected_item_id):
		PlayerState.uninstall_interior_item(selected_item_id)
	else:
		PlayerState.install_interior_item(selected_item_id)

	refresh()


func _on_player_interior_changed() -> void:
	refresh()
