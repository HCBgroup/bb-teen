class_name ExamSpotlightSequence
extends Area2D

## Orchestrates the dramatic exam spotlight sequence, Arun's anxiety thoughts,
## and the arrival of the magical Bounce Back guide.

@export var arun: CharacterBody2D
@export var magical_guide: MagicalGuide

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
var _is_typing: bool = false

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

var _current_pitch: float = 1.0

func _process(delta: float) -> void:
	if _sequence_started and arun and _shader_mat:
		# Update screen coordinate of Arun for spotlight
		var canvas_pos = arun.get_global_transform_with_canvas().origin
		_shader_mat.set_shader_parameter("player_screen_pos", canvas_pos)

	if _is_typing and _char_idx < _current_target.length():
		_typewriter_timer += delta
		if _typewriter_timer >= 0.02:
			_typewriter_timer = 0.0
			_char_idx += 1
			_text_lbl.text = _current_target.substr(0, _char_idx)

			# Play dialogue chatter blip every 2 characters
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
	_sequence_started = true
	_is_player_near = false
	_prompt_label.visible = false

	if not arun:
		arun = get_node_or_null("../Arun_Charchter(Evin)")

	if arun:
		# Sit Arun squarely at the desk
		arun.global_position = Vector2(418, 465)
		var move_comp = arun.get_node_or_null("MovementComponent")
		if move_comp:
			move_comp.set_process(false)
			move_comp.facing_dir = Vector2.UP

	# Enable spotlight overlay & smoothly dim the room
	_overlay_rect.visible = true
	var tween = create_tween().set_parallel(true)
	tween.tween_method(func(v: float):
		if _shader_mat:
			_shader_mat.set_shader_parameter("darkness", v)
	, 0.0, 0.90, 1.4).set_trans(Tween.TRANS_SINE)

	# Pulse the spotlight slightly like a nervous heartbeat
	var pulse_tween = create_tween().set_loops(6)
	pulse_tween.tween_method(func(r: float):
		if _shader_mat:
			_shader_mat.set_shader_parameter("inner_radius", r)
	, 60.0, 52.0, 0.5)
	pulse_tween.tween_method(func(r: float):
		if _shader_mat:
			_shader_mat.set_shader_parameter("inner_radius", r)
	, 52.0, 60.0, 0.5)

	await tween.finished

	# Begin thought dialogue sequence
	_dialogue_lines = [
		{
			"speaker": "💭 ARUN (Heart Pounding)",
			"color": Color(0.4, 0.8, 1.0),
			"text": "\"Question 1: 'Solve for x under extreme time pressure.' The numbers are starting to blur together...\""
		},
		{
			"speaker": "💭 ARUN (Panic Rising)",
			"color": Color(1.0, 0.4, 0.4),
			"text": "\"Everyone else is turning pages so fast. My hands won't stop shaking. What if I freeze?! What will Mom and Dad say?!\""
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

		if "MENTOR" in data["speaker"] or "✨" in data["speaker"]:
			_current_pitch = 1.45
		else:
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
	if _dialogue_idx == 2:
		# Anxiety peak: trigger Magical Guide swoop-in!
		_dialogue_panel.visible = false
		_is_typing = false
		var audio_mgr = get_node_or_null("/root/AudioManager")
		if audio_mgr and audio_mgr.has_method("play_powerup"):
			audio_mgr.play_powerup()

		if not magical_guide:
			magical_guide = get_node_or_null("../MagicalGuide")

		if magical_guide:
			magical_guide.fly_in(Vector2(470, 440))
			await magical_guide.arrival_finished
			magical_guide.pulse_wisdom()
			if audio_mgr and audio_mgr.has_method("play_magic_sparkle"):
				audio_mgr.play_magic_sparkle()

		_dialogue_lines.append({
			"speaker": "✨ BOUNCE MENTOR (Magical Guide)",
			"color": Color(1.0, 0.85, 0.3),
			"text": "\"ARUN! Look up! Stop holding your breath!\""
		})
		_dialogue_lines.append({
			"speaker": "✨ BOUNCE MENTOR",
			"color": Color(1.0, 0.85, 0.3),
			"text": "\"A rubber ball only leaps higher the harder it hits the floor. Pressure doesn't break who you are — how you Bounce Back does!\""
		})
		_dialogue_lines.append({
			"speaker": "✨ BOUNCE MENTOR",
			"color": Color(1.0, 0.85, 0.3),
			"text": "\"Take a deep breath. Focus your mind. You've prepared for this. Let's solve this exam together!\""
		})
		_dialogue_lines.append({
			"speaker": "💭 ARUN (Empowered)",
			"color": Color(0.4, 1.0, 0.6),
			"text": "\"He's right... Panic is just energy waiting to be redirected. I don't have to freeze. I can Bounce Back!\""
		})

		_dialogue_panel.visible = true
		_display_current_line()
	elif _dialogue_idx < _dialogue_lines.size():
		_display_current_line()
	else:
		_finish_exam_sequence()

func _finish_exam_sequence() -> void:
	_dialogue_panel.visible = false
	_is_typing = false

	var audio_mgr = get_node_or_null("/root/AudioManager")
	if audio_mgr:
		if audio_mgr.has_method("stop_tts"):
			audio_mgr.stop_tts()
		if audio_mgr.has_method("play_prop_open"):
			audio_mgr.play_prop_open()

	# Restore lighting with golden glow
	var tween = create_tween().set_parallel(true)
	tween.tween_method(func(v: float):
		if _shader_mat:
			_shader_mat.set_shader_parameter("darkness", v)
	, 0.90, 0.0, 1.2)

	if arun:
		arun.take_stress(-50.0) # Golden flash of relief
		var move_comp = arun.get_node_or_null("MovementComponent")
		if move_comp:
			move_comp.set_process(true)

	await tween.finished
	_overlay_rect.visible = false

func _on_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D and not _sequence_started:
		_is_player_near = true
		_prompt_label.visible = true

func _on_body_exited(body: Node2D) -> void:
	if body is CharacterBody2D:
		_is_player_near = false
		_prompt_label.visible = false
