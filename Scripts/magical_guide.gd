class_name MagicalGuide
extends Node2D

## Celestial guide that manifests during Arun's moment of acute exam panic.
## Swoops down from above, hovers with gentle bobbing, and delivers the Bounce Back wisdom.

signal arrival_finished

@onready var sprite: Sprite2D = $Sprite2D

var _is_hovering: bool = false
var _time: float = 0.0
var _base_y: float = 0.0

func _ready() -> void:
	visible = false
	if sprite:
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

func _process(delta: float) -> void:
	if _is_hovering and sprite:
		_time += delta
		sprite.position.y = _base_y + sin(_time * 4.0) * 5.0

func fly_in(target_pos: Vector2) -> void:
	visible = true
	global_position = Vector2(target_pos.x - 30.0, target_pos.y - 280.0)
	modulate.a = 0.0
	scale = Vector2(0.3, 0.3)

	var tween = create_tween().set_parallel(true)
	tween.tween_property(self, "global_position", target_pos, 1.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 1.0, 0.6)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 1.0).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)

	await tween.finished
	_base_y = sprite.position.y
	_is_hovering = true
	arrival_finished.emit()

func pulse_wisdom() -> void:
	if sprite:
		var flash = create_tween()
		flash.tween_property(sprite, "modulate", Color(2.5, 2.3, 1.2, 1.0), 0.15)
		flash.tween_property(sprite, "modulate", Color.WHITE, 0.25)
