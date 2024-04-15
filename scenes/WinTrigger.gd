extends Area3D




func _on_area_entered(area: Area3D) -> void:
	if area.is_in_group("player"):
		get_tree().change_scene_to_packed(load("res://scenes/winScene.tscn"))
