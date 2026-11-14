class_name PlatformerPlayer
extends CharacterBody2D

## 2D Platformer Character controller for Arun during the Morning Dash runner level.

@export var move_speed: float = 240.0
@export var jump_velocity: float = -460.0
@export var gravity: float = 980.0

var motivation_score: int = 0
var coins_collected: int = 0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var camera: Camera2D = $Camera2D

# Coyote time & jump buffer for responsive feel
var _coyote_timer: float = 0.0
var _jump_buffer_timer: float = 0.0

func _ready() -> void:
	motion_mode = CharacterBody2D.MOTION_MODE_GROUNDED
	collision_layer = 1
	collision_mask = 2

	if sprite:
		sprite.play("idle")

func _physics_process(delta: float) -> void:
	# Apply Gravity
	if not is_on_floor():
		velocity.y += gravity * delta
		_coyote_timer -= delta
	else:
		_coyote_timer = 0.12 # 120ms coyote time

	# Jump buffer
	if _jump_buffer_timer > 0.0:
		_jump_buffer_timer -= delta

	if Input.is_action_just_pressed("ui_up") or Input.is_action_just_pressed("ui_accept") or Input.is_physical_key_pressed(KEY_SPACE) or Input.is_physical_key_pressed(KEY_W):
		_jump_buffer_timer = 0.15

	# Execute Jump
	if _jump_buffer_timer > 0.0 and _coyote_timer > 0.0:
		velocity.y = jump_velocity
		_jump_buffer_timer = 0.0
		_coyote_timer = 0.0

		var audio_mgr = get_node_or_null("/root/AudioManager")
		if audio_mgr and audio_mgr.has_method("play_sfx") and audio_mgr.snd_jump:
			audio_mgr.play_sfx(audio_mgr.snd_jump, 1.1, -4.0)

	# Horizontal Movement
	var direction := 0.0
	if Input.is_action_pressed("ui_right") or Input.is_physical_key_pressed(KEY_D):
		direction += 1.0
	if Input.is_action_pressed("ui_left") or Input.is_physical_key_pressed(KEY_A):
		direction -= 1.0

	if direction != 0.0:
		velocity.x = move_toward(velocity.x, direction * move_speed, 1800.0 * delta)
		if sprite:
			sprite.flip_h = (direction < 0.0)
	else:
		velocity.x = move_toward(velocity.x, 0.0, 1600.0 * delta)

	move_and_slide()

	# Update Animations
	_update_animation(direction)

func _update_animation(direction: float) -> void:
	if not sprite:
		return

	if not is_on_floor():
		if velocity.y < 0.0:
			if sprite.sprite_frames.has_animation("jump_up"):
				sprite.play("jump_up")
		else:
			if sprite.sprite_frames.has_animation("jump_fall"):
				sprite.play("jump_fall")
	else:
		if absf(velocity.x) > 10.0:
			sprite.play("run")
		else:
			sprite.play("idle")

func add_motivation(amount: int) -> void:
	motivation_score += amount
	coins_collected += 1
