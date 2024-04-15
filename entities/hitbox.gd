extends Area3D

@export var thing_dealing_damage: Node3D
# Called when the node enters the scene tree for the first time.
func damage() -> int:
	return thing_dealing_damage.damage
