class_name PlatformerPlayer
extends CharacterBody2D

## 2D Platformer Character controller for Arun during the Morning Dash runner level.
## Features snappy variable jump, coyote time, jump buffering, and respawn tracking.

signal respawn_triggered(quote: String)

@export var move_speed: float = 260.0
@export var jump_velocity: float = -490.0
@export var base_gravity: float = 1100.0
@export var fall_gravity: float = 1600.0

var motivation_score: int = 0
var coins_collected: int = 0

var last_safe_checkpoint: Vector2 = Vector2(120, 510)
var is_respawning: bool = false

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var camera: Camera2D = $Camera2D

# Coyote time & jump buffer
var _coyote_timer: float = 0.0
var _jump_buffer_timer: float = 0.0

var motivational_quotes: Array[String] = [
	"\"Falling down is just part of the journey. Take a breath and Bounce Back!\"",
	"\"A stumble is not the end of the road. Shake it off and leap again!\"",
	"\"Resilience isn't never falling — it's rising every single time you do.\"",
	"\"Every jump gets you closer. You've got this, Arun!\"",
	"\"Pressure doesn't break who you are — how you Bounce Back does!\"",
	"\"Mistakes are proof you are trying. Head up, let's go again!\""
]

func _ready() -> void:
	motion_mode = CharacterBody2D.MOTION_MODE_GROUNDED
	collision_layer = 1
	collision_mask = 2
	z_index = 10

	if sprite:
		sprite.play("idle")

func _physics_process(delta: float) -> void:
	if is_respawning:
		return

	# Fall into pit check (below level floor)
	if global_position.y > 690.0:
		trigger_respawn()
		return

	# Ground tracking & checkpoint update
	if is_on_floor():
		_coyote_timer = 0.15 # 150ms coyote time
		# Update last safe ground position
		if global_position.y < 540.0:
			last_safe_checkpoint = global_position
	else:
		_coyote_timer -= delta
		# Dynamic gravity: fall faster for snappy, non-floaty platforming
		var grav = base_gravity
		if velocity.y > 0.0 or not (Input.is_action_pressed("ui_up") or Input.is_physical_key_pressed(KEY_SPACE) or Input.is_physical_key_pressed(KEY_W)):
			grav = fall_gravity
		velocity.y += grav * delta

	# Jump buffer timer
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
			audio_mgr.play_sfx(audio_mgr.snd_jump, 1.15, -4.0)

	# Horizontal Movement (A/D or Arrows)
	var direction := 0.0
	if Input.is_action_pressed("ui_right") or Input.is_physical_key_pressed(KEY_D):
		direction += 1.0
	if Input.is_action_pressed("ui_left") or Input.is_physical_key_pressed(KEY_A):
		direction -= 1.0

	if direction != 0.0:
		velocity.x = move_toward(velocity.x, direction * move_speed, 2200.0 * delta)
		if sprite:
			sprite.flip_h = (direction < 0.0)
	else:
		velocity.x = move_toward(velocity.x, 0.0, 1800.0 * delta)

	move_and_slide()

	# Update Animations
	_update_animation(direction)

func _update_animation(direction: float) -> void:
	if not sprite or is_respawning:
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

func trigger_respawn() -> void:
	if is_respawning:
		return
	is_respawning = true
	velocity = Vector2.ZERO

	# Play bounce/fall sound
	var audio_mgr = get_node_or_null("/root/AudioManager")
	if audio_mgr and audio_mgr.has_method("play_sfx") and audio_mgr.snd_hurt:
		audio_mgr.play_sfx(audio_mgr.snd_hurt, 1.1, -4.0)

	# Pick a random motivational quote
	var quote = motivational_quotes[randi() % motivational_quotes.size()]
	respawn_triggered.emit(quote)

	# Notify HUD level controller
	var walkway = get_tree().current_scene
	if walkway and walkway.has_method("show_respawn_card"):
		walkway.show_respawn_card(quote)

	# Teleport back to safe ground with brief pause
	await get_tree().create_timer(1.2).timeout

	global_position = last_safe_checkpoint + Vector2(0, -15)
	velocity = Vector2.ZERO
	is_respawning = false

	# Brief invincibility / encouragement flash
	if sprite:
		var tw = create_tween()
		tw.tween_property(sprite, "modulate", Color(1.0, 0.85, 0.3), 0.15)
		tw.tween_property(sprite, "modulate", Color.WHITE, 0.15)
		tw.tween_property(sprite, "modulate", Color(1.0, 0.85, 0.3), 0.15)
		tw.tween_property(sprite, "modulate", Color.WHITE, 0.15)

func add_motivation(amount: int) -> void:
	motivation_score += amount
	coins_collected += 1
