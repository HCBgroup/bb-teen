class_name ExamSpotlightSequence
extends Area2D

## Orchestrates the dramatic Exam Shot sequence:
## - Classmates hunched over writing their exams
## - Clock ticking and dimming spotlight focus on Arun
## - Arun's internal exam panic monologue
## - Sudden transition into the Marksheet Dodge Minigame

@export var arun: CharacterBody2D
@export var magical_guide: MagicalGuide

var _is_player_near: bool = false
var _sequence_started: bool = false
var _exam_seat_enabled: bool = true # Can take seat anytime or after talking to Mr. Kumar
var _prompt_label: Label
var _marker_sprite: Polygon2D

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
var _is_typing: bool = false
var _current_pitch: float = 1.0

# Sound timer for clock ticking
var _tick_timer: float = 0.0

func _ready() -> void:
	collision_layer = 0
	collision_mask = 1
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

	_setup_prompt()
	_setup_spotlight_overlay()
	_setup_dialogue_ui()

func enable_exam_seat() -> void:
	_exam_seat_enabled = true
	if _prompt_label:
		_prompt_label.text = "[E] Take Exam Seat (Desk #5)"
	if _is_player_near:
		_prompt_label.visible = true

func _setup_prompt() -> void:
	_prompt_label = Label.new()
	_prompt_label.text = "[E] Take Exam Seat (Desk #5)"
	_prompt_label.add_theme_font_size_override("font_size", 12)
	_prompt_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3))
	_prompt_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	_prompt_label.position = Vector2(-90, -45)
	_prompt_label.size = Vector2(180, 24)
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
		_shader_mat.set_shader_parameter("inner_radius", 65.0)
		_shader_mat.set_shader_parameter("outer_radius", 190.0)
		_shader_mat.set_shader_parameter("dark_color", Color(0.04, 0.05, 0.12, 1.0))
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
	_dialogue_panel.visible = false
	_canvas_layer.add_child(_dialogue_panel)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	_dialogue_panel.add_child(vbox)

	_speaker_lbl = Label.new()
	_speaker_lbl.add_theme_font_size_override("font_size", 14)
	vbox.add_child(_speaker_lbl)

	_text_lbl = Label.new()
	_text_lbl.add_theme_font_size_override("font_size", 15)
	_text_lbl.add_theme_color_override("font_color", Color.WHITE)
	_text_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text_lbl.custom_minimum_size = Vector2(760, 50)
	vbox.add_child(_text_lbl)

	_continue_lbl = Label.new()
	_continue_lbl.text = "▶ Press [E] or [SPACE] to continue"
	_continue_lbl.add_theme_font_size_override("font_size", 11)
	_continue_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	_continue_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	vbox.add_child(_continue_lbl)

func _process(delta: float) -> void:
	if _sequence_started:
		if arun and _shader_mat:
			var canvas_pos = arun.get_global_transform_with_canvas().origin
			_shader_mat.set_shader_parameter("player_screen_pos", canvas_pos)

		# Soft ticking clock sound during exam shot
		_tick_timer += delta
		if _tick_timer >= 1.0:
			_tick_timer = 0.0
			var audio_mgr = get_node_or_null("/root/AudioManager")
			if audio_mgr and audio_mgr.has_method("play_sfx") and audio_mgr.snd_tap:
				audio_mgr.play_sfx(audio_mgr.snd_tap, 0.8, -14.0)

	if _is_typing and _char_idx < _current_target.length():
		_typewriter_timer += delta
		if _typewriter_timer >= 0.02:
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
		if _is_player_near and _exam_seat_enabled and (event.is_action_pressed("ui_accept") or event.is_physical_key_pressed(KEY_E) or (event is InputEventKey and event.keycode == KEY_E)):
			start_exam_sequence()
	else:
		if event.is_action_pressed("ui_accept") or event.is_physical_key_pressed(KEY_E) or (event is InputEventKey and (event.keycode == KEY_E or event.keycode == KEY_SPACE or event.keycode == KEY_ENTER)):
			if _char_idx < _current_target.length():
				_char_idx = _current_target.length()
				_text_lbl.text = _current_target
			else:
				_advance_dialogue()

func start_exam_sequence() -> void:
	_sequence_started = true
	_is_player_near = false
	_prompt_label.visible = false

	if not arun:
		arun = get_node_or_null("../Arun_Charchter(Evin)")

	if arun:
		# Sit Arun squarely at Desk #5 facing UP
		arun.global_position = Vector2(418, 465)
		var move_comp = arun.get_node_or_null("MovementComponent")
		if move_comp:
			move_comp.set_process(false)
			move_comp.facing_dir = Vector2.UP

	# Animate all classmates into writing posture
	var parent_school = get_parent()
	if parent_school and parent_school.has_method("set_classmates_writing"):
		parent_school.set_classmates_writing(true)

	# Enable spotlight overlay & smoothly dim the room for the dramatic Exam Shot
	_overlay_rect.visible = true
	var tween = create_tween().set_parallel(true)
	tween.tween_method(func(v: float):
		if _shader_mat:
			_shader_mat.set_shader_parameter("darkness", v)
	, 0.0, 0.90, 1.4).set_trans(Tween.TRANS_SINE)

	# Nervous heartbeat pulse on the spotlight
	var pulse_tween = create_tween().set_loops(6)
	pulse_tween.tween_method(func(r: float):
		if _shader_mat:
			_shader_mat.set_shader_parameter("inner_radius", r)
	, 65.0, 55.0, 0.5)
	pulse_tween.tween_method(func(r: float):
		if _shader_mat:
			_shader_mat.set_shader_parameter("inner_radius", r)
	, 55.0, 65.0, 0.5)

	await tween.finished

	# The Exam Shot Monologue:
	_dialogue_lines = [
		{
			"speaker": "⏱️ EXAM HALL (The Clock is Ticking)",
			"color": Color(1.0, 0.85, 0.3),
			"text": "\"The classroom falls dead silent. Pencils scratch frantically against paper. 90 minutes on the clock.\""
		},
		{
			"speaker": "💭 ARUN (Heart Pounding)",
			"color": Color(0.4, 0.8, 1.0),
			"text": "\"Question 1: 'Solve for x under extreme time pressure.' Wait... my mind is completely going blank! What was the formula?!\""
		},
		{
			"speaker": "💭 ARUN (Panic Rising)",
			"color": Color(1.0, 0.4, 0.4),
			"text": "\"Everyone else is turning pages so fast... It feels like sheets of failing marks are raining down from above to crush me!\""
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
		_current_pitch = 0.95

		var audio_mgr = get_node_or_null("/root/AudioManager")
		if audio_mgr:
			if audio_mgr.has_method("play_interact"):
				audio_mgr.play_interact()
			if audio_mgr.has_method("speak_tts"):
				audio_mgr.speak_tts(_current_target, _current_pitch)
	else:
		_dialogue_panel.visible = false

func _advance_dialogue() -> void:
	_dialogue_idx += 1
	if _dialogue_idx < _dialogue_lines.size():
		_display_current_line()
	else:
		# Monologue complete: Sudden transition into Marksheet Dodge Minigame!
		_trigger_minigame_transition()

func _trigger_minigame_transition() -> void:
	_dialogue_panel.visible = false
	_is_typing = false

	var audio_mgr = get_node_or_null("/root/AudioManager")
	if audio_mgr:
		if audio_mgr.has_method("stop_tts"):
			audio_mgr.stop_tts()
		if audio_mgr.has_method("play_sfx") and audio_mgr.snd_hurt:
			audio_mgr.play_sfx(audio_mgr.snd_hurt, 0.9, 0.0)

	# Sudden anxiety flash / screen shake before minigame
	var flash_tween = create_tween()
	flash_tween.tween_property(_overlay_rect, "modulate", Color(1.5, 1.5, 1.5, 1.0), 0.15)
	flash_tween.tween_property(_overlay_rect, "modulate", Color.WHITE, 0.2)

	await flash_tween.finished

	# Transition to the Marksheet Dodge Minigame
	var scene_mgr = get_node_or_null("/root/SceneManager")
	if scene_mgr and scene_mgr.has_method("change_scene_to"):
		scene_mgr.change_scene_to("res://minigame/marksheet_dodge_game.tscn")
	else:
		get_tree().change_scene_to_file("res://minigame/marksheet_dodge_game.tscn")

func _on_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D and not _sequence_started:
		_is_player_near = true
		if _exam_seat_enabled:
			_prompt_label.visible = true

func _on_body_exited(body: Node2D) -> void:
	if body is CharacterBody2D:
		_is_player_near = false
		_prompt_label.visible = false
