extends Control

func _ready() -> void:
	pass
	
func _process(delta: float) -> void:
	volume_update()
	
func volume_update():
	AudioGlobal.music_volume = $MusicScrollBar.value
