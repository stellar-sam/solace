extends Control

# Paths to buttons
@onready var start_button = $VBoxContainer/start
@onready var info_button = $VBoxContainer/info
@onready var exit_button = $VBoxContainer/exit

func _ready():
	start_button.pressed.connect(_on_start_pressed)
	exit_button.pressed.connect(_on_exit_pressed)

func _on_start_pressed():
	# Replace with the path to your main game scene
	get_tree().change_scene_to_file("res://scenes/world.tscn")

func _on_info_pressed():
	# Replace with path to information/settings scene
	get_tree().change_scene_to_file("res://scenes/information.tscn")

func _on_exit_pressed():
	get_tree().quit()
