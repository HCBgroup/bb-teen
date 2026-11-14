class_name Marksheet
extends Area2D

signal paper_shredded(points: int, global_pos: Vector2)
signal paper_hit_player(penalty: int, global_pos: Vector2)
signal paper_escaped()

@export var base_speed: float = 180.0
@export var rotation_speed: float = 35.0
@export var drift_amplitude: float = 40.0
@export var drift_frequency: float = 2.0
@export var bottom_boundary: float = 780.0

var fall_speed: float = 180.0
var time_alive: float = 0.0
var initial_x: float = 0.0
var is_destroyed: bool = false

@onready var sprite: Sprite2D = $PaperSprite
@onready var collision_shape: CollisionShape2D = $PaperCollisionShape
@onready var grade_label: Label = $GradeLabel

const GRADE_STAMPS: Array[String] = ["F", "D-", "0/100", "FAIL", "F-", "RETEST"]

func _ready() -> void:
	add_to_group("marksheet")
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.randomize()
	
	fall_speed = rng.randf_range(base_speed * 0.85, base_speed * 1.35)
	rotation_speed = rng.randf_range(-40.0, 40.0)
	drift_amplitude = rng.randf_range(20.0, 50.0)
	drift_frequency = rng.randf_range(1.5, 3.0)
	initial_x = position.x
	
	if grade_label:
		grade_label.text = GRADE_STAMPS[rng.randi() % GRADE_STAMPS.size()]
		grade_label.rotation_degrees = rng.randf_range(-15.0, 15.0)

func _physics_process(delta: float) -> void:
	if is_destroyed:
		return
		
	time_alive += delta
	var sway: float = sin(time_alive * drift_frequency) * drift_amplitude
	position.x = initial_x + sway
	position.y += fall_speed * delta
	rotation_degrees += rotation_speed * delta
	
	if position.y > bottom_boundary:
		emit_signal("paper_escaped")
		queue_free()

func shred() -> void:
	if is_destroyed:
		return
	is_destroyed = true
	emit_signal("paper_shredded", 10, global_position)
	
	collision_shape.set_deferred("disabled", true)
	var tween: Tween = create_tween().set_parallel(true)
	tween.tween_property(sprite, "scale", sprite.scale * 1.3, 0.15)
	tween.tween_property(sprite, "modulate:a", 0.0, 0.15)
	if grade_label:
		tween.tween_property(grade_label, "modulate:a", 0.0, 0.15)
	tween.chain().tween_callback(queue_free)

func _on_body_entered(body: Node2D) -> void:
	if is_destroyed:
		return
	if body.is_in_group("player"):
		is_destroyed = true
		collision_shape.set_deferred("disabled", true)
		
		if body.has_method("take_damage"):
			body.take_damage(1)
		emit_signal("paper_hit_player", 5, global_position)
		
		var tween: Tween = create_tween()
		tween.tween_property(self, "modulate", Color(1.0, 0.2, 0.2, 0.0), 0.15)
		tween.tween_callback(queue_free)
