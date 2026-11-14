class_name MarksheetDodgePlayer
extends CharacterBody2D

signal health_changed(current_hp: int, max_hp: int)
signal player_hit(damage: int)
signal player_died()
signal attack_performed()

@export var move_speed: float = 300.0
@export var max_health: int = 5

var current_health: int = 5
var is_attacking: bool = false
var is_invulnerable: bool = false
var is_active: bool = true
var facing_direction: Vector2 = Vector2.DOWN

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var attack_hitbox: Area2D = $AttackHitbox
@onready var attack_shape: CollisionShape2D = $AttackHitbox/CollisionShape2D
@onready var body_shape: CollisionShape2D = $CollisionShape2D
@onready var invulnerability_timer: Timer = $InvulnerabilityTimer

func _ready() -> void:
	add_to_group("player")
	current_health = max_health
	attack_hitbox.monitoring = false
	invulnerability_timer.timeout.connect(_on_invulnerability_timeout)
	emit_signal("health_changed", current_health, max_health)

func reset(initial_pos: Vector2, new_max_health: int = 5) -> void:
	global_position = initial_pos
	max_health = new_max_health
	current_health = max_health
	is_attacking = false
	is_invulnerable = false
	is_active = true
	facing_direction = Vector2.DOWN
	velocity = Vector2.ZERO
	attack_hitbox.monitoring = false
	invulnerability_timer.stop()
	animated_sprite.modulate = Color.WHITE
	animated_sprite.play("idle_down")
	emit_signal("health_changed", current_health, max_health)

func set_active(active: bool) -> void:
	is_active = active
	if not active:
		velocity = Vector2.ZERO
		is_attacking = false
		attack_hitbox.monitoring = false
		animated_sprite.play("idle_down")

func _physics_process(_delta: float) -> void:
	if not is_active or current_health <= 0:
		return

	var attack_pressed := false
	if InputMap.has_action("attack") and Input.is_action_just_pressed("attack"):
		attack_pressed = true
	elif Input.is_action_just_pressed("ui_accept") or Input.is_physical_key_pressed(KEY_SPACE) or Input.is_physical_key_pressed(KEY_Z):
		attack_pressed = true

	if attack_pressed and not is_attacking:
		start_attack()

	if is_attacking:
		velocity = Vector2.ZERO
		return

	process_movement()
	process_animation()
	move_and_slide()

func process_movement() -> void:
	var direction: Vector2 = Vector2.ZERO
	if InputMap.has_action("left") and InputMap.has_action("right") and InputMap.has_action("up") and InputMap.has_action("down"):
		direction = Input.get_vector("left", "right", "up", "down")
	else:
		direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")

	if direction == Vector2.ZERO:
		if Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT):
			direction.x -= 1.0
		if Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT):
			direction.x += 1.0
		if Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP):
			direction.y -= 1.0
		if Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN):
			direction.y += 1.0
		if direction != Vector2.ZERO:
			direction = direction.normalized()

	if direction != Vector2.ZERO:
		velocity = direction * move_speed
		if abs(direction.x) >= abs(direction.y):
			facing_direction = Vector2(sign(direction.x), 0)
		else:
			facing_direction = Vector2(0, sign(direction.y))
	else:
		velocity = Vector2.ZERO

func process_animation() -> void:
	if is_attacking:
		return
	if velocity != Vector2.ZERO:
		play_facing_animation("run")
	else:
		play_facing_animation("idle")

func play_facing_animation(prefix: String) -> void:
	if facing_direction.x != 0:
		animated_sprite.play(prefix + "_right")
		animated_sprite.flip_h = facing_direction.x < 0
	elif facing_direction.y < 0:
		animated_sprite.play(prefix + "_up")
		animated_sprite.flip_h = false
	else:
		animated_sprite.play(prefix + "_down")
		animated_sprite.flip_h = false

func start_attack() -> void:
	is_attacking = true
	attack_hitbox.monitoring = true
	update_attack_hitbox_position()
	play_facing_animation("attack")
	emit_signal("attack_performed")
	
	for area: Area2D in attack_hitbox.get_overlapping_areas():
		if area.has_method("shred"):
			area.shred()

func update_attack_hitbox_position() -> void:
	var reach: float = 36.0
	if facing_direction.x > 0:
		attack_hitbox.position = Vector2(reach, 0)
	elif facing_direction.x < 0:
		attack_hitbox.position = Vector2(-reach, 0)
	elif facing_direction.y < 0:
		attack_hitbox.position = Vector2(0, -reach)
	else:
		attack_hitbox.position = Vector2(0, reach)

func take_damage(amount: int) -> void:
	if is_invulnerable or current_health <= 0 or not is_active:
		return
		
	current_health = max(0, current_health - amount)
	emit_signal("health_changed", current_health, max_health)
	emit_signal("player_hit", amount)
	
	if current_health <= 0:
		emit_signal("player_died")
		is_attacking = false
		attack_hitbox.monitoring = false
		var death_tween: Tween = create_tween()
		death_tween.tween_property(animated_sprite, "modulate", Color(1.0, 0.2, 0.2, 0.4), 0.3)
	else:
		is_invulnerable = true
		invulnerability_timer.start(0.8)
		flash_flicker()

func flash_flicker() -> void:
	var tween: Tween = create_tween().set_loops(4)
	tween.tween_property(animated_sprite, "modulate:a", 0.3, 0.1)
	tween.tween_property(animated_sprite, "modulate:a", 1.0, 0.1)

func _on_invulnerability_timeout() -> void:
	is_invulnerable = false
	animated_sprite.modulate = Color.WHITE

func _on_animated_sprite_2d_animation_finished() -> void:
	if is_attacking:
		is_attacking = false
		attack_hitbox.monitoring = false

func _on_attack_hitbox_area_entered(area: Area2D) -> void:
	if is_attacking and area.has_method("shred"):
		area.shred()
