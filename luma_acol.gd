extends CharacterBody2D

@export var npc_id = "luma_acol"
@onready var http = $HTTPRequest

const speed = 30
var current_state = IDLE

var dir = Vector2.RIGHT
var start_pos

var is_roaming = true
var is_chatting = false

var player
var player_in_chat_zone = false


enum {
	IDLE,
	NEW_DIR,
	MOVE
}

func _ready():
	randomize()
	start_pos = position

	http.request_completed.connect(_on_request_completed)
	$Dialogue.player_message_sent.connect(_on_player_message)
	
	
func _on_player_message(message: String):

	send_to_npc(message)
	
func send_to_npc(message: String):

	var body = {
		"npc": npc_id,
		"message": message
	}

	var headers = [
		"Content-Type: application/json"
	]

	var error = http.request(
		"http://127.0.0.1:5000/talk",
		headers,
		HTTPClient.METHOD_POST,
		JSON.stringify(body)
	)

	if error != OK:
		print("Request failed")
		
func _on_request_completed(result, response_code, headers, body):

	var text = body.get_string_from_utf8()
	#print("RAW RESPONSE:", text)

	var response = JSON.parse_string(text)

	#print("PARSED:", response)

	if response == null:
		print("JSON PARSE FAILED")
		return

	if !response.has("reply"):
		print("NO REPLY KEY")
		return

	var reply = response["reply"]

	$Dialogue.update_ai_text(reply)

func _process(delta):
	var anim = $AnimatedSprite2D
	if current_state == 0 or current_state == 1:
		anim.flip_h = false
		anim.play("idle")
	elif current_state == 2 and !is_chatting:
		if dir.x == -1:
			anim.flip_h = false
			anim.play("walk_side")
		if dir.x == 1:
			anim.flip_h = true
			anim.play("walk_side")
		if dir.y == -1:
			anim.flip_h = false
			anim.play("walk_up")
		if dir.y == 1:
			anim.flip_h = false
			anim.play("walk_down")
		
	if (Input.is_action_just_pressed("chat") and player_in_chat_zone):
		$Dialogue.start_ai_dialogue("Lalita", "...")
		is_roaming = false
		is_chatting = true
		anim.flip_h = false
		anim.play("idle")
	
				
func choose(array):
	array.shuffle()
	return array.front()
	
func move(delta):
	if !is_chatting:
		velocity = dir * speed
	else:
		velocity = Vector2.ZERO
		
	move_and_slide()

func _physics_process(delta):
	if is_roaming:
		match current_state:
			IDLE:
				velocity = Vector2.ZERO
			NEW_DIR:
				dir = choose([Vector2.RIGHT, Vector2.UP, Vector2.LEFT, Vector2.DOWN])
			MOVE:
				move(delta)


		
	


func _on_chat_detection_area_body_entered(body: Node2D) -> void:
	if body.has_method("player"):
		player = body
		player_in_chat_zone = true


func _on_chat_detection_area_body_exited(body: Node2D) -> void:
	if body.has_method("player"):
		player_in_chat_zone = false
		



func _on_timer_timeout() -> void:
	$Timer.wait_time = choose([0.5, 1, 1.5])
	current_state = choose([IDLE, NEW_DIR, MOVE])




func _on_dialogue_dialogue_finished() -> void:
	is_chatting = false
	is_roaming = true
	
