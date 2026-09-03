extends Control

# Paths to buttons
@onready var back_button = $back

func _ready():
	back_button.pressed.connect(_on_back_pressed)


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
