class_name CompanionStudent
extends CharacterBody2D

## Fellow student companion travelling to school with Arun on the Walkway.
## Follows Arun smoothly at a friendly distance and offers encouraging dialogue.

@export var follow_distance: float = 75.0
@export var move_speed: float = 145.0
@export var npc_name: String = "Priya"
@export var dialogue_lines: PackedStringArray = [
	"Hey Arun! That was some sprint to school!",
	"You look charged up and ready for the math assessment.",
	"Let's head inside together — we're going to do great!"
]

var voice_clips: Array[AudioStream] = []

var target: CharacterBody2D
var _player_in_range: bool = false
var _is_speaking: bool = false
var _dialogue_index: int = 0
var _char_index: int = 0
var _current_text: String = ""
var _typewriter_speed: float = 0.025
var _typewriter_timer: float = 0.0

# UI
var _ui_root: Node2D
var _prompt_badge: PanelContainer
var _dialogue_box: PanelContainer
var _name_label: Label
var _text_label: Label
var _footer_label: Label
var _sprite: Sprite2D

func _ready() -> void:
	collision_layer = 2
	collision_mask = 2
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	z_index = 5

	# Preload voice clips
	if ResourceLoader.exists("res://assests/audio/voice/priya_walkway_1.mp3"):
		voice_clips.append(load("res://assests/audio/voice/priya_walkway_1.mp3"))
	if ResourceLoader.exists("res://assests/audio/voice/priya_walkway_2.mp3"):
		voice_clips.append(load("res://assests/audio/voice/priya_walkway_2.mp3"))
	if ResourceLoader.exists("res://assests/audio/voice/priya_walkway_3.mp3"):
		voice_clips.append(load("res://assests/audio/voice/priya_walkway_3.mp3"))

	# Sprite
	_sprite = Sprite2D.new()
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if ResourceLoader.exists("res://assests/school/student_meera.png"):
		_sprite.texture = load("res://assests/school/student_meera.png")
	_sprite.scale = Vector2(0.9, 0.9)
	_sprite.position = Vector2(0, -22)
	add_child(_sprite)

	# Collider
	var col = CollisionShape2D.new()
	var cap = CapsuleShape2D.new()
	cap.radius = 8.0
	cap.height = 18.0
	col.shape = cap
	col.rotation = 1.5708
	col.position = Vector2(0, -6)
	add_child(col)

	# Interaction Zone
	var zone = Area2D.new()
	zone.collision_layer = 0
	zone.collision_mask = 1
	var zcol = CollisionShape2D.new()
	var circ = CircleShape2D.new()
	circ.radius = 45.0
	zcol.shape = circ
	zone.add_child(zcol)
	zone.body_entered.connect(_on_player_enter)
	zone.body_exited.connect(_on_player_exit)
	add_child(zone)

	_build_hovering_ui()

	# Find player target
	call_deferred("_find_target")

func _find_target() -> void:
	target = get_node_or_null("../Arun_Charchter(Evin)")

func _physics_process(delta: float) -> void:
	if _is_speaking or not target:
		velocity = velocity.move_toward(Vector2.ZERO, 600.0 * delta)
		move_and_slide()
		return

	var dist = global_position.distance_to(target.global_position)
	if dist > follow_distance:
		var dir = (target.global_position - global_position).normalized()
		velocity = velocity.move_toward(dir * move_speed, 900.0 * delta)
		if _sprite and absf(dir.x) > 0.1:
			_sprite.flip_h = (dir.x < 0.0)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, 800.0 * delta)

	move_and_slide()

func _process(delta: float) -> void:
	if _is_speaking and _char_index < _current_text.length():
		_typewriter_timer += delta
		if _typewriter_timer >= _typewriter_speed:
			_typewriter_timer = 0.0
			_char_index += 1
			_text_label.text = _current_text.substr(0, _char_index)

			if _char_index % 2 == 0:
				var audio_mgr = get_node_or_null("/root/AudioManager")
				if audio_mgr and audio_mgr.has_method("play_talk_blip"):
					audio_mgr.play_talk_blip(1.25)

func _unhandled_input(event: InputEvent) -> void:
	if not _player_in_range:
		return
	if event is InputEventKey and event.is_pressed() and not event.is_echo():
		if event.keycode == KEY_E or event.physical_keycode == KEY_E:
			_advance_or_start_dialogue()

func _advance_or_start_dialogue() -> void:
	if dialogue_lines.is_empty():
		return

	if not _is_speaking:
		_prompt_badge.visible = false
		_dialogue_box.visible = true
		_dialogue_index = 0
		_show_current_line()
	else:
		if _char_index < _current_text.length():
			_char_index = _current_text.length()
			_text_label.text = _current_text
		else:
			_dialogue_index += 1
			if _dialogue_index < dialogue_lines.size():
				_show_current_line()
			else:
				_close_dialogue()

func _show_current_line() -> void:
	_is_speaking = true
	_current_text = dialogue_lines[_dialogue_index]
	_char_index = 0
	_text_label.text = ""
	_typewriter_timer = 0.0

	if _dialogue_index == dialogue_lines.size() - 1:
		_footer_label.text = "▶ [E] Done"
	else:
		_footer_label.text = "▶ [E] Next"

	var audio_mgr = get_node_or_null("/root/AudioManager")
	if audio_mgr:
		if audio_mgr.has_method("play_interact"):
			audio_mgr.play_interact()
		if _dialogue_index < voice_clips.size() and voice_clips[_dialogue_index] != null:
			if audio_mgr.has_method("play_voice_stream"):
				audio_mgr.play_voice_stream(voice_clips[_dialogue_index])
		elif audio_mgr.has_method("speak_tts"):
			audio_mgr.speak_tts(_current_text, 1.25)

func _close_dialogue() -> void:
	_is_speaking = false
	_dialogue_box.visible = false
	var audio_mgr = get_node_or_null("/root/AudioManager")
	if audio_mgr and audio_mgr.has_method("stop_voice"):
		audio_mgr.stop_voice()
	if _player_in_range:
		_prompt_badge.visible = true

func _on_player_enter(body: Node2D) -> void:
	if body is CharacterBody2D and body != self:
		_player_in_range = true
		if not _is_speaking:
			_prompt_badge.visible = true

func _on_player_exit(body: Node2D) -> void:
	if body is CharacterBody2D and body != self:
		_player_in_range = false
		_prompt_badge.visible = false
		if _is_speaking:
			_close_dialogue()

func _build_hovering_ui() -> void:
	_ui_root = Node2D.new()
	_ui_root.z_index = 20
	add_child(_ui_root)

	# 1. Prompt badge [E] Talk
	_prompt_badge = PanelContainer.new()
	var p_style = StyleBoxFlat.new()
	p_style.bg_color = Color(0.08, 0.1, 0.16, 0.9)
	p_style.border_color = Color(1.0, 0.85, 0.3, 0.9)
	p_style.border_width_left = 1
	p_style.border_width_right = 1
	p_style.border_width_top = 1
	p_style.border_width_bottom = 1
	p_style.corner_radius_top_left = 4
	p_style.corner_radius_top_right = 4
	p_style.corner_radius_bottom_left = 4
	p_style.corner_radius_bottom_right = 4
	p_style.content_margin_left = 8
	p_style.content_margin_right = 8
	p_style.content_margin_top = 2
	p_style.content_margin_bottom = 2
	_prompt_badge.add_theme_stylebox_override("panel", p_style)

	var p_lbl = Label.new()
	p_lbl.text = "[E] Talk to " + npc_name
	p_lbl.add_theme_font_size_override("font_size", 11)
	p_lbl.add_theme_color_override("font_color", Color(1.0, 0.95, 0.4))
	_prompt_badge.add_child(p_lbl)
	_prompt_badge.position = Vector2(-60, -58)
	_prompt_badge.visible = false
	_ui_root.add_child(_prompt_badge)

	# 2. Dialogue Box Panel
	_dialogue_box = PanelContainer.new()
	_dialogue_box.custom_minimum_size = Vector2(240, 75)
	var box_style = StyleBoxFlat.new()
	box_style.bg_color = Color(0.07, 0.09, 0.15, 0.95)
	box_style.border_color = Color(0.88, 0.72, 0.28, 1.0)
	box_style.border_width_left = 2
	box_style.border_width_right = 2
	box_style.border_width_top = 2
	box_style.border_width_bottom = 2
	box_style.corner_radius_top_left = 8
	box_style.corner_radius_top_right = 8
	box_style.corner_radius_bottom_left = 8
	box_style.corner_radius_bottom_right = 8
	box_style.content_margin_left = 12
	box_style.content_margin_right = 12
	box_style.content_margin_top = 8
	box_style.content_margin_bottom = 8
	box_style.shadow_color = Color(0.0, 0.0, 0.0, 0.5)
	box_style.shadow_size = 4
	box_style.shadow_offset = Vector2(0, 2)
	_dialogue_box.add_theme_stylebox_override("panel", box_style)
	_dialogue_box.position = Vector2(-120, -145)
	_dialogue_box.visible = false
	_ui_root.add_child(_dialogue_box)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	_dialogue_box.add_child(vbox)

	_name_label = Label.new()
	_name_label.text = npc_name.to_upper() + " (Classmate)"
	_name_label.add_theme_font_size_override("font_size", 11)
	_name_label.add_theme_color_override("font_color", Color(0.35, 0.9, 0.65))
	vbox.add_child(_name_label)

	_text_label = Label.new()
	_text_label.text = ""
	_text_label.add_theme_font_size_override("font_size", 12)
	_text_label.add_theme_color_override("font_color", Color(0.96, 0.96, 0.98))
	_text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text_label.custom_minimum_size = Vector2(216, 36)
	vbox.add_child(_text_label)

	_footer_label = Label.new()
	_footer_label.text = "▶ [E] Next"
	_footer_label.add_theme_font_size_override("font_size", 10)
	_footer_label.add_theme_color_override("font_color", Color(0.8, 0.75, 0.5, 0.8))
	_footer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	vbox.add_child(_footer_label)
