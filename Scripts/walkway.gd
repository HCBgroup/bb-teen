extends Node2D

## Morning Dash Platformer Runner level controller.
## Arun dashes to school, jumps across platforms, and collects Motivation Coins.

const SceneMgr = preload("res://Scripts/scene_manager.gd")

@onready var player: PlatformerPlayer = $PlatformerPlayer
@onready var hud_layer: CanvasLayer = $HUD

# HUD elements
var _hud_panel: PanelContainer
var _coin_label: Label
var _motivation_bar: ProgressBar
var _status_label: Label
var _tip_label: Label

var total_coins: int = 16
var collected_coins: int = 0

func _ready() -> void:
	# Configure player camera bounds for wide 2800px platformer level
	if player and player.camera:
		player.camera.limit_left = 0
		player.camera.limit_top = 0
		player.camera.limit_right = 2800
		player.camera.limit_bottom = 720
		player.camera.zoom = Vector2(1.25, 1.25)

	_build_hud()

	var door: String = SceneMgr.get_target_door()
	if door == "from_school":
		if player:
			player.global_position = Vector2(2500, 560)
	else:
		# Starting run from home towards school
		if player:
			player.global_position = Vector2(120, 560)

	# Start background music
	var audio_mgr = get_node_or_null("/root/AudioManager")
	if audio_mgr and audio_mgr.has_method("start_bgm"):
		audio_mgr.start_bgm()

func _build_hud() -> void:
	if not hud_layer:
		hud_layer = CanvasLayer.new()
		hud_layer.name = "HUD"
		add_child(hud_layer)

	_hud_panel = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.1, 0.16, 0.88)
	style.border_color = Color(0.9, 0.75, 0.25, 1.0)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	_hud_panel.add_theme_stylebox_override("panel", style)
	_hud_panel.position = Vector2(24, 20)
	hud_layer.add_child(_hud_panel)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	_hud_panel.add_child(vbox)

	# Mission Header
	var title = Label.new()
	title.text = "⚡ MORNING DASH TO SCHOOL"
	title.add_theme_font_size_override("font_size", 12)
	title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	title.add_theme_color_override("font_shadow_color", Color.BLACK)
	vbox.add_child(title)

	# Motivation / Focus Bar
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 8)
	vbox.add_child(hbox)

	var bar_lbl = Label.new()
	bar_lbl.text = "Focus:"
	bar_lbl.add_theme_font_size_override("font_size", 11)
	bar_lbl.add_theme_color_override("font_color", Color(0.85, 0.85, 0.9))
	hbox.add_child(bar_lbl)

	_motivation_bar = ProgressBar.new()
	_motivation_bar.custom_minimum_size = Vector2(160, 16)
	_motivation_bar.max_value = 100.0
	_motivation_bar.value = 15.0 # Starting base focus
	_motivation_bar.show_percentage = false
	hbox.add_child(_motivation_bar)

	# Coin Counter
	_coin_label = Label.new()
	_coin_label.text = "🪙 0 / %d" % total_coins
	_coin_label.add_theme_font_size_override("font_size", 12)
	_coin_label.add_theme_color_override("font_color", Color(1.0, 0.95, 0.4))
	_coin_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	hbox.add_child(_coin_label)

	# Status text
	_status_label = Label.new()
	_status_label.text = "Gather motivation sparks before the bell rings!"
	_status_label.add_theme_font_size_override("font_size", 10)
	_status_label.add_theme_color_override("font_color", Color(0.7, 0.8, 0.9))
	vbox.add_child(_status_label)

	# Controls Tip Banner in center bottom
	_tip_label = Label.new()
	_tip_label.text = "[A / D] or [ARROWS] Run   •   [SPACE] or [W] Jump"
	_tip_label.add_theme_font_size_override("font_size", 12)
	_tip_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.8))
	_tip_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	_tip_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_tip_label.anchor_left = 0.5
	_tip_label.anchor_right = 0.5
	_tip_label.anchor_top = 1.0
	_tip_label.anchor_bottom = 1.0
	_tip_label.offset_left = -200
	_tip_label.offset_top = -45
	_tip_label.offset_right = 200
	_tip_label.offset_bottom = -20
	hud_layer.add_child(_tip_label)

func on_coin_collected(amount: int) -> void:
	collected_coins += 1
	var pct = clampf(15.0 + (float(collected_coins) / float(total_coins)) * 85.0, 0.0, 100.0)

	var tw = create_tween().set_parallel(true)
	tw.tween_property(_motivation_bar, "value", pct, 0.25).set_trans(Tween.TRANS_CUBIC)

	_coin_label.text = "🪙 %d / %d" % [collected_coins, total_coins]

	if collected_coins == total_coins / 2:
		_status_label.text = "⚡ Halfway! Momentum building! Keep running!"
		_status_label.add_theme_color_override("font_color", Color(0.4, 1.0, 0.6))
	elif collected_coins >= total_coins:
		_status_label.text = "✨ MAX FOCUS! Arun is fully ready to Bounce Back!"
		_status_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
