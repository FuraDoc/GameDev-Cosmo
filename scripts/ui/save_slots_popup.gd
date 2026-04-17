extends Control

signal new_game_confirmed(slot_id: int, pilot_name: String)
signal continue_confirmed(slot_id: int)
signal cancelled

@onready var title_label = $CenterContainer/RootVBox/TitleLabel
@onready var slots_row = $CenterContainer/RootVBox/SlotsRow
@onready var back_button = $CenterContainer/RootVBox/BackButton

var mode: String = "new_game"
var save_slot_card_scene = preload("res://scenes/ui/save_slot_card.tscn")
var monitor_texture_path := "res://assets/backgrounds/equip/save_background.png"


func _ready():
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	back_button.pressed.connect(_on_back_button_pressed)
	setup_mode()
	build_cards()


func setup_mode() -> void:
	if mode == "new_game":
		title_label.text = "Новая игра"
	else:
		title_label.text = "Продолжить"


func build_cards() -> void:
	for child in slots_row.get_children():
		child.queue_free()
	
	var slots = SaveManager.get_all_slots_summary()
	
	for slot_data in slots:
		var card = save_slot_card_scene.instantiate()
		card.setup(mode, slot_data)
		
		card.new_game_requested.connect(_on_card_new_game_requested)
		card.continue_requested.connect(_on_card_continue_requested)
		
		slots_row.add_child(card)


func _on_card_new_game_requested(slot_id: int, pilot_name: String) -> void:
	new_game_confirmed.emit(slot_id, pilot_name)
	queue_free()


func _on_card_continue_requested(slot_id: int) -> void:
	continue_confirmed.emit(slot_id)
	queue_free()


func _on_back_button_pressed() -> void:
	cancelled.emit()
	queue_free()


func _unhandled_input(event):
	if event.is_action_pressed("ui_cancel"):
		cancelled.emit()
		queue_free()
		
		 
