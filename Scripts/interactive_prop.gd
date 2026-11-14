class_name InteractiveProp
extends Area2D

## InteractiveProp — inspectable items (exam papers, chalkboards, notes, diaries).
## Shows a prompt on approach; pressing E opens an interactive paper/modal UI.

@export var prop_name: String = "Exam Paper"
@export var prompt_text: String = "[E] Inspect Paper"
@export var modal_title: String = "EXAM PAPER: MATHEMATICS"
@export_multiline var modal_content: String = (
	"MID-TERM ASSESSMENT\n" +
	"----------------------------------------\n" +
	"Q1: If stress level S rises linearly with time,\n" +
	"    at what point do you take a deep breath?\n\n" +
	"Q2: Arun has 3 assignments due tomorrow.\n" +
	"    How many should he panic about? (Answer: 0)\n\n" +
	"[Note scribbled in margin]:\n" +
	"'Stay grounded. One question at a time. Bounce Back!'"
)
@export var paper_color: Color = Color(0.97, 0.95, 0.88, 1.0) # Parchment / exam paper

var _player_in_range: bool = false
var _is_open: bool = false
var _prompt_label: Label
var _ui_canvas: CanvasLayer
var _panel: PanelContainer
var _title_lbl: Label
var _content_lbl: Label
var _close_lbl: Label

func _ready() -> void:
	collision_layer = 0
	collision_mask = 1 # Arun layer 1
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

	# Floating prompt above prop
	_prompt_label = Label.new()
	_prompt_label.text = prompt_text
	_prompt_label.add_theme_font_size_override("font_size", 11)
	_prompt_label.add_theme_color_override("font_color", Color(1.0, 1.0, 0.4, 1.0))
	_prompt_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	_prompt_label.add_theme_constant_override("shadow_offset_x", 1)
	_prompt_label.add_theme_constant_override("shadow_offset_y", 1)
	_prompt_label.position = Vector2(-50, -32)
	_prompt_label.size = Vector2(100, 20)
	_prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt_label.visible = false
	add_child(_prompt_label)

	_build_modal_ui()

func _build_modal_ui() -> void:
	_ui_canvas = CanvasLayer.new()
	_ui_canvas.layer = 50
	add_child(_ui_canvas)

	# Dimmed backdrop
	var backdrop := ColorRect.new()
	backdrop.color = Color(0, 0, 0, 0.45)
	backdrop.anchor_right = 1.0
	backdrop.anchor_bottom = 1.0
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui_canvas.add_child(backdrop)

	# Paper container
	_panel = PanelContainer.new()
	_panel.anchor_left = 0.5
	_panel.anchor_top = 0.5
	_panel.anchor_right = 0.5
	_panel.anchor_bottom = 0.5
	_panel.offset_left = -180.0
	_panel.offset_top = -120.0
	_panel.offset_right = 180.0
	_panel.offset_bottom = 120.0

	var style := StyleBoxFlat.new()
	style.bg_color = paper_color
	style.border_color = Color(0.3, 0.25, 0.2, 1.0)
	style.set_border_width_all(3)
	style.set_corner_radius_all(6)
	style.set_content_margin_all(14)
	style.shadow_color = Color(0, 0, 0, 0.4)
	style.shadow_size = 6
	_panel.add_theme_stylebox_override("panel", style)
	_ui_canvas.add_child(_panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	_panel.add_child(vbox)

	# Title
	_title_lbl = Label.new()
	_title_lbl.text = modal_title
	_title_lbl.add_theme_font_size_override("font_size", 14)
	_title_lbl.add_theme_color_override("font_color", Color(0.15, 0.12, 0.1, 1.0))
	_title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_title_lbl)

	# Content text
	_content_lbl = Label.new()
	_content_lbl.text = modal_content
	_content_lbl.add_theme_font_size_override("font_size", 11)
	_content_lbl.add_theme_color_override("font_color", Color(0.2, 0.18, 0.16, 1.0))
	_content_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_content_lbl.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(_content_lbl)

	# Footer / Close prompt
	_close_lbl = Label.new()
	_close_lbl.text = "[E / ESC] Close"
	_close_lbl.add_theme_font_size_override("font_size", 10)
	_close_lbl.add_theme_color_override("font_color", Color(0.5, 0.4, 0.3, 1.0))
	_close_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	vbox.add_child(_close_lbl)

	_ui_canvas.visible = false

func _unhandled_input(event: InputEvent) -> void:
	if not _player_in_range:
		return

	if event is InputEventKey and event.is_pressed() and not event.is_echo():
		if event.keycode == KEY_E or event.physical_keycode == KEY_E:
			if _is_open:
				close_modal()
			else:
				open_modal()
		elif event.keycode == KEY_ESCAPE or event.physical_keycode == KEY_ESCAPE:
			if _is_open:
				close_modal()

func open_modal() -> void:
	_is_open = true
	_prompt_label.visible = false
	_ui_canvas.visible = true

	var audio_mgr = get_node_or_null("/root/AudioManager")
	if audio_mgr:
		if audio_mgr.has_method("play_prop_open"):
			audio_mgr.play_prop_open()
		if audio_mgr.has_method("speak_tts"):
			audio_mgr.speak_tts(modal_title)

	# Play a subtle pop-in tween
	_panel.scale = Vector2(0.9, 0.9)
	_panel.pivot_offset = _panel.size / 2.0
	var tw := create_tween()
	tw.tween_property(_panel, "scale", Vector2.ONE, 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func close_modal() -> void:
	_is_open = false
	_ui_canvas.visible = false

	var audio_mgr = get_node_or_null("/root/AudioManager")
	if audio_mgr:
		if audio_mgr.has_method("play_interact"):
			audio_mgr.play_interact()
		if audio_mgr.has_method("stop_tts"):
			audio_mgr.stop_tts()

	if _player_in_range:
		_prompt_label.visible = true

func _on_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D:
		_player_in_range = true
		if not _is_open:
			_prompt_label.visible = true

func _on_body_exited(body: Node2D) -> void:
	if body is CharacterBody2D:
		_player_in_range = false
		_prompt_label.visible = false
		if _is_open:
			close_modal()
