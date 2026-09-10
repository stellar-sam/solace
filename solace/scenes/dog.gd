extends CharacterBody2D

const speed = 40
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

func _process(delta):
	var anim = $AnimatedSprite2D

	if current_state == IDLE or current_state == NEW_DIR:
		anim.flip_h = false
		anim.play("idle")

	elif current_state == MOVE and !is_chatting:
		if dir.x == -1:
			anim.flip_h = true
			anim.play("walk_side")
		elif dir.x == 1:
			anim.flip_h = false
			anim.play("walk_side")




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
				dir = choose([Vector2.RIGHT, Vector2.LEFT])
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
