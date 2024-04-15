extends Node3D

@export var enemies:Array[CharacterBody3D]
var open_door:bool = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	var enemies_dead = true
	for enemy in enemies:
		if enemy.health > 0:
			enemies_dead = false
	
	if enemies_dead:
		open_door = true
	

	
