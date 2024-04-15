extends CharacterBody3D


@export var SPEED = 1
var damage = 1
@export var time_to_live = 3

func _ready() -> void:
	print("Ready rotation:" + str(rotation))

func _physics_process(delta: float) -> void:
	velocity = Vector3(0,0,SPEED).rotated(Vector3.UP, rotation.y)
	time_to_live -= delta
	if time_to_live <= 0:
		queue_free()
	move_and_slide()


func _on_area_3d_area_entered(area: Area3D) -> void:
	if area.is_in_group("player") or area.is_in_group("walls"):
		queue_free()

func _on_area_3d_body_entered(body: Node3D) -> void:
	if body.is_in_group("player") or body.is_in_group("walls"):
		queue_free()
