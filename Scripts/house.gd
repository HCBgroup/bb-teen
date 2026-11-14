extends Node2D

const SceneMgr = preload("res://Scripts/scene_manager.gd")

@onready var player: CharacterBody2D = $"Arun_Charchter(Evin)"

var _intro_ui: CanvasLayer
var _intro_step: int = 0
var _intro_title: Label
var _intro_label: Label
var _intro_panel: PanelContainer

func _ready() -> void:
	# Configure camera limits for full 1280x720 house framing
	if player and player.has_method("configure_camera"):
		player.configure_camera(Rect2(0, 0, 1280, 720), Vector2(1.0, 1.0))

	var door: String = SceneMgr.get_target_door()
	if door == "from_walkway":
		# Entering from front door into kitchen/living area
		if player:
			player.global_position = Vector2(1040, 580)
	else:
		# Game starts in front of bedroom mirror looking up!
		if player:
			player.global_position = Vector2(310, 245)
			var move_comp = player.get_node_or_null("MovementComponent")
			if move_comp:
				move_comp.facing_dir = Vector2.UP
		_start_morning_shout_sequence()

func _start_morning_shout_sequence() -> void:
	_intro_ui = CanvasLayer.new()
	_intro_ui.layer = 50
	add_child(_intro_ui)

	_intro_panel = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.14, 0.22, 0.94)
	style.border_color = Color(0.9, 0.75, 0.2, 1.0)
	style.border_width_left = 3
	style.border_width_right = 3
	style.border_width_top = 3
	style.border_width_bottom = 3
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	_intro_panel.add_theme_stylebox_override("panel", style)

	_intro_panel.anchor_left = 0.5
	_intro_panel.anchor_top = 0.0
	_intro_panel.anchor_right = 0.5
	_intro_panel.anchor_bottom = 0.0
	_intro_panel.offset_left = -360
	_intro_panel.offset_top = 28
	_intro_panel.offset_right = 360
	_intro_panel.offset_bottom = 145
	_intro_ui.add_child(_intro_panel)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	_intro_panel.add_child(vbox)

	_intro_title = Label.new()
	_intro_title.text = "📢 MOM (Shouting from the Kitchen):"
	_intro_title.add_theme_font_size_override("font_size", 14)
	_intro_title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	_intro_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_intro_title)

	_intro_label = Label.new()
	_intro_label.text = "\"ARUN! Are you STILL staring into that mirror?! Your turmeric milk is getting cold on the table, and the bus leaves in 15 minutes! The math exam starts at 8:30!\""
	_intro_label.add_theme_font_size_override("font_size", 13)
	_intro_label.add_theme_color_override("font_color", Color.WHITE)
	_intro_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_intro_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_intro_label)

	var hint = Label.new()
	hint.text = "[Press E / SPACE to continue]"
	hint.add_theme_font_size_override("font_size", 11)
	hint.add_theme_color_override("font_color", Color(0.75, 0.75, 0.75))
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(hint)

	_intro_step = 1

func _unhandled_input(event: InputEvent) -> void:
	if _intro_step > 0:
		if event is InputEventKey and event.is_pressed() and not event.is_echo():
			if event.keycode == KEY_E or event.keycode == KEY_SPACE or event.keycode == KEY_ENTER or event.physical_keycode == KEY_E:
				_advance_intro()

func _advance_intro() -> void:
	if _intro_step == 1:
		_intro_step = 2
		_intro_title.text = "💭 ARUN (Looking into Mirror):"
		_intro_title.add_theme_color_override("font_color", Color(0.4, 0.8, 1.0))
		_intro_label.text = "\"Deep breath... Formula sheets are packed. Everyone expects top percentile, but I can't let panic freeze me. Take a breath and Bounce Back.\""
	elif _intro_step == 2:
		_intro_step = 0
		if _intro_panel:
			var tween = create_tween()
			tween.tween_property(_intro_panel, "modulate:a", 0.0, 0.25)
			tween.tween_callback(func():
				if _intro_ui:
					_intro_ui.queue_free()
					_intro_ui = null
			)
