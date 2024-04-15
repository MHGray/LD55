extends CharacterBody3D

const TOOF = preload("res://entities/toof.tscn")

@onready var hurtbox: Area3D = $Hurtbox
@onready var collision_box: CollisionShape3D = $CollisionBox
@onready var navigation_agent: NavigationAgent3D = $NavigationAgent3D
@onready var armature: Node3D = $Armature
@onready var sfx_player: AudioStreamPlayer3D = $SFXPlayer
@export var patrol_points: Array[Node3D]
@export var world:Node3D


enum sfx {
	SFX_ATTACK,
	SFX_DAMAGE,
	SFX_DEATH,
}

var sfx_dictionary = {
	sfx.SFX_ATTACK: preload("res://audio/sfx/ball_attack.mp3"),
	sfx.SFX_DAMAGE: preload("res://audio/sfx/ball_damage.mp3"),
	sfx.SFX_DEATH: preload("res://audio/sfx/ball_death.mp3")
}

@export var next_decision_max:float = 3
var next_decision:float = next_decision_max

var next_patrol_point:Node3D
var pick_new_patrol_point:bool = false

@export var target:CharacterBody3D
@export var SPEED:float = 3

var health = 3
@export var just_damaged:bool = false
@export var attacking:bool = false
enum STATES{
	MOVE,
	ATTACK,
	RUN_AWAY,
	IDLE
}

var state = STATES.ATTACK

func _physics_process(delta: float) -> void:
	if health <= 0:
		return
	velocity = Vector3.ZERO
	next_decision -= delta
	if next_decision <= 0:
		next_decision = next_decision_max
		make_decision()
	
	match state:
		STATES.MOVE:
			move_patrol(delta)
		STATES.ATTACK:
			attack(delta)
		STATES.RUN_AWAY:
			run_away(delta)
		STATES.IDLE:
			pass

	move_and_slide()

func move_patrol(_delta: float = 0):
	if patrol_points.size() <= 0:
		return
	if next_patrol_point && next_patrol_point.global_position.distance_to(global_position) < 1:
		pick_new_patrol_point = true

	if !next_patrol_point || pick_new_patrol_point:
		next_patrol_point = patrol_points.pick_random()
		pick_new_patrol_point = false
	
	navigation_agent.set_target_position(next_patrol_point.global_position)
	var next_path_position: Vector3 = navigation_agent.get_next_path_position()
	
	velocity.x = global_position.direction_to(next_path_position).x * SPEED
	velocity.z = global_position.direction_to(next_path_position).z * SPEED
	
	armature.look_at(Vector3(next_path_position.x,.4,next_path_position.z))
	
	#armature.rotate(Vector3.UP, TAU/2)
	#armature.global_rotation.z = next_patrol_point.rotation.y
	
	if global_position.distance_to(next_patrol_point.global_position) < 1:
		velocity = Vector3.ZERO

func take_damage(amt):
	health -= amt
	just_damaged = true
	if health <= 0:
		hurtbox.queue_free()
		collision_box.queue_free()

func attack(_delta):
	armature.look_at(Vector3(target.global_position.x, .4, target.global_position.z))
	
func run_away(_delta):
	var direction_to_run:Vector3 = global_position - target.global_position
	direction_to_run.y = .4
	direction_to_run.normalized()
	velocity.x = direction_to_run.x * SPEED
	velocity.z = direction_to_run.z * SPEED
	pass

func spawn_toof():
	var toof = TOOF.instantiate()
	world.add_child(toof)
	toof.global_position = global_position
	toof.look_at(target.global_position)
	toof.rotate_y(PI)
	print("toof rotation: " + str(toof.rotation))

func make_decision():
	velocity = Vector3.ZERO
	match state:
		STATES.MOVE:
			if global_position.distance_to(target.global_position) > 10:
				state = STATES.MOVE
				return
			state = STATES.ATTACK
			attacking = true
		STATES.ATTACK:
			state = STATES.MOVE

func _on_hurtbox_area_entered(area: Area3D) -> void:
	if area.is_in_group("hitbox") && area.is_in_group("player"):
		take_damage(area.damage())

func play_sound(sfx_enum:sfx):
	if sfx_player.playing:
		sfx_player.stop()
	sfx_player.stream = sfx_dictionary[sfx_enum]
	sfx_player.play()
