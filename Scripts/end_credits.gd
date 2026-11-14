extends Control

## ==============================================================================
## END CREDITS SCENE: BOUNCE BACK
## Theme: Triumphant conclusion, inspiring message of lifelong resilience.
## ==============================================================================

const SceneMgr = preload("res://Scripts/scene_manager.gd")

var font_bold: Font
var font_regular: Font

var _music_player: AudioStreamPlayer
var _sfx_player: AudioStreamPlayer
var _sfx_powerup: AudioStream
var _sfx_tap: AudioStream
var _music_enabled: bool = true

# Scroll control
var _scroll_container: ScrollContainer
var _credits_vbox: VBoxContainer
var _scroll_pos: float = 0.0
var _scroll_speed: float = 38.0
var _is_fast_forward: bool = false
var _is_paused: bool = false
var _max_scroll: float = 0.0

# Hero display
var _hero_rect: TextureRect
var _hero_glow: ColorRect

# Bottom action buttons
var _action_bar: HBoxContainer
var _speed_hint: Label

func _ready() -> void:
	anchor_right = 1.0
	anchor_bottom = 1.0
	custom_minimum_size = Vector2(1280, 720)

	_load_resources()
	_build_ui()
	_start_music()

func _load_resources() -> void:
	if ResourceLoader.exists("res://assests/fonts/PixelOperator8-Bold.ttf"):
		font_bold = load("res://assests/fonts/PixelOperator8-Bold.ttf")
	if ResourceLoader.exists("res://assests/fonts/PixelOperator8.ttf"):
		font_regular = load("res://assests/fonts/PixelOperator8.ttf")

	if ResourceLoader.exists("res://assests/audio/power_up.wav"):
		_sfx_powerup = load("res://assests/audio/power_up.wav")
	if ResourceLoader.exists("res://assests/audio/tap.wav"):
		_sfx_tap = load("res://assests/audio/tap.wav")

	_music_player = AudioStreamPlayer.new()
	_music_player.bus = "Master"
	add_child(_music_player)

	if ResourceLoader.exists("res://assests/audio/time_for_adventure.mp3"):
		var music = load("res://assests/audio/time_for_adventure.mp3")
		_music_player.stream = music
		_music_player.volume_db = -8.0

	_sfx_player = AudioStreamPlayer.new()
	_sfx_player.bus = "Master"
	add_child(_sfx_player)

func _start_music() -> void:
	if _music_player and _music_player.stream and _music_enabled:
		_music_player.play()
	if _sfx_powerup and _music_enabled:
		_sfx_player.stream = _sfx_powerup
		_sfx_player.volume_db = -2.0
		_sfx_player.play()

func _play_sfx(stream: AudioStream) -> void:
	if stream and _sfx_player and _music_enabled:
		_sfx_player.stream = stream
		_sfx_player.play()

# ─────────────────────────────────────────────────────────────────────────────
# UI BUILDER
# ─────────────────────────────────────────────────────────────────────────────
func _build_ui() -> void:
	# 1. Radiant dusk/dawn sky
	var bg = ColorRect.new()
	bg.name = "Background"
	bg.color = Color(0.06, 0.05, 0.12, 1.0)
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	add_child(bg)

	var dawn_gradient = ColorRect.new()
	dawn_gradient.name = "DawnGlow"
	dawn_gradient.color = Color(0.22, 0.1, 0.18, 0.55)
	dawn_gradient.anchor_right = 1.0
	dawn_gradient.anchor_bottom = 1.0
	add_child(dawn_gradient)

	# Floating celebratory particles
	var particles = CPUParticles2D.new()
	particles.name = "CelebrationParticles"
	particles.position = Vector2(640, 740)
	particles.amount = 55
	particles.lifetime = 7.0
	particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	particles.emission_rect_extents = Vector2(640, 20)
	particles.direction = Vector2(0, -1)
	particles.spread = 25.0
	particles.gravity = Vector2(0, -12)
	particles.initial_velocity_min = 30.0
	particles.initial_velocity_max = 75.0
	particles.scale_amount_min = 2.5
	particles.scale_amount_max = 5.5
	particles.color = Color(1.0, 0.88, 0.45, 0.8)
	add_child(particles)

	# 2. Side triumphant hero display (Left side)
	var hero_card = PanelContainer.new()
	hero_card.name = "HeroCard"
	hero_card.position = Vector2(60, 100)
	hero_card.custom_minimum_size = Vector2(280, 480)
	var h_style = StyleBoxFlat.new()
	h_style.bg_color = Color(0.09, 0.1, 0.18, 0.85)
	h_style.border_color = Color(0.85, 0.65, 0.2, 0.9)
	h_style.border_width_left = 2
	h_style.border_width_right = 2
	h_style.border_width_top = 2
	h_style.border_width_bottom = 2
	h_style.corner_radius_top_left = 10
	h_style.corner_radius_top_right = 10
	h_style.corner_radius_bottom_left = 10
	h_style.corner_radius_bottom_right = 10
	h_style.content_margin_left = 16
	h_style.content_margin_right = 16
	h_style.content_margin_top = 20
	h_style.content_margin_bottom = 20
	hero_card.add_theme_stylebox_override("panel", h_style)
	add_child(hero_card)

	var h_vbox = VBoxContainer.new()
	h_vbox.add_theme_constant_override("separation", 14)
	hero_card.add_child(h_vbox)

	var h_title = Label.new()
	h_title.text = "ARUN"
	h_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	h_title.add_theme_font_size_override("font_size", 16)
	h_title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	if font_bold:
		h_title.add_theme_font_override("font", font_bold)
	h_vbox.add_child(h_title)

	var h_status = Label.new()
	h_status.text = "★ STANDING STRONG ★"
	h_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	h_status.add_theme_font_size_override("font_size", 9)
	h_status.add_theme_color_override("font_color", Color(0.4, 1.0, 0.6))
	if font_bold:
		h_status.add_theme_font_override("font", font_bold)
	h_vbox.add_child(h_status)

	_hero_rect = TextureRect.new()
	_hero_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_hero_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_hero_rect.custom_minimum_size = Vector2(240, 260)
	if ResourceLoader.exists("res://assests/Arunboy/Jump/Jump-up.png"):
		_hero_rect.texture = load("res://assests/Arunboy/Jump/Jump-up.png")
	h_vbox.add_child(_hero_rect)

	# Gentle breathing animation on hero
	var h_tween = create_tween().set_loops()
	h_tween.tween_property(_hero_rect, "scale", Vector2(1.03, 1.03), 1.5).set_trans(Tween.TRANS_SINE)
	h_tween.tween_property(_hero_rect, "scale", Vector2(1.0, 1.0), 1.5).set_trans(Tween.TRANS_SINE)

	var h_quote = Label.new()
	h_quote.text = "\"I stumbled, but I stood up.\nTomorrow, I will bounce even higher.\""
	h_quote.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	h_quote.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	h_quote.add_theme_font_size_override("font_size", 10)
	h_quote.add_theme_color_override("font_color", Color(0.8, 0.9, 1.0))
	if font_regular:
		h_quote.add_theme_font_override("font", font_regular)
	h_vbox.add_child(h_quote)

	# 3. Main Scrolling Credits Container (Center / Right)
	_scroll_container = ScrollContainer.new()
	_scroll_container.name = "CreditsScroll"
	_scroll_container.position = Vector2(380, 40)
	_scroll_container.custom_minimum_size = Vector2(840, 580)
	_scroll_container.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll_container.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	add_child(_scroll_container)

	_credits_vbox = VBoxContainer.new()
	_credits_vbox.name = "CreditsContent"
	_credits_vbox.custom_minimum_size = Vector2(810, 0)
	_credits_vbox.add_theme_constant_override("separation", 24)
	_scroll_container.add_child(_credits_vbox)

	_populate_credits_content()

	# 4. Bottom Navigation & Control Bar
	_build_bottom_bar()

func _populate_credits_content() -> void:
	# Spacer at top so it starts scrolling up gracefully
	_add_spacer(60)

	_add_header("BOUNCE BACK", 36, Color(1.0, 0.85, 0.3))
	_add_body("\"The Journey of Arun & The Power of Resilience\"", 13, Color(0.75, 0.9, 1.0))
	_add_body("A Game Jam Experience for Hack Club Haven 2026", 11, Color(0.8, 0.6, 0.3))

	_add_divider()

	_add_header("THE CORE LESSON", 18, Color(1.0, 0.7, 0.2))
	_add_body("In life, failure is not the end of the road.\nIt is simply the ground beneath your feet,\nready to push you higher than you were before.\n\nWhatever happens to your life —\nBounce back like nothing happened,\nand stay always stronger.", 12, Color(1.0, 1.0, 1.0))

	_add_divider()

	_add_header("THE STORY BEHIND THE GAME", 18, Color(1.0, 0.7, 0.2))
	_add_body("A morning of pressure and expectations.\nA math exam with terrifying stakes.\nA freeze in the classroom where words wouldn't come.\n\nYet through deep breaths and courage,\nArun discovered that falling down is temporary,\nbut the choice to bounce back is forever.", 11, Color(0.85, 0.9, 0.95))

	_add_divider()

	_add_header("DEVELOPMENT TEAM", 18, Color(1.0, 0.7, 0.2))
	_add_role_entry("Game Direction & Concept", "Hack Club Haven Team")
	_add_role_entry("GDScript & Systems", "Haven Developers")
	_add_role_entry("Pixel Art & Staging", "Haven Artists")
	_add_role_entry("Narrative & Dialogue", "Haven Storycrafters")

	_add_divider()

	_add_header("CHARACTERS & CAST", 18, Color(1.0, 0.7, 0.2))
	_add_role_entry("Arun", "A teenager learning to conquer anxiety")
	_add_role_entry("Mom", "The morning warmth & firm encouragement")
	_add_role_entry("Ms. Das", "The strict teacher with high standards")
	_add_role_entry("Kabir", "The friend who reminds you who you are")

	_add_divider()

	_add_header("ASSETS & ATTRIBUTIONS", 18, Color(1.0, 0.7, 0.2))
	_add_role_entry("Cute Fantasy Pack", "Tiles, props, and environment sprites")
	_add_role_entry("Arun Sprite Set", "Original jumping boy artwork")
	_add_role_entry("Brackeys Audio & Fonts", "PixelOperator8 & Retro Sound Effects")
	_add_role_entry("Engine", "Godot Engine 4.7 Forward+ / GL Compatibility")

	_add_divider()

	_add_header("SPECIAL THANKS", 18, Color(1.0, 0.7, 0.2))
	_add_body("To the Hack Club Haven Mentors & Organizers\nfor creating the space where creators dare to build.", 11, Color(0.9, 0.85, 0.6))
	_add_body("\nTo every student, dreamer, and gamer\nwho ever felt the weight of expectations...", 11, Color(0.8, 0.9, 1.0))
	_add_body("\nAND TO YOU, THE PLAYER:\nThank you for playing.\nNever stop bouncing back.", 14, Color(1.0, 0.9, 0.35))

	_add_divider()

	_add_header("HC — HACK CLUB HAVEN", 16, Color(0.9, 0.6, 0.2))
	_add_body("2026 • Made with Heart in 24 Hours", 10, Color(0.6, 0.65, 0.75))

	# Bottom spacer
	_add_spacer(140)

func _add_header(text: String, size: int, col: Color) -> void:
	var l = Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	if font_bold:
		l.add_theme_font_override("font", font_bold)
	_credits_vbox.add_child(l)

func _add_body(text: String, size: int, col: Color) -> void:
	var l = Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	if font_regular:
		l.add_theme_font_override("font", font_regular)
	_credits_vbox.add_child(l)

func _add_role_entry(role: String, name_str: String) -> void:
	var hbox = HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 20)

	var r = Label.new()
	r.text = role
	r.custom_minimum_size = Vector2(360, 24)
	r.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	r.add_theme_font_size_override("font_size", 11)
	r.add_theme_color_override("font_color", Color(1.0, 0.85, 0.4))
	if font_bold:
		r.add_theme_font_override("font", font_bold)
	hbox.add_child(r)

	var n = Label.new()
	n.text = name_str
	n.custom_minimum_size = Vector2(360, 24)
	n.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	n.add_theme_font_size_override("font_size", 11)
	n.add_theme_color_override("font_color", Color(0.9, 0.95, 1.0))
	if font_regular:
		n.add_theme_font_override("font", font_regular)
	hbox.add_child(n)

	_credits_vbox.add_child(hbox)

func _add_divider() -> void:
	var d = Label.new()
	d.text = "✦  ━━━━━━━━━━━━━━━━━━  ✦"
	d.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	d.add_theme_font_size_override("font_size", 10)
	d.add_theme_color_override("font_color", Color(0.5, 0.4, 0.7, 0.6))
	if font_regular:
		d.add_theme_font_override("font", font_regular)
	_credits_vbox.add_child(d)

func _add_spacer(h: int) -> void:
	var s = Control.new()
	s.custom_minimum_size = Vector2(0, h)
	_credits_vbox.add_child(s)

func _build_bottom_bar() -> void:
	var bar_panel = PanelContainer.new()
	bar_panel.position = Vector2(0, 640)
	bar_panel.custom_minimum_size = Vector2(1280, 80)
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.06, 0.1, 0.95)
	style.border_color = Color(0.3, 0.35, 0.5, 0.5)
	style.border_width_top = 2
	bar_panel.add_theme_stylebox_override("panel", style)
	add_child(bar_panel)

	_action_bar = HBoxContainer.new()
	_action_bar.position = Vector2(40, 655)
	_action_bar.custom_minimum_size = Vector2(1200, 50)
	_action_bar.add_theme_constant_override("separation", 20)
	add_child(_action_bar)

	var replay_btn = Button.new()
	replay_btn.text = "🔄 PLAY AGAIN"
	replay_btn.custom_minimum_size = Vector2(220, 44)
	_style_button(replay_btn, Color(0.85, 0.55, 0.1), Color(1.0, 0.85, 0.4), 12)
	replay_btn.pressed.connect(_on_replay_pressed)
	_action_bar.add_child(replay_btn)

	var title_btn = Button.new()
	title_btn.text = "🏠 TITLE SCREEN"
	title_btn.custom_minimum_size = Vector2(220, 44)
	_style_button(title_btn, Color(0.2, 0.25, 0.4), Color(0.7, 0.85, 1.0), 12)
	title_btn.pressed.connect(_on_title_pressed)
	_action_bar.add_child(title_btn)

	_speed_hint = Label.new()
	_speed_hint.text = "Hold [SPACE] to Speed Up • [P] to Pause"
	_speed_hint.custom_minimum_size = Vector2(450, 44)
	_speed_hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_speed_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_speed_hint.add_theme_font_size_override("font_size", 10)
	_speed_hint.add_theme_color_override("font_color", Color(0.65, 0.7, 0.8))
	if font_regular:
		_speed_hint.add_theme_font_override("font", font_regular)
	_action_bar.add_child(_speed_hint)

	var music_btn = Button.new()
	music_btn.text = "🔊 AUDIO"
	music_btn.custom_minimum_size = Vector2(140, 44)
	_style_button(music_btn, Color(0.15, 0.18, 0.25), Color(0.7, 0.7, 0.8), 10)
	music_btn.pressed.connect(_toggle_music)
	_action_bar.add_child(music_btn)

func _style_button(btn: Button, bg_col: Color, text_col: Color, font_size: int = 12) -> void:
	var style_normal = StyleBoxFlat.new()
	style_normal.bg_color = bg_col
	style_normal.border_color = bg_col.lightened(0.3)
	style_normal.border_width_bottom = 3
	style_normal.corner_radius_top_left = 6
	style_normal.corner_radius_top_right = 6
	style_normal.corner_radius_bottom_left = 6
	style_normal.corner_radius_bottom_right = 6
	btn.add_theme_stylebox_override("normal", style_normal)

	var style_hover = StyleBoxFlat.new()
	style_hover.bg_color = bg_col.lightened(0.2)
	style_hover.border_color = Color(1.0, 0.9, 0.5)
	style_hover.border_width_bottom = 3
	style_hover.corner_radius_top_left = 6
	style_hover.corner_radius_top_right = 6
	style_hover.corner_radius_bottom_left = 6
	style_hover.corner_radius_bottom_right = 6
	btn.add_theme_stylebox_override("hover", style_hover)

	btn.add_theme_color_override("font_color", text_col)
	btn.add_theme_color_override("font_hover_color", Color.WHITE)
	btn.add_theme_font_size_override("font_size", font_size)
	if font_bold:
		btn.add_theme_font_override("font", font_bold)

# ─────────────────────────────────────────────────────────────────────────────
# SCROLL LOGIC
# ─────────────────────────────────────────────────────────────────────────────
func _process(delta: float) -> void:
	if _is_paused:
		return

	var current_speed = _scroll_speed
	if _is_fast_forward:
		current_speed *= 3.5

	_scroll_pos += current_speed * delta
	_scroll_container.scroll_vertical = int(_scroll_pos)

	# If scrolled to bottom, gently loop or hold
	var v_bar = _scroll_container.get_v_scroll_bar()
	if v_bar and _scroll_pos > v_bar.max_value:
		_scroll_pos = v_bar.max_value

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.keycode == KEY_SPACE or event.keycode == KEY_DOWN:
			_is_fast_forward = event.is_pressed()
		elif event.keycode == KEY_P and event.is_pressed() and not event.is_echo():
			_is_paused = not _is_paused
			_speed_hint.text = "⏸ PAUSED — Press [P] to Resume" if _is_paused else "Hold [SPACE] to Speed Up • [P] to Pause"
		elif event.keycode == KEY_ESCAPE and event.is_pressed() and not event.is_echo():
			_on_title_pressed()

func _on_replay_pressed() -> void:
	_play_sfx(_sfx_tap)
	SceneMgr.transition_to("res://Scence/House.tscn")

func _on_title_pressed() -> void:
	_play_sfx(_sfx_tap)
	SceneMgr.transition_to("res://Scence/Intro.tscn")

func _toggle_music() -> void:
	_music_enabled = not _music_enabled
	if _music_enabled:
		_start_music()
	else:
		if _music_player:
			_music_player.stop()
