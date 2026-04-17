extends Control

@onready var storage_background = $StorageBackground
@onready var alien_jelly_capsule = $AlienJellyCapsule
@onready var marta_cat_capsule = $MartaCatCapsule
@onready var robo_crab_capsule = $RoboCrabCapsule

@onready var tooltip_panel = $BottomInfoContainer/TooltipPanel
@onready var pet_name_label = $BottomInfoContainer/TooltipPanel/VBoxContainer/PetNameLabel
@onready var pet_description_label = $BottomInfoContainer/TooltipPanel/VBoxContainer/PetDescriptionLabel
@onready var pet_history_label = $BottomInfoContainer/TooltipPanel/VBoxContainer/PetHistoryLabel
@onready var action_button = $BottomInfoContainer/TooltipPanel/VBoxContainer/ActionButton


var selected_pet_id: String = ""

var pet_nodes: Dictionary = {}
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


func _ready() -> void:
	tooltip_panel.visible = false

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

	refresh()


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


func _on_pet_mouse_entered(pet_id: String) -> void:
	if not PlayerState.has_found_pet(pet_id):
		return

	selected_pet_id = pet_id
	_show_selected_pet_info()


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

	tooltip_panel.visible = true


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


func _on_player_pets_changed() -> void:
	refresh()
