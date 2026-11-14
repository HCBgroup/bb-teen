class_name MotivationCoin
extends Area2D

## Collectible Motivation / Focus Coin in the Morning Dash runner level.

@export var score_value: int = 10
var _collected: bool = false

@onready var anim_sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	collision_layer = 0
	collision_mask = 1 # Player layer
	body_entered.connect(_on_body_entered)

	# Gentle floating bob animation
	var tw = create_tween().set_loops()
	tw.tween_property(self, "position:y", position.y - 6.0, 0.6).set_trans(Tween.TRANS_SINE)
	tw.tween_property(self, "position:y", position.y + 6.0, 0.6).set_trans(Tween.TRANS_SINE)

func _on_body_entered(body: Node2D) -> void:
	if _collected:
		return
	if body is CharacterBody2D or body.has_method("add_motivation"):
		_collect(body)

func _collect(player_node: Node2D) -> void:
	_collected = true
	set_deferred("monitoring", false)

	# Play retro coin SFX
	var audio_mgr = get_node_or_null("/root/AudioManager")
	if audio_mgr and audio_mgr.has_method("play_sfx") and audio_mgr.snd_coin:
		var pitch = randf_range(0.95, 1.25)
		audio_mgr.play_sfx(audio_mgr.snd_coin, pitch, -3.0)

	# Notify player or level
	if player_node.has_method("add_motivation"):
		player_node.add_motivation(score_value)
	var walkway = get_tree().current_scene
	if walkway and walkway.has_method("on_coin_collected"):
		walkway.on_coin_collected(score_value)

	# Floating text effect: "+10 Focus!"
	var float_lbl = Label.new()
	float_lbl.text = "+%d Motivation!" % score_value
	float_lbl.add_theme_font_size_override("font_size", 12)
	float_lbl.add_theme_color_override("font_color", Color(1.0, 0.9, 0.2))
	float_lbl.add_theme_color_override("font_shadow_color", Color.BLACK)
	float_lbl.position = Vector2(-45, -25)
	add_child(float_lbl)

	var tw = create_tween().set_parallel(true)
	tw.tween_property(float_lbl, "position:y", float_lbl.position.y - 30.0, 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(float_lbl, "modulate:a", 0.0, 0.5)
	if anim_sprite:
		tw.tween_property(anim_sprite, "scale", anim_sprite.scale * 1.5, 0.3)
		tw.tween_property(anim_sprite, "modulate:a", 0.0, 0.3)

	await tw.finished
	queue_free()
