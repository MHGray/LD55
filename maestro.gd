extends Node

var music_location = "res://audio/music/"
var musics:Array[AudioStreamMP3]
var sfxs:Array[AudioStreamMP3]
var voices:Array[AudioStreamMP3]
@onready var main_menu_music_player: AudioStreamPlayer = $MainMenuMusicPlayer
@onready var music_player: AudioStreamPlayer = $MusicPlayer

func play_main_music():
	main_menu_music_player.stop()
	music_player.play()
