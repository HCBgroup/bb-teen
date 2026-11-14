class_name MovementComponent
extends Node

## MovementComponent handles top-down physics movement, dashing, and sprite animation updates.
## Attach this component to a CharacterBody2D.

@export var base_speed: float = 180.0
@export var dash_speed: float = 400.0
@export var dash_duration: float = 0.16
@export var dash_cooldown: float = 0.65

var is_dashing: bool = false
var dash_timer: float = 0.0
var dash_cooldown_timer: float = 0.0
var dash_dir: Vector2 = Vector2.DOWN
var facing_dir: Vector2 = Vector2.DOWN
var _wants_dash: bool = false

var body: CharacterBody2D
var animated_sprite: AnimatedSprite2D

func setup(p_body: CharacterBody2D, p_sprite: AnimatedSprite2D) -> void:
	body = p_body
	animated_sprite = p_sprite

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.is_pressed() and not event.is_echo():
		if event.keycode == KEY_SHIFT or event.physical_keycode == KEY_SHIFT:
			_wants_dash = true

func process_movement(delta: float) -> void:
	if body == null:
		return

	# Handle dash cooldown
	if dash_cooldown_timer > 0.0:
		dash_cooldown_timer -= delta

	# Handle active dash
	if is_dashing:
		dash_timer -= delta
		body.velocity = dash_dir * dash_speed
		if dash_timer <= 0.0:
			is_dashing = false
			body.velocity = Vector2.ZERO
		body.move_and_slide()
		return

	# 8-Directional Input
	var input_vector := Vector2.ZERO
	if Input.is_action_pressed("ui_right") or Input.is_physical_key_pressed(KEY_D) or Input.is_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_RIGHT):
		input_vector.x += 1.0
	if Input.is_action_pressed("ui_left") or Input.is_physical_key_pressed(KEY_A) or Input.is_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_LEFT):
		input_vector.x -= 1.0
	if Input.is_action_pressed("ui_down") or Input.is_physical_key_pressed(KEY_S) or Input.is_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN) or Input.is_key_pressed(KEY_DOWN):
		input_vector.y += 1.0
	if Input.is_action_pressed("ui_up") or Input.is_physical_key_pressed(KEY_W) or Input.is_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP) or Input.is_key_pressed(KEY_UP):
		input_vector.y -= 1.0

	if input_vector != Vector2.ZERO:
		input_vector = input_vector.normalized()
		facing_dir = input_vector
		body.velocity = input_vector * base_speed
		if animated_sprite:
			if animated_sprite.sprite_frames and animated_sprite.sprite_frames.has_animation("run"):
				if not animated_sprite.is_playing() or animated_sprite.animation != &"run":
					animated_sprite.play("run")
			else:
				if not animated_sprite.is_playing() or animated_sprite.animation != &"default":
					animated_sprite.play("default")
			if input_vector.x != 0.0:
				animated_sprite.flip_h = input_vector.x < 0.0
	else:
		body.velocity = Vector2.ZERO
		if animated_sprite:
			if not animated_sprite.is_playing() or animated_sprite.animation != &"default":
				animated_sprite.play("default")

	# Dash Trigger (Shift)
	if _wants_dash:
		_wants_dash = false
		if dash_cooldown_timer <= 0.0 and facing_dir != Vector2.ZERO:
			start_dash(facing_dir)

	body.move_and_slide()

func start_dash(dir: Vector2) -> void:
	is_dashing = true
	dash_timer = dash_duration
	dash_cooldown_timer = dash_cooldown
	dash_dir = dir if dir != Vector2.ZERO else Vector2.DOWN
	if animated_sprite:
		var tween = body.create_tween()
		tween.tween_property(animated_sprite, "modulate", Color(2.0, 2.0, 2.2, 0.7), 0.08)
		tween.tween_property(animated_sprite, "modulate", Color.WHITE, 0.1)
