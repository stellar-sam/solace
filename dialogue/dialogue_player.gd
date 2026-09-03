extends Control

signal dialogue_finished
signal player_message_sent(message)

@export_file("*.json") var d_file

var dialogue = []
var current_dialogue_id = 0
var d_active = false

func _ready():
	$NinePatchRect.visible = false
	$LineEdit.visible = false
	
#func start():
#	if d_active:
#		return
#	d_active = true
#	$NinePatchRect.visible = true
#	dialogue = load_dialogue()
#	current_dialogue_id = -1
#	next_script()

func start_ai_dialogue(name, text):

	d_active = true

	$NinePatchRect.visible = true
	$LineEdit.visible = true
	$LineEdit.grab_focus()

	$NinePatchRect/Name.text = name
	$NinePatchRect/Text.text = text

func update_ai_text(text: String):

	$NinePatchRect/Text.text = text
	
	
func load_dialogue():
	var file = FileAccess.open("res://dialogue/npc1_dialogue.json", FileAccess.READ)
	var content = JSON.parse_string(file.get_as_text())
	return content
	
func _input(event):
	if !d_active:
		return

	if event.is_action_pressed("ui_cancel"):
		close_dialogue()
	#if event.is_action_pressed("ui_accept"):
	#	next_script()
	
#func next_script():
#	current_dialogue_id += 1
#	if current_dialogue_id >= len(dialogue):
#		d_active = false
#		$NinePatchRect.visible = false
#		$LineEdit.visible = false
#		$LineEdit.release_focus()
#		emit_signal("dialogue_finished")
#		return
#		
#	$NinePatchRect/Name.text = dialogue[current_dialogue_id]["name"]
#	$NinePatchRect/Text.text = dialogue[current_dialogue_id]["text"]

func close_dialogue():

	d_active = false

	$NinePatchRect.visible = false
	$LineEdit.visible = false

	$LineEdit.release_focus()

	emit_signal("dialogue_finished")

func _on_line_edit_text_submitted(text: String) -> void:
	if text.strip_edges() == "":
		return

	player_message_sent.emit(text)

	$LineEdit.clear()
