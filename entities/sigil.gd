extends Node3D

@onready var animation_player: AnimationPlayer = $AnimationPlayer
const SIGIL_ANIMATIONS: AnimationLibrary = preload("res://entities/sigilAnimations.tres") as AnimationLibrary
@onready var area_3d: Area3D = $Area3D
@onready var fire: GPUParticles3D = $Fire
@onready var audio_stream_player_3d: AudioStreamPlayer3D = $AudioStreamPlayer3D
@onready var chanting_player: AudioStreamPlayer3D = $Chanting

enum sfx {
	SFX_DETONATE_1,
	SFX_DETONATE_2,
	SFX_DETONATE_3,
	SFX_DETONATE_4,
	SFX_DETONATE_5,
}

var sfx_dictionary = {
	sfx.SFX_DETONATE_1: preload("res://audio/sfx/explosion1.mp3"),
	sfx.SFX_DETONATE_2 : preload("res://audio/sfx/explosion2.mp3"),
	sfx.SFX_DETONATE_3 : preload("res://audio/sfx/explosion3.mp3"),
	sfx.SFX_DETONATE_4 : preload("res://audio/sfx/explosion4.mp3"),
	sfx.SFX_DETONATE_5 : preload("res://audio/sfx/explosion5.mp3"),
}

var charge_amount:int = 1
var blast_radius: int = 3
var damage:int = 1

func _ready() -> void:
	area_3d.monitorable = false
	fire.emitting = false
	damage = charge_amount

func detonate():
	print("Detonate_" + str(charge_amount))
	animation_player.play("sigilAnimations/Detonate_" + str(charge_amount))
	audio_stream_player_3d.stream = sfx_dictionary[charge_amount - 1]
	audio_stream_player_3d.play()

func kill_me():
	print("Dying")
	queue_free()
