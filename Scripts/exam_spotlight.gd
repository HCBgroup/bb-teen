class_name ExamSpotlightSequence
extends Area2D

## Orchestrates the dramatic exam shot, Arun's mid-term tension,
## and the transition into the Marksheet Dodge Minigame.

@export var arun: CharacterBody2D

var _is_player_near: bool = false
var _sequence_started: bool = false
var _prompt_label: Label

# Visual overlay for spotlight
var _canvas_layer: CanvasLayer
var _overlay_rect: ColorRect
var _shader_mat: ShaderMaterial

# Dialogue UI
var _dialogue_panel: PanelContainer
var _speaker_lbl: Label
var _text_lbl: Label
var _continue_lbl: Label

var _dialogue_lines: Array = []
var _dialogue_idx: int = 0
var _char_idx: int = 0
var _current_target: String = ""
var _typewriter_timer: float = 0.0
var _typewriter_speed: float = 0.02
var _is_typing: bool = false
var _current_pitch: float = 1.0

func _ready() -> void:
	collision_layer = 0
	collision_mask = 1
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

	_setup_prompt()
	_setup_spotlight_overlay()
	_setup_dialogue_ui()

func _setup_prompt() -> void:
	_prompt_label = Label.new()
	_prompt_label.text = "[E] Take Exam Seat"
	_prompt_label.add_theme_font_size_override("font_size", 13)
	_prompt_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3))
	_prompt_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	_prompt_label.position = Vector2(-70, -45)
	_prompt_label.size = Vector2(140, 24)
	_prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt_label.visible = false
	add_child(_prompt_label)

func _setup_spotlight_overlay() -> void:
	_canvas_layer = CanvasLayer.new()
	_canvas_layer.layer = 40
	add_child(_canvas_layer)

	_overlay_rect = ColorRect.new()
	_overlay_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var shader = load("res://Shaders/spotlight.gdshader")
	if shader:
		_shader_mat = ShaderMaterial.new()
		_shader_mat.shader = shader
		_shader_mat.set_shader_parameter("darkness", 0.0)
		_shader_mat.set_shader_parameter("inner_radius", 60.0)
		_shader_mat.set_shader_parameter("outer_radius", 180.0)
		_shader_mat.set_shader_parameter("dark_color", Color(0.04, 0.06, 0.12, 1.0))
		_overlay_rect.material = _shader_mat

	_overlay_rect.visible = false
	_canvas_layer.add_child(_overlay_rect)

func _setup_dialogue_ui() -> void:
	_dialogue_panel = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.1, 0.16, 0.95)
	style.border_color = Color(0.85, 0.65, 0.2, 1.0)
	style.border_width_left = 3
	style.border_width_right = 3
	style.border_width_top = 3
	style.border_width_bottom = 3
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.content_margin_left = 22
	style.content_margin_right = 22
	style.content_margin_top = 14
	style.content_margin_bottom = 14
	_dialogue_panel.add_theme_stylebox_override("panel", style)

	_dialogue_panel.anchor_left = 0.5
	_dialogue_panel.anchor_top = 1.0
	_dialogue_panel.anchor_right = 0.5
	_dialogue_panel.anchor_bottom = 1.0
	_dialogue_panel.offset_left = -420
	_dialogue_panel.offset_top = -180
	_dialogue_panel.offset_right = 420
	_dialogue_panel.offset_bottom = -30
	_dialogue_panel.name = "DialogueBox"

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	_dialogue_panel.add_child(vbox)

	_speaker_lbl = Label.new()
	_speaker_lbl.text = "ARUN"
	_speaker_lbl.add_theme_font_size_override("font_size", 13)
	_speaker_lbl.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2))
	vbox.add_child(_speaker_lbl)

	_text_lbl = Label.new()
	_text_lbl.text = "..."
	_text_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text_lbl.add_theme_font_size_override("font_size", 14)
	_text_lbl.add_theme_color_override("font_color", Color.WHITE)
	_text_lbl.custom_minimum_size = Vector2(800, 60)
	vbox.add_child(_text_lbl)

	_continue_lbl = Label.new()
	_continue_lbl.text = "▶ Press [E] or [SPACE] to continue"
	_continue_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_continue_lbl.add_theme_font_size_override("font_size", 11)
	_continue_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8))
	vbox.add_child(_continue_lbl)

	_dialogue_panel.visible = false
	_canvas_layer.add_child(_dialogue_panel)

func _process(delta: float) -> void:
	if _is_typing and _char_idx < _current_target.length():
		_typewriter_timer += delta
		if _typewriter_timer >= _typewriter_speed:
			_typewriter_timer = 0.0
			_char_idx += 1
			_text_lbl.text = _current_target.substr(0, _char_idx)

			if _char_idx % 2 == 0:
				var audio_mgr = get_node_or_null("/root/AudioManager")
				if audio_mgr and audio_mgr.has_method("play_talk_blip"):
					audio_mgr.play_talk_blip(_current_pitch)

func _unhandled_input(event: InputEvent) -> void:
	if not event.is_pressed() or event.is_echo():
		return

	if not _sequence_started:
		if _is_player_near and (event.is_action_pressed("ui_accept") or event.is_physical_key_pressed(KEY_E) or (event is InputEventKey and event.keycode == KEY_E)):
			start_exam_sequence()
	else:
		if event.is_action_pressed("ui_accept") or event.is_physical_key_pressed(KEY_E) or (event is InputEventKey and (event.keycode == KEY_E or event.keycode == KEY_SPACE or event.keycode == KEY_ENTER)):
			if _char_idx < _current_target.length():
				_char_idx = _current_target.length()
				_text_lbl.text = _current_target
			else:
				_advance_dialogue()

func start_exam_sequence() -> void:
	if _sequence_started:
		return
	_sequence_started = true
	_is_player_near = false
	if _prompt_label:
		_prompt_label.visible = false

	if not arun:
		arun = get_node_or_null("../Arun_Charchter(Evin)")

	if arun:
		# Sit Arun squarely at Desk 24
		arun.global_position = Vector2(418, 465)
		var move_comp = arun.get_node_or_null("MovementComponent")
		if move_comp:
			move_comp.set_process(false)
			move_comp.facing_dir = Vector2.UP

	# Enable spotlight overlay & smoothly dim the room
	if _overlay_rect:
		_overlay_rect.visible = true
	var tween = create_tween()
	if tween:
		tween.set_parallel(true)
		tween.tween_method(func(v: float):
			if _shader_mat:
				_shader_mat.set_shader_parameter("darkness", v)
		, 0.0, 0.90, 1.4).set_trans(Tween.TRANS_SINE)

		# Pulse the spotlight slightly like a nervous heartbeat
		var pulse_tween = create_tween()
		if pulse_tween:
			pulse_tween.set_loops(6)
			pulse_tween.tween_method(func(r: float):
				if _shader_mat:
					_shader_mat.set_shader_parameter("inner_radius", r)
			, 60.0, 52.0, 0.5)
			pulse_tween.tween_method(func(r: float):
				if _shader_mat:
					_shader_mat.set_shader_parameter("inner_radius", r)
			, 52.0, 60.0, 0.5)

		await tween.finished

	# The Exam Shot: Room goes dead silent, clock ticks, and the exam begins
	_dialogue_lines = [
		{
			"speaker": "📋 MR. KUMAR (Invigilator)",
			"color": Color(1.0, 0.85, 0.3),
			"text": "\"Silence in the examination hall. Pens ready. You have 90 minutes. Turn your papers over... and begin!\""
		},
		{
			"speaker": "💭 ARUN (Heart Pounding)",
			"color": Color(0.4, 0.8, 1.0),
			"text": "\"Question 1: 'Solve for x under extreme pressure.' The numbers are blurring... Everyone's pens are scratching so fast!\""
		},
		{
			"speaker": "💭 ARUN (Steeling Resolve)",
			"color": Color(1.0, 0.5, 0.3),
			"text": "\"No! I won't freeze up today. Deep breath. I'm going to shred through this exam and BOUNCE BACK!\""
		}
	]
	_dialogue_idx = 0
	_dialogue_panel.visible = true
	_display_current_line()

func _display_current_line() -> void:
	if _dialogue_idx < _dialogue_lines.size():
		var data = _dialogue_lines[_dialogue_idx]
		_speaker_lbl.text = data["speaker"]
		_speaker_lbl.add_theme_color_override("font_color", data["color"])
		_current_target = data["text"]
		_char_idx = 0
		_text_lbl.text = ""
		_is_typing = true

		if "KUMAR" in data["speaker"]:
			_current_pitch = 0.9
		else:
			_current_pitch = 1.05

		var audio_mgr = get_node_or_null("/root/AudioManager")
		if audio_mgr:
			if audio_mgr.has_method("play_interact"):
				audio_mgr.play_interact()
			if audio_mgr.has_method("speak_tts"):
				audio_mgr.speak_tts(_current_target, _current_pitch)
	else:
		_transition_to_minigame()

func _advance_dialogue() -> void:
	_dialogue_idx += 1
	if _dialogue_idx < _dialogue_lines.size():
		_display_current_line()
	else:
		_transition_to_minigame()

func _transition_to_minigame() -> void:
	_dialogue_panel.visible = false
	_is_typing = false

	var audio_mgr = get_node_or_null("/root/AudioManager")
	if audio_mgr:
		if audio_mgr.has_method("stop_tts"):
			audio_mgr.stop_tts()
		if audio_mgr.has_method("play_powerup"):
			audio_mgr.play_powerup()

	# Dramatic transition into Marksheet Dodge Minigame
	var scene_mgr = get_node_or_null("/root/SceneManager")
	if scene_mgr:
		scene_mgr.change_scene_to("res://minigame/marksheet_dodge_game.tscn")
	else:
		get_tree().change_scene_to_file("res://minigame/marksheet_dodge_game.tscn")

func _on_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D and not _sequence_started:
		_is_player_near = true
		if _prompt_label:
			_prompt_label.visible = true

func _on_body_exited(body: Node2D) -> void:
	if body is CharacterBody2D:
		_is_player_near = false
		if _prompt_label:
			_prompt_label.visible = false
