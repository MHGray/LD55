extends Control

@onready var sfx: HSlider = $sfx
@onready var music: HSlider = $music

@onready var SFX_Bus = AudioServer.get_bus_index("SFX")
@onready var Music_Bus = AudioServer.get_bus_index("Music")
@onready var audio_stream_player: AudioStreamPlayer = $AudioStreamPlayer

func _ready() -> void:
	sfx.value = db_to_linear(AudioServer.get_bus_volume_db(SFX_Bus))
	music.value = db_to_linear(AudioServer.get_bus_volume_db(Music_Bus))

func _on_sfx_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(SFX_Bus, linear_to_db(value))
	audio_stream_player.play()
	
func _on_music_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(Music_Bus, linear_to_db(value))


func _on_instructions_pressed() -> void:
	$TextureRect4.visible = true
	$Instructions2.visible = true

func _on_okay_pressed() -> void:
	$TextureRect4.visible = false
	$Instructions2.visible = false
