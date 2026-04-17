extends Control

# =========================================================
# CARGO EQUIPMENT PANEL
# =========================================================
# Встроенная панель раздела "Снаряжение" внутри CargoBayPopup.
#
# Это не отдельный popup, а обычная внутренняя панель.
# Поэтому здесь:
# - нет затемнения фона
# - нет кнопки закрытия
# - нет сигнала close_requested
# =========================================================

@onready var stand_background = $StandBackground
@onready var tooltip_panel = $TooltipPanel
@onready var tooltip_label = $TooltipPanel/TooltipLabel

@onready var rescue_suit_item = $RescueSuitItem
@onready var ar_visor_item = $ArVisorItem
@onready var wave_drone_item = $WaveDroneItem
@onready var analytic_resonator_item = $AnalyticResonatorItem
@onready var smart_metal_container_item = $SmartMetalContainerItem

var _spot_to_item_id: Dictionary = {}


func _ready() -> void:
	tooltip_panel.visible = false
	
	_spot_to_item_id = {
		rescue_suit_item: "rescue_suit",
		ar_visor_item: "ar_visor",
		wave_drone_item: "wave_drone",
		analytic_resonator_item: "analytic_resonator",
		smart_metal_container_item: "smart_metal_container"
	}
	
	_setup_item_nodes()
	refresh()


func refresh() -> void:
	tooltip_panel.visible = false
	
	for item_node in _spot_to_item_id.keys():
		var item_id = _spot_to_item_id[item_node]
		var item_data = ItemDatabase.get_item(item_id)
		
		if item_data == null:
			push_error("CargoEquipmentPanel.refresh(): не найден ItemData для id: " + item_id)
			item_node.visible = false
			continue
		
		if PlayerState.has_item(item_id):
			item_node.visible = true
			item_node.texture = item_data.equipment_texture
		else:
			item_node.visible = false


func _setup_item_nodes() -> void:
	for item_node in _spot_to_item_id.keys():
		item_node.mouse_filter = Control.MOUSE_FILTER_STOP
		item_node.mouse_entered.connect(_on_item_mouse_entered.bind(item_node))
		item_node.mouse_exited.connect(_on_item_mouse_exited.bind(item_node))


func _on_item_mouse_entered(item_node: TextureRect) -> void:
	var item_id = _spot_to_item_id.get(item_node, "")
	if item_id.is_empty():
		return
	
	if not PlayerState.has_item(item_id):
		return
	
	var item_data = ItemDatabase.get_item(item_id)
	if item_data == null:
		return
	
	_show_tooltip_for_item(item_data)


func _on_item_mouse_exited(item_node: TextureRect) -> void:
	tooltip_panel.visible = false


func _show_tooltip_for_item(item_data: ItemData) -> void:
	tooltip_label.text = item_data.title + "\n\n" + item_data.description
	tooltip_panel.visible = true
