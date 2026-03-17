extends Control

func _on_menu_button_pressed():
	get_tree().change_scene_to_file("res://scenes/main/main_scene.tscn")


func _on_button_pressed() -> void:
	pass # Replace with function body.


	

func _on_text_quest_button_pressed():
	if $UI.has_node("TextQuest"):
		return
	var quest_scene = load("res://scenes/text_quest/text_quest.tscn")
	var quest_instance = quest_scene.instantiate()
	$UI.add_child(quest_instance)
	quest_instance.move_to_front()
	

@onready var space_view = $SpaceView
@onready var fade_overlay = $UI/FadeOverlay

var backgrounds = [
	"res://assets/backgrounds/space/space_1.jpg",
	"res://assets/backgrounds/space/space_2.jpg",
	"res://assets/backgrounds/space/space_3.jpg"
]

var current_background_index = 0
var is_transitioning = false

func _ready():
	update_space_view()

func update_space_view():
	var texture = load(backgrounds[current_background_index])
	space_view.texture = texture

func _on_next_adventure_button_pressed():
	if is_transitioning:
		return
	
	is_transitioning = true
	await play_transition()
	
	current_background_index += 1
	if current_background_index >= backgrounds.size():
		current_background_index = 0
	
	update_space_view()
	
	await play_fade_in()
	is_transitioning = false

func play_transition() -> void:
	var tween = create_tween()
	tween.tween_property(fade_overlay, "color:a", 1.0, 1.0)
	await tween.finished
	
	await get_tree().create_timer(1.0).timeout

func play_fade_in() -> void:
	var tween = create_tween()
	tween.tween_property(fade_overlay, "color:a", 0.0, 1.0)
	await tween.finished
