class_name FloatingText
extends Label

func setup(display_text: String, start_pos: Vector2, text_color: Color = Color.WHITE) -> void:
	text = display_text
	global_position = start_pos
	modulate = text_color
	z_index = 100
	
	add_theme_font_size_override("font_size", 22)
	
	var tween: Tween = create_tween().set_parallel(true)
	tween.tween_property(self, "global_position:y", start_pos.y - 45.0, 0.65).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2(1.2, 1.2), 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	var fade_tween: Tween = create_tween()
	fade_tween.tween_interval(0.35)
	fade_tween.tween_property(self, "modulate:a", 0.0, 0.3)
	fade_tween.tween_callback(queue_free)
