extends CharacterBody2D

const speed = 100
var current_dir = "none"
var server_pid

func _ready():
	$AnimatedSprite2D.play("idle_down")

func _physics_process(delta):
	player_movement(delta)
	
func player_movement(delta):
	if get_viewport().gui_get_focus_owner() != null:
		return
	if Input.is_action_pressed("ui_right") or Input.is_key_label_pressed(KEY_D):
		current_dir = "right"
		play_anim(1)
		velocity.x = speed
		velocity.y = 0
	elif Input.is_action_pressed("ui_left") or Input.is_key_label_pressed(KEY_A):
		current_dir = "left"
		play_anim(1)
		velocity.x = -speed
		velocity.y = 0
	elif Input.is_action_pressed("ui_down") or Input.is_key_label_pressed(KEY_S):
		current_dir = "down"
		play_anim(1)
		velocity.x = 0
		velocity.y = speed
	elif Input.is_action_pressed("ui_up") or Input.is_key_label_pressed(KEY_W):
		current_dir = "up"
		play_anim(1)
		velocity.x = 0
		velocity.y = -speed
	else:
		play_anim(0)
		velocity.x = 0
		velocity.y = 0
		
	move_and_slide()

func play_anim(movement):
	var dir = current_dir
	var anim = $AnimatedSprite2D
	
	if dir == "right":
		anim.flip_h = false
		if movement == 1:
			anim.play("walk_side")
		elif movement == 0:
			anim.play("idle_side")
	elif dir == "left":
		anim.flip_h = true
		if movement == 1:
			anim.play("walk_side")
		elif movement == 0:
			anim.play("idle_side")
	elif dir == "up":
		anim.flip_h = false
		if movement == 1:
			anim.play("walk_up")
		elif movement == 0:
			anim.play("idle_up")
	elif dir == "down":
		anim.flip_h = false
		if movement == 1:
			anim.play("walk_down")
		elif movement == 0:
			anim.play("idle_down")

func player():
	pass
