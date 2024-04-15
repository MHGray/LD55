extends Button

const WORLD = preload("res://scenes/world.tscn")

func _on_pressed() -> void:
	get_tree().change_scene_to_packed(WORLD)
