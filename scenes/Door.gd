extends MeshInstance3D

var move_down_time = 5
@export var open = false

@export var trigger:Node3D

signal opened

func _physics_process(delta: float) -> void:
	if trigger.open_door:
		open = true
	if open:
		position.y -= delta
		move_down_time -= delta
		if move_down_time <= 0:
			queue_free()


