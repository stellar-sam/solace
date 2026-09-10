extends CharacterBody2D

const speed = 60
var current_state = IDLE

var dir = Vector2.RIGHT
var start_pos

var is_roaming = true
var is_chatting = false

var player
var player_in_chat_zone = false

var cat_choice = 0


enum {
	IDLE,
	NEW_DIR,
	MOVE
}

func _ready():
	randomize()
	start_pos = position
	
func _process(delta):
	var anim = $AnimatedSprite2D
	if current_state == 0 or current_state == 1:
		anim.flip_h = false
		match cat_choice:
			0:
				anim.play("idle")
			1:
				anim.play("play")
			2:
				anim.play("play2")
			3:
				anim.play("sleep")
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
		player_in_chat_zone = true
		



func _on_timer_timeout() -> void:
	$Timer.wait_time = choose([0.5, 1, 1.5])
	current_state = choose([IDLE, NEW_DIR, MOVE])
	
	if current_state == IDLE:
		cat_choice = choose([0, 1, 2, 3])




func _on_dialogue_dialogue_finished() -> void:
	is_chatting = false
	is_roaming = true
	
