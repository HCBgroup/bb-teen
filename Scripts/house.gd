extends Node2D

const SceneMgr = preload("res://Scripts/scene_manager.gd")

@onready var player: CharacterBody2D = $"Arun_Charchter(Evin)"

var _dialogue_box: CanvasLayer
var _speaker_badge: Label
var _dialogue_label: Label
var _continue_prompt: Label
var _dialogue_queue: Array = []
var _is_dialogue_active: bool = false
var _char_index: int = 0
var _target_text: String = ""
var _typewriter_speed: float = 0.02
var _typewriter_timer: float = 0.0

func _ready() -> void:
	# Configure camera limits for 1280x720 native view with smooth tracking
	if player and player.has_method("configure_camera"):
		player.configure_camera(Rect2(0, 0, 1280, 720), Vector2(1.3, 1.3))

	_setup_dialogue_box()

	var door: String = SceneMgr.get_target_door()
	if door == "from_walkway" or door == "from_run":
		# Entering from front door
		if player:
			player.global_position = Vector2(1170, 590)
	else:
		# Game starts in bedroom staring into gold mirror
		if player:
			player.global_position = Vector2(184, 195)
			var move_comp = player.get_node_or_null("MovementComponent")
			if move_comp:
				move_comp.facing_dir = Vector2.UP
		_start_opening_dialogue()

func _setup_dialogue_box() -> void:
	_dialogue_box = CanvasLayer.new()
	_dialogue_box.layer = 60
	add_child(_dialogue_box)

	var panel = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.12, 0.18, 0.95)
	style.border_color = Color(0.85, 0.65, 0.2, 1.0)
	style.border_width_left = 3
	style.border_width_right = 3
	style.border_width_top = 3
	style.border_width_bottom = 3
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.content_margin_left = 24
	style.content_margin_right = 24
	style.content_margin_top = 16
	style.content_margin_bottom = 16
	panel.add_theme_stylebox_override("panel", style)

	panel.anchor_left = 0.5
	panel.anchor_top = 1.0
	panel.anchor_right = 0.5
	panel.anchor_bottom = 1.0
	panel.offset_left = -440
	panel.offset_top = -180
	panel.offset_right = 440
	panel.offset_bottom = -30
	panel.name = "DialoguePanel"
	panel.visible = false
	_dialogue_box.add_child(panel)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	panel.add_child(vbox)

	# Speaker Badge
	_speaker_badge = Label.new()
	_speaker_badge.text = "SPEAKER"
	_speaker_badge.add_theme_font_size_override("font_size", 14)
	_speaker_badge.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	vbox.add_child(_speaker_badge)

	# Dialogue Text
	_dialogue_label = Label.new()
	_dialogue_label.text = ""
	_dialogue_label.add_theme_font_size_override("font_size", 15)
	_dialogue_label.add_theme_color_override("font_color", Color.WHITE)
	_dialogue_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_dialogue_label.custom_minimum_size = Vector2(800, 50)
	vbox.add_child(_dialogue_label)

	# Continue prompt indicator
	_continue_prompt = Label.new()
	_continue_prompt.text = "▶ Press [E] or [SPACE] to continue"
	_continue_prompt.add_theme_font_size_override("font_size", 11)
	_continue_prompt.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	_continue_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	vbox.add_child(_continue_prompt)

func _start_opening_dialogue() -> void:
	_dialogue_queue = [
		{
			"speaker": "📢 MOM (Shouting from the Kitchen)",
			"color": Color(1.0, 0.8, 0.25),
			"text": "\"ARUN! Are you STILL staring into that mirror?! Your turmeric milk is getting cold on the table, and the bus leaves in 15 minutes! The math exam starts at 8:30!\""
		},
		{
			"speaker": "💭 ARUN (Looking into Mirror)",
			"color": Color(0.4, 0.8, 1.0),
			"text": "\"Deep breath... Uniform is on. Formula sheets are packed. Everyone expects top marks, but I can't let anxiety freeze me. Take a breath and Bounce Back.\""
		}
	]
	_play_next_dialogue()

var _current_pitch: float = 1.0

func _process(delta: float) -> void:
	if _is_dialogue_active and _char_index < _target_text.length():
		_typewriter_timer += delta
		if _typewriter_timer >= _typewriter_speed:
			_typewriter_timer = 0.0
			_char_index += 1
			_dialogue_label.text = _target_text.substr(0, _char_index)

			# Play retro speech chatter blip every 2 characters
			if _char_index % 2 == 0:
				var audio_mgr = get_node_or_null("/root/AudioManager")
				if audio_mgr and audio_mgr.has_method("play_talk_blip"):
					audio_mgr.play_talk_blip(_current_pitch)

func _unhandled_input(event: InputEvent) -> void:
	if not _is_dialogue_active:
		return
	if event is InputEventKey and event.is_pressed() and not event.is_echo():
		if event.keycode == KEY_E or event.keycode == KEY_SPACE or event.keycode == KEY_ENTER or event.physical_keycode == KEY_E:
			if _char_index < _target_text.length():
				# Instantly complete current line
				_char_index = _target_text.length()
				_dialogue_label.text = _target_text
			else:
				_play_next_dialogue()

func _play_next_dialogue() -> void:
	if _dialogue_queue.is_empty():
		_close_dialogue()
		return

	var current = _dialogue_queue.pop_front()
	var panel = _dialogue_box.get_node_or_null("DialoguePanel")
	if panel:
		panel.visible = true

	_speaker_badge.text = current["speaker"]
	_speaker_badge.add_theme_color_override("font_color", current["color"])
	_target_text = current["text"]
	_char_index = 0
	_dialogue_label.text = ""
	_is_dialogue_active = true

	if "MOM" in current["speaker"]:
		_current_pitch = 1.15
	else:
		_current_pitch = 1.0

	var audio_mgr = get_node_or_null("/root/AudioManager")
	if audio_mgr:
		if audio_mgr.has_method("play_interact"):
			audio_mgr.play_interact()
		if audio_mgr.has_method("speak_tts"):
			audio_mgr.speak_tts(_target_text, _current_pitch)

func _close_dialogue() -> void:
	_is_dialogue_active = false
	var audio_mgr = get_node_or_null("/root/AudioManager")
	if audio_mgr and audio_mgr.has_method("stop_tts"):
		audio_mgr.stop_tts()

	var panel = _dialogue_box.get_node_or_null("DialoguePanel")
	if panel:
		var tween = create_tween()
		tween.tween_property(panel, "modulate:a", 0.0, 0.2)
		tween.tween_callback(func():
			panel.visible = false
			panel.modulate.a = 1.0
		)
