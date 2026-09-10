extends Node

@export var bg_music_player: AudioStreamPlayer


func _ready() -> void:
	bg_music_player.play()
	
func _process(delta: float) -> void:
	update_volume()
	
func update_volume():
	var bgmusic_index = AudioServer.get_bus_index("music")
	AudioServer.set_bus_volume_db(bgmusic_index, AudioGlobal.music_volume)
