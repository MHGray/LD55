extends CharacterBody3D

@onready var navigation_agent: NavigationAgent3D = $NavigationAgent3D
@onready var animation_tree: AnimationTree = $AnimationTree
@onready var armature: Node3D = $Armature
@onready var hitbox: Area3D = $Armature/hitbox
@onready var hurtbox: Area3D = $Hurtbox
@onready var collisionbox: CollisionShape3D = $Collisionbox
@onready var sfx_player: AudioStreamPlayer3D = $SFXPlayer

enum sfx {
	SFX_ATTACK,
	SFX_DAMAGE,
	SFX_DEATH,
}

var sfx_dictionary = {
	sfx.SFX_ATTACK: preload("res://audio/sfx/lizard_attack.mp3"),
	sfx.SFX_DAMAGE: preload("res://audio/sfx/lizard_damage.mp3"),
	sfx.SFX_DEATH: preload("res://audio/sfx/lizard_death.mp3")
}

@export var next_decision_max = 5
var next_decision = next_decision_max

@export var patrol_points: Array[Node3D]

var next_patrol_point
var pick_new_patrol_point:bool = false

enum STATES {
	IDLE,
	ATTACK,
	MOVE_PATROL
}
var state = STATES.IDLE

var health = 3

@export var SPEED = 5.0
const JUMP_VELOCITY = 4.5
@export var aggro_range = 7

@export var attacking: bool = false
@export var target: CharacterBody3D
@export var attack_cooldown_max = 3
var attack_cooldown = attack_cooldown_max

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

var damage = 1
@export var just_damaged:bool = false

func _ready():
	if target == null:
		print_rich("[wave amplitude=10][color=red]You forgot a target on an enemy[/color][/wave]")

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta
	if attacking:
		return
	if health <= 0:
		return
	next_decision -= delta
	if next_decision <= 0:
		next_decision = next_decision_max
		if global_position.distance_to(target.global_position) < aggro_range:
			state = STATES.ATTACK
		elif state == STATES.IDLE:
			state = STATES.MOVE_PATROL
		else:
			state = STATES.IDLE
	
	if state ==STATES.ATTACK:
		move_attack(delta)
	elif state == STATES.MOVE_PATROL:
		if global_position.distance_to(target.global_position) < aggro_range:
			state = STATES.ATTACK
		move_patrol(delta)
	else:
		if global_position.distance_to(target.global_position) < aggro_range:
			state = STATES.ATTACK
		idle(delta)
	animation_tree["parameters/StateMachine/Movement/blend_position"] = velocity.length()
	move_and_slide()

func attack():
	attacking = true
	attack_cooldown = attack_cooldown_max
	

func move_attack(delta):
	if global_position.distance_to(target.global_position) < 1 && attack_cooldown <= 0:
		attack()
	else:
		attack_cooldown -= delta
	
	navigation_agent.set_target_position(target.global_position)
	var next_path_position: Vector3 = navigation_agent.get_next_path_position()
	

	#global_position.direction_to(next_path_position)
	velocity.x = global_position.direction_to(next_path_position).x * SPEED
	velocity.z = global_position.direction_to(next_path_position).z * SPEED
	
	armature.look_at(Vector3(target.global_position.x,1,target.global_position.z))
	
	armature.rotate(Vector3.UP, TAU/2)
	armature.global_rotation.z = target.rotation.y
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.

	if global_position.distance_to(target.global_position) < 1:
		velocity = Vector3.ZERO

func move_patrol(_delta: float = 0):
	if patrol_points.size() <= 0:
		return
	if next_patrol_point == null || pick_new_patrol_point:
		next_patrol_point = patrol_points.pick_random()
		pick_new_patrol_point = false
		navigation_agent.target_reached.connect(func(): 
			pick_new_patrol_point = true
			return 
			, CONNECT_ONE_SHOT)
	
	navigation_agent.set_target_position(next_patrol_point.global_position)
	var next_path_position: Vector3 = navigation_agent.get_next_path_position()
	
	velocity.x = global_position.direction_to(next_path_position).x * SPEED
	velocity.z = global_position.direction_to(next_path_position).z * SPEED
	
	armature.look_at(Vector3(next_patrol_point.global_position.x,1,next_patrol_point.global_position.z))
	
	armature.rotate(Vector3.UP, TAU/2)
	armature.global_rotation.z = next_patrol_point.rotation.y
	
	if global_position.distance_to(next_patrol_point.global_position) < 1:
		velocity = Vector3.ZERO

func idle(_delta:float = 0):
	velocity = Vector3.ZERO

func _on_hurtbox_area_entered(area: Area3D) -> void:
	if area.is_in_group("hitbox") && area.is_in_group("player"):
		take_damage(area.damage())

func play_sound(sfx_enum:sfx):
	if sfx_player.playing:
		sfx_player.stop()
	sfx_player.stream = sfx_dictionary[sfx_enum]
	sfx_player.play()

func take_damage(amt):
	health -= amt
	just_damaged = true
	if health <= 0:
		hitbox.queue_free()
		hurtbox.queue_free()
		collisionbox.queue_free()
