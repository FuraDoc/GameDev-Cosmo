extends Control

func _on_fly_button_pressed():
	get_tree().change_scene_to_file("res://scenes/ship/ship_scene.tscn")

func _on_exit_button_pressed():
	get_tree().quit()
	get_tree().change_scene_to_file("res://scenes/ship/ship_scene.tscn")
	pass # Replace with function body.
