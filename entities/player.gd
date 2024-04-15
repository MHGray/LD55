extends CharacterBody3D

const SIGIL = preload("res://entities/sigil.tscn")
@export var world: Node3D

enum sfx {
	SFX_CHARGING,
	SFX_DAMAGE,
	SFX_DEATH,
	SFX_DETONATE,
	SFX_SET
}

var sfx_dictionary = {
	sfx.SFX_CHARGING: preload("res://audio/sfx/charging.mp3"),
	sfx.SFX_DAMAGE : preload("res://audio/sfx/damage.mp3"),
	sfx.SFX_DEATH : preload("res://audio/sfx/death.mp3"),
	sfx.SFX_DETONATE : preload("res://audio/sfx/detonate.mp3"),
	sfx.SFX_SET : preload("res://audio/sfx/set.mp3")
}

@onready var armature: Node3D = $Armature
@onready var animation_tree: AnimationTree = $AnimationTree
@onready var spring_arm_pivot: Node3D = $SpringArm3DPivot
@onready var spring_arm_3d: SpringArm3D = $SpringArm3DPivot/SpringArm3D
@onready var camera_3d: Camera3D = $SpringArm3DPivot/SpringArm3D/Camera3D
@onready var fire: GPUParticles3D = $Fire
@onready var health_label: RichTextLabel = $Control/HealthLabel
@onready var death_fade_out: TextureRect = $"Control/Death Fade Out"
@onready var sfx_player: AudioStreamPlayer = $AudioStreamPlayer

@export var SPEED:float = 5
@export var JUMP_VELOCITY:float = 4.5
@export var MOUSE_SENSITIVITY:float = 5
@export var TURN_SPEED:float = 5

var detonating_cooldown:float = 2
var think_about_death_time_max:float = 4
var think_about_death_time:float = think_about_death_time_max

var health :int:
	get: 
		return health
	set(value):
		health = value
		health_changed.emit()

#sigils
var sigils = []

#summon stats		
@export var charges:int = 5
@export var blast_radius: float = 3
@export var summon_speed: float = 3

var using_charges: int = 1
@export var time_til_next_charge_max:float = .66
var time_til_next_charge:float = time_til_next_charge_max

#states
var summoning:bool = false
var just_damaged: bool = false
var charging: bool = false
var done_charging: bool = true
var detonating: bool = false

signal charge_increased
signal detonated
signal health_changed

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready() -> void:
	Maestro.play_main_music()
	print(sfx_dictionary[sfx.SFX_CHARGING])
	health = 5
	animation_tree.active = true
	health_label.text  = "Health: " + str(health)

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta
	if health <= 0 or velocity.y < -20:
		if think_about_death_time == think_about_death_time_max:
			play_sound(sfx.SFX_DEATH)
		think_about_death_time-=delta
		death_fade_out.self_modulate.a = (think_about_death_time_max - think_about_death_time) / think_about_death_time_max
		if think_about_death_time <= 0:
			get_tree().reload_current_scene()
			return
		velocity.x = 0
		velocity.z = 0
		move_and_slide()
		return

	if summoning:
		handle_summoning(delta)
		return
	elif detonating: 
		handle_detonating(delta)
		return

	# Handle Summon
	if Input.is_action_just_pressed("cross") and is_on_floor() and not summoning:
		summoning = true

	if Input.is_action_just_pressed("square") and is_on_floor() and detonating_cooldown <= 0:
		detonating = true
		detonating_cooldown = 1
	detonating_cooldown -= delta
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir := Input.get_vector("right", "left", "down", "up")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
		
		#change facing direction
	if direction:
		var target_angle = Quaternion(Vector3(0, 1 , 0), atan2(velocity.x,velocity.z))
		var q_rotation = Quaternion(armature.basis)
		var rotate_q = q_rotation.slerp(target_angle, TURN_SPEED * delta)
		armature.basis = Basis(rotate_q)
	
	animation_tree["parameters/StateMachine/Movement/blend_position"] = velocity.length()
	just_damaged = false
	move_and_slide()

func handle_summoning(delta: float) -> void:
	velocity.x = 0
	velocity.z = 0
	
	if Input.is_action_pressed("cross") and charging:
		time_til_next_charge -= delta
		if time_til_next_charge <= 0 :
			print("time to charge")
			time_til_next_charge = time_til_next_charge_max
			if using_charges < charges:
				print("charging")
				using_charges += 1
				charge_increased.emit()
	elif charging:
		charging = false
		done_charging = true
	# Charging gets slower the longer you charge?
	move_and_slide()
	
func handle_detonating(_delta:float) -> void:
	pass

func summon_flame() -> void:
	if summoning == false:return
	summoning = false
	var sigil = SIGIL.instantiate()
	sigil.position = global_position
	sigil.charge_amount = using_charges
	detonated.connect(sigil.detonate, CONNECT_ONE_SHOT)
	
	sigils.append(sigil)
	world.add_child(sigil)
	using_charges = 1

func clean_sigils_array():
	sigils = sigils.filter(func(sig): return sig != null)

func detonate() -> void:
	detonating = false
	detonated.emit()

func start_charging() -> void:
	charging = true

func _on_charge_increased() -> void:
	fire.emitting = true

func _on_hurtbox_area_entered(area: Area3D) -> void:
	if area.is_in_group("hitbox"):
		take_damage(area.damage())
		
func take_damage(amt:int = 1):
	stop_sound()
	just_damaged = true
	charging = false
	summoning=false
	using_charges = 1
	health -= amt
	if health > 0:
		play_sound(sfx.SFX_DAMAGE)

func _on_health_changed() -> void:
	health_label.text = "health: " + str(health)

func play_sound(sfx_enum:sfx):
	if sfx_player.playing:
		sfx_player.stop()
	sfx_player.stream = sfx_dictionary[sfx_enum]
	sfx_player.play()

func stop_sound():
	sfx_player.stop()
