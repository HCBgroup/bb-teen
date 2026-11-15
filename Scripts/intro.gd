extends Control

## ==============================================================================
## INTRO & TITLE SCENE: BOUNCE BACK
## Theme: Resilience, rising stronger after failure, bouncing back like nothing happened.
## ==============================================================================

const SceneMgr = preload("res://Scripts/scene_manager.gd")

# Font references
var font_bold: Font
var font_regular: Font

# Audio players
var _music_player: AudioStreamPlayer
var _sfx_player: AudioStreamPlayer
var _sfx_jump: AudioStream
var _sfx_powerup: AudioStream
var _sfx_tap: AudioStream

# State
enum State { PROLOGUE, TITLE }
var _current_state: State = State.PROLOGUE
var _prologue_index: int = 0
var _bounce_count: int = 0
var _is_animating: bool = false
var _music_enabled: bool = true

# Node references
var _prologue_layer: Control
var _prologue_text: Label
var _prologue_subtext: Label
var _prologue_skip_btn: Button
var _prologue_hero: TextureRect

var _title_layer: Control
var _title_label: Label
var _tagline_label: Label
var _hero_container: Control
var _hero_sprite: TextureRect
var _hero_shadow: ColorRect
var _bounce_hint_label: Label
var _bounce_counter_label: Label
var _quote_popup: PanelContainer
var _music_toggle_btn: Button

# Motivational lines during prologue
var _prologue_slides = [
	{
		"main": "In life, falling down is inevitable.",
		"sub": "Expectations rise high. Fear creeps in. Sometimes, you stumble.",
		"hero_texture": "res://assests/Arunboy/Jump/Jump-fall.png",
		"hero_color": Color(0.7, 0.7, 0.85, 0.8)
	},
	{
		"main": "A bad grade. A harsh word. A moment where you freeze.",
		"sub": "The world tells you to stay down. The mirror asks if you are enough.",
		"hero_texture": "res://assests/Arunboy/Idle/frame-2.png",
		"hero_color": Color(0.8, 0.8, 0.9, 0.9)
	},
	{
		"main": "But gravity only exists so you have something to push against.",
		"sub": "Every setback is not a full stop — it's tension pulling back a slingshot.",
		"hero_texture": "res://assests/Arunboy/Jump/Jump-fall.png",
		"hero_color": Color(1.0, 0.9, 0.5, 1.0)
	},
	{
		"main": "Whatever happens to your life...",
		"sub": "Shake off the dust. Breathe in deep.",
		"hero_texture": "res://assests/Arunboy/Idle/frame-1.png",
		"hero_color": Color(1.0, 0.95, 0.7, 1.0)
	},
	{
		"main": "BOUNCE BACK LIKE NOTHING HAPPENED.",
		"sub": "AND STAND ALWAYS STRONGER.",
		"hero_texture": "res://assests/Arunboy/Jump/Jump-up.png",
		"hero_color": Color(1.0, 1.0, 1.0, 1.0)
	}
]

var _bounce_cheers = [
	"\"Nothing can keep me down!\"",
	"\"Rise again!\"",
	"\"Stronger than before!\"",
	"\"Every fall is just a spring!\"",
	"\"Bounce back like nothing happened!\"",
	"\"Always moving forward!\"",
	"\"Resilience is my power!\""
]

func _ready() -> void:
	# Configure root
	anchor_right = 1.0
	anchor_bottom = 1.0
	custom_minimum_size = Vector2(1280, 720)

	_load_resources()
	_build_ui()
	_start_music()
	_show_prologue_slide(0)

func _load_resources() -> void:
	# Fonts
	if ResourceLoader.exists("res://assests/fonts/PixelOperator8-Bold.ttf"):
		font_bold = load("res://assests/fonts/PixelOperator8-Bold.ttf")
	if ResourceLoader.exists("res://assests/fonts/PixelOperator8.ttf"):
		font_regular = load("res://assests/fonts/PixelOperator8.ttf")

	# Audio
	if ResourceLoader.exists("res://assests/audio/jump.wav"):
		_sfx_jump = load("res://assests/audio/jump.wav")
	if ResourceLoader.exists("res://assests/audio/power_up.wav"):
		_sfx_powerup = load("res://assests/audio/power_up.wav")
	if ResourceLoader.exists("res://assests/audio/tap.wav"):
		_sfx_tap = load("res://assests/audio/tap.wav")

	# Audio Players
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

func _play_sfx(stream: AudioStream, vol_db: float = 0.0) -> void:
	if stream and _sfx_player and _music_enabled:
		_sfx_player.stream = stream
		_sfx_player.volume_db = vol_db
		_sfx_player.play()

# ─────────────────────────────────────────────────────────────────────────────
# UI BUILDER
# ─────────────────────────────────────────────────────────────────────────────
func _build_ui() -> void:
	# 1. Background gradient & star embers
	_build_background()

	# 2. Prologue layer
	_build_prologue_layer()

	# 3. Title layer
	_build_title_layer()

	# 4. Resilience Code Popup
	_build_quote_popup()

func _build_background() -> void:
	# Deep sky canvas
	var bg = ColorRect.new()
	bg.name = "Background"
	bg.color = Color(0.05, 0.06, 0.12, 1.0)
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	add_child(bg)

	# Atmospheric vignette / gradient overlay
	var overlay = ColorRect.new()
	overlay.name = "Atmosphere"
	overlay.color = Color(0.12, 0.09, 0.22, 0.5)
	overlay.anchor_right = 1.0
	overlay.anchor_bottom = 1.0
	add_child(overlay)

	# Rising hope particles (golden embers drifting up)
	var particles = CPUParticles2D.new()
	particles.name = "HopeParticles"
	particles.position = Vector2(640, 740)
	particles.amount = 45
	particles.lifetime = 6.0
	particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	particles.emission_rect_extents = Vector2(640, 20)
	particles.direction = Vector2(0, -1)
	particles.spread = 20.0
	particles.gravity = Vector2(0, -15)
	particles.initial_velocity_min = 25.0
	particles.initial_velocity_max = 60.0
	particles.scale_amount_min = 2.0
	particles.scale_amount_max = 5.0
	particles.color = Color(1.0, 0.85, 0.4, 0.7)
	add_child(particles)

func _build_prologue_layer() -> void:
	_prologue_layer = Control.new()
	_prologue_layer.name = "PrologueLayer"
	_prologue_layer.anchor_right = 1.0
	_prologue_layer.anchor_bottom = 1.0
	add_child(_prologue_layer)

	# Hero sprite during prologue
	_prologue_hero = TextureRect.new()
	_prologue_hero.name = "PrologueHero"
	_prologue_hero.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_prologue_hero.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_prologue_hero.custom_minimum_size = Vector2(160, 200)
	_prologue_hero.position = Vector2(560, 140)
	_prologue_layer.add_child(_prologue_hero)

	# Text container
	var vbox = VBoxContainer.new()
	vbox.name = "TextContainer"
	vbox.anchor_left = 0.5
	vbox.anchor_top = 0.5
	vbox.anchor_right = 0.5
	vbox.anchor_bottom = 0.5
	vbox.offset_left = -500
	vbox.offset_top = 50
	vbox.offset_right = 500
	vbox.offset_bottom = 230
	vbox.add_theme_constant_override("separation", 18)
	_prologue_layer.add_child(vbox)

	_prologue_text = Label.new()
	_prologue_text.text = ""
	_prologue_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prologue_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_prologue_text.add_theme_font_size_override("font_size", 24)
	_prologue_text.add_theme_color_override("font_color", Color(1.0, 0.92, 0.4))
	if font_bold:
		_prologue_text.add_theme_font_override("font", font_bold)
	vbox.add_child(_prologue_text)

	_prologue_subtext = Label.new()
	_prologue_subtext.text = ""
	_prologue_subtext.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prologue_subtext.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_prologue_subtext.add_theme_font_size_override("font_size", 14)
	_prologue_subtext.add_theme_color_override("font_color", Color(0.85, 0.88, 0.95))
	if font_regular:
		_prologue_subtext.add_theme_font_override("font", font_regular)
	vbox.add_child(_prologue_subtext)

	# Bottom instructions
	var next_hint = Label.new()
	next_hint.text = "Press [SPACE] or Click to Continue"
	next_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	next_hint.add_theme_font_size_override("font_size", 11)
	next_hint.add_theme_color_override("font_color", Color(0.6, 0.65, 0.75))
	if font_regular:
		next_hint.add_theme_font_override("font", font_regular)
	vbox.add_child(next_hint)

	# Skip button (top right)
	_prologue_skip_btn = Button.new()
	_prologue_skip_btn.text = "SKIP PROLOGUE >>"
	_prologue_skip_btn.position = Vector2(1080, 25)
	_prologue_skip_btn.custom_minimum_size = Vector2(170, 36)
	_style_button(_prologue_skip_btn, Color(0.2, 0.22, 0.32), Color(0.8, 0.6, 0.2))
	_prologue_skip_btn.pressed.connect(_transition_to_title)
	_prologue_layer.add_child(_prologue_skip_btn)

func _build_title_layer() -> void:
	_title_layer = Control.new()
	_title_layer.name = "TitleLayer"
	_title_layer.anchor_right = 1.0
	_title_layer.anchor_bottom = 1.0
	_title_layer.visible = false
	_title_layer.modulate.a = 0.0
	add_child(_title_layer)

	# Hack Club Haven badge
	var badge = Label.new()
	badge.text = "HC — HACK CLUB HAVEN PRESENTS"
	badge.position = Vector2(0, 35)
	badge.custom_minimum_size = Vector2(1280, 30)
	badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge.add_theme_font_size_override("font_size", 12)
	badge.add_theme_color_override("font_color", Color(0.9, 0.7, 0.2))
	if font_bold:
		badge.add_theme_font_override("font", font_bold)
	_title_layer.add_child(badge)

	# Giant Title
	_title_label = Label.new()
	_title_label.name = "TitleLabel"
	_title_label.text = "BOUNCE BACK"
	_title_label.position = Vector2(0, 65)
	_title_label.custom_minimum_size = Vector2(1280, 70)
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.add_theme_font_size_override("font_size", 54)
	_title_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.25))
	_title_label.add_theme_color_override("font_shadow_color", Color(0.8, 0.2, 0.1, 0.8))
	_title_label.add_theme_constant_override("shadow_offset_x", 4)
	_title_label.add_theme_constant_override("shadow_offset_y", 4)
	if font_bold:
		_title_label.add_theme_font_override("font", font_bold)
	_title_layer.add_child(_title_label)

	var creators_panel = PanelContainer.new()
	var c_style = StyleBoxFlat.new()
	c_style.bg_color = Color(0.09, 0.12, 0.2, 0.9)
	c_style.border_color = Color(0.9, 0.72, 0.25, 0.95)
	c_style.border_width_left = 2
	c_style.border_width_right = 2
	c_style.border_width_top = 2
	c_style.border_width_bottom = 2
	c_style.corner_radius_top_left = 6
	c_style.corner_radius_top_right = 6
	c_style.corner_radius_bottom_left = 6
	c_style.corner_radius_bottom_right = 6
	c_style.content_margin_left = 20
	c_style.content_margin_right = 20
	c_style.content_margin_top = 6
	c_style.content_margin_bottom = 6
	creators_panel.add_theme_stylebox_override("panel", c_style)
	creators_panel.position = Vector2(240, 140)
	creators_panel.custom_minimum_size = Vector2(800, 38)
	_title_layer.add_child(creators_panel)

	var c_vbox = VBoxContainer.new()
	c_vbox.add_theme_constant_override("separation", 2)
	creators_panel.add_child(c_vbox)

	var creators_lbl = Label.new()
	creators_lbl.text = "* CREATED BY: EVIN JACOB SUBIN  -  AIZEL LINTO  -  JAY KRISHNA *"
	creators_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	creators_lbl.add_theme_font_size_override("font_size", 11)
	creators_lbl.add_theme_color_override("font_color", Color(1.0, 0.9, 0.45))
	if font_bold:
		creators_lbl.add_theme_font_override("font", font_bold)
	c_vbox.add_child(creators_lbl)

	var jam_lbl = Label.new()
	jam_lbl.text = "Built in 24 Hours at Hack Club Haven • Ready to Ship on itch.io"
	jam_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	jam_lbl.add_theme_font_size_override("font_size", 10)
	jam_lbl.add_theme_color_override("font_color", Color(0.65, 0.85, 1.0))
	if font_regular:
		jam_lbl.add_theme_font_override("font", font_regular)
	c_vbox.add_child(jam_lbl)

	# Tagline
	_tagline_label = Label.new()
	_tagline_label.text = "\"Whatever happens in life, bounce back like nothing happened and stay always stronger.\""
	_tagline_label.position = Vector2(140, 195)
	_tagline_label.custom_minimum_size = Vector2(1000, 30)
	_tagline_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_tagline_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_tagline_label.add_theme_font_size_override("font_size", 11)
	_tagline_label.add_theme_color_override("font_color", Color(0.8, 0.9, 0.95))
	if font_regular:
		_tagline_label.add_theme_font_override("font", font_regular)
	_title_layer.add_child(_tagline_label)

	# Character Centerpiece with Interactive Bounce!
	_hero_container = Control.new()
	_hero_container.name = "HeroContainer"
	_hero_container.position = Vector2(565, 235)
	_hero_container.custom_minimum_size = Vector2(150, 190)
	_title_layer.add_child(_hero_container)

	_hero_shadow = ColorRect.new()
	_hero_shadow.color = Color(0.0, 0.0, 0.0, 0.4)
	_hero_shadow.position = Vector2(25, 175)
	_hero_shadow.custom_minimum_size = Vector2(100, 12)
	_hero_container.add_child(_hero_shadow)

	_hero_sprite = TextureRect.new()
	_hero_sprite.name = "HeroSprite"
	if ResourceLoader.exists("res://assests/Arunboy/Idle/frame-1.png"):
		_hero_sprite.texture = load("res://assests/Arunboy/Idle/frame-1.png")
	_hero_sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_hero_sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_hero_sprite.custom_minimum_size = Vector2(150, 180)
	_hero_sprite.position = Vector2(0, 0)
	_hero_container.add_child(_hero_sprite)

	# Interactive bounce prompt under hero
	_bounce_hint_label = Label.new()
	_bounce_hint_label.text = "Press [SPACE] to Test Your Bounce!"
	_bounce_hint_label.position = Vector2(-150, 195)
	_bounce_hint_label.custom_minimum_size = Vector2(450, 24)
	_bounce_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_bounce_hint_label.add_theme_font_size_override("font_size", 10)
	_bounce_hint_label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.3))
	if font_bold:
		_bounce_hint_label.add_theme_font_override("font", font_bold)
	_hero_container.add_child(_bounce_hint_label)

	_bounce_counter_label = Label.new()
	_bounce_counter_label.text = ""
	_bounce_counter_label.position = Vector2(-200, 222)
	_bounce_counter_label.custom_minimum_size = Vector2(550, 24)
	_bounce_counter_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_bounce_counter_label.add_theme_font_size_override("font_size", 11)
	_bounce_counter_label.add_theme_color_override("font_color", Color(0.4, 1.0, 0.6))
	if font_regular:
		_bounce_counter_label.add_theme_font_override("font", font_regular)
	_hero_container.add_child(_bounce_counter_label)

	# Menu Buttons Container
	var menu_vbox = VBoxContainer.new()
	menu_vbox.name = "MenuContainer"
	menu_vbox.position = Vector2(440, 500)
	menu_vbox.custom_minimum_size = Vector2(400, 180)
	menu_vbox.add_theme_constant_override("separation", 14)
	_title_layer.add_child(menu_vbox)

	var start_btn = Button.new()
	start_btn.text = "▶ BEGIN JOURNEY"
	start_btn.custom_minimum_size = Vector2(400, 48)
	_style_button(start_btn, Color(0.85, 0.55, 0.1), Color(1.0, 0.85, 0.4), 16)
	start_btn.pressed.connect(_on_start_pressed)
	menu_vbox.add_child(start_btn)

	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 14)
	menu_vbox.add_child(hbox)

	var code_btn = Button.new()
	code_btn.text = "RESILIENCE CODE"
	code_btn.custom_minimum_size = Vector2(193, 40)
	_style_button(code_btn, Color(0.2, 0.25, 0.4), Color(0.6, 0.8, 1.0), 10)
	code_btn.pressed.connect(_show_quote_popup)
	hbox.add_child(code_btn)

	var credits_btn = Button.new()
	credits_btn.text = "CREDITS"
	credits_btn.custom_minimum_size = Vector2(193, 40)
	_style_button(credits_btn, Color(0.2, 0.25, 0.4), Color(0.6, 0.8, 1.0), 10)
	credits_btn.pressed.connect(_on_credits_pressed)
	hbox.add_child(credits_btn)

	# Bottom Audio Toggle
	_music_toggle_btn = Button.new()
	_music_toggle_btn.text = "MUSIC: ON"
	_music_toggle_btn.position = Vector2(30, 670)
	_music_toggle_btn.custom_minimum_size = Vector2(140, 32)
	_style_button(_music_toggle_btn, Color(0.15, 0.18, 0.25), Color(0.7, 0.7, 0.8), 9)
	_music_toggle_btn.pressed.connect(_toggle_music)
	_title_layer.add_child(_music_toggle_btn)

	# Version/Haven label bottom right
	var foot = Label.new()
	foot.text = "Hack Club Haven 2026 • 24hr Jam"
	foot.position = Vector2(980, 680)
	foot.custom_minimum_size = Vector2(270, 25)
	foot.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	foot.add_theme_font_size_override("font_size", 9)
	foot.add_theme_color_override("font_color", Color(0.5, 0.55, 0.65))
	if font_regular:
		foot.add_theme_font_override("font", font_regular)
	_title_layer.add_child(foot)

func _build_quote_popup() -> void:
	_quote_popup = PanelContainer.new()
	_quote_popup.name = "QuotePopup"
	_quote_popup.anchor_left = 0.5
	_quote_popup.anchor_top = 0.5
	_quote_popup.anchor_right = 0.5
	_quote_popup.anchor_bottom = 0.5
	_quote_popup.offset_left = -380
	_quote_popup.offset_top = -220
	_quote_popup.offset_right = 380
	_quote_popup.offset_bottom = 220
	_quote_popup.visible = false

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.1, 0.16, 0.98)
	style.border_color = Color(0.9, 0.7, 0.2, 1.0)
	style.border_width_left = 3
	style.border_width_right = 3
	style.border_width_top = 3
	style.border_width_bottom = 3
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	style.content_margin_left = 28
	style.content_margin_right = 28
	style.content_margin_top = 24
	style.content_margin_bottom = 24
	_quote_popup.add_theme_stylebox_override("panel", style)
	add_child(_quote_popup)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	_quote_popup.add_child(vbox)

	var qtitle = Label.new()
	qtitle.text = "THE CODE OF RESILIENCE"
	qtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	qtitle.add_theme_font_size_override("font_size", 16)
	qtitle.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	if font_bold:
		qtitle.add_theme_font_override("font", font_bold)
	vbox.add_child(qtitle)

	var qbody = Label.new()
	qbody.text = "1. ACCEPT THE STUMBLE:\nA fall is an event, not an identity. Everyone falls.\n\n2. SHAKE OFF THE DUST:\nReset your mind instantly. Do not let regret rob tomorrow's strength.\n\n3. BOUNCE BACK STRONGER:\nWhen you push back up from the ground, you discover muscle and courage you never knew was there.\n\n\"Stay Always Stronger.\""
	qbody.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	qbody.add_theme_font_size_override("font_size", 11)
	qbody.add_theme_color_override("font_color", Color(0.9, 0.95, 1.0))
	if font_regular:
		qbody.add_theme_font_override("font", font_regular)
	vbox.add_child(qbody)

	var close_btn = Button.new()
	close_btn.text = "I WILL BOUNCE BACK"
	close_btn.custom_minimum_size = Vector2(240, 38)
	close_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_style_button(close_btn, Color(0.8, 0.5, 0.1), Color(1.0, 0.9, 0.4), 11)
	close_btn.pressed.connect(func(): _quote_popup.visible = false)
	vbox.add_child(close_btn)

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
# LOGIC & ANIMATIONS
# ─────────────────────────────────────────────────────────────────────────────
func _show_prologue_slide(idx: int) -> void:
	if idx >= _prologue_slides.size():
		_transition_to_title()
		return

	_is_animating = true
	var slide = _prologue_slides[idx]

	# Load hero frame
	if ResourceLoader.exists(slide["hero_texture"]):
		_prologue_hero.texture = load(slide["hero_texture"])
	_prologue_hero.modulate = slide["hero_color"]

	# Fade in text
	_prologue_text.modulate.a = 0.0
	_prologue_subtext.modulate.a = 0.0
	_prologue_hero.modulate.a = 0.0

	_prologue_text.text = slide["main"]
	_prologue_subtext.text = slide["sub"]

	var tween = create_tween()
	tween.tween_property(_prologue_hero, "modulate:a", 1.0, 0.4)
	tween.parallel().tween_property(_prologue_text, "modulate:a", 1.0, 0.4)
	tween.parallel().tween_property(_prologue_subtext, "modulate:a", 1.0, 0.6)
	tween.tween_callback(func(): _is_animating = false)

	if idx == _prologue_slides.size() - 1:
		_play_sfx(_sfx_powerup, -3.0)

func _transition_to_title() -> void:
	if _current_state == State.TITLE:
		return
	_current_state = State.TITLE

	_play_sfx(_sfx_powerup, 0.0)

	var tween = create_tween()
	tween.tween_property(_prologue_layer, "modulate:a", 0.0, 0.4)
	tween.tween_callback(func():
		_prologue_layer.visible = false
		_title_layer.visible = true
	)
	tween.tween_property(_title_layer, "modulate:a", 1.0, 0.6)

	# Gentle bouncing loop for title label
	var b_tween = create_tween().set_loops()
	b_tween.tween_property(_title_label, "position:y", 70.0, 1.2).set_trans(Tween.TRANS_SINE)
	b_tween.tween_property(_title_label, "position:y", 80.0, 1.2).set_trans(Tween.TRANS_SINE)

func _do_interactive_bounce() -> void:
	_bounce_count += 1
	_play_sfx(_sfx_jump, 2.0)

	# Change sprite to jump-up during ascent
	if ResourceLoader.exists("res://assests/Arunboy/Jump/Jump-up.png"):
		_hero_sprite.texture = load("res://assests/Arunboy/Jump/Jump-up.png")

	var cheer = _bounce_cheers[_bounce_count % _bounce_cheers.size()]
	_bounce_counter_label.text = "Bounce #%d: %s" % [_bounce_count, cheer]

	# Launch jump tween
	var tween = create_tween()
	# Upward launch with stretch
	tween.tween_property(_hero_sprite, "position:y", -70.0, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(_hero_shadow, "scale", Vector2(0.6, 0.6), 0.22)
	# Downward fall with squash
	tween.tween_property(_hero_sprite, "position:y", 0.0, 0.20).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(_hero_shadow, "scale", Vector2(1.0, 1.0), 0.20)
	# Return to idle frame
	tween.tween_callback(func():
		if ResourceLoader.exists("res://assests/Arunboy/Idle/frame-1.png"):
			_hero_sprite.texture = load("res://assests/Arunboy/Idle/frame-1.png")
	)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.is_pressed() and not event.is_echo():
		if event.keycode == KEY_SPACE or event.keycode == KEY_ENTER:
			if _current_state == State.PROLOGUE:
				if not _is_animating:
					_prologue_index += 1
					_show_prologue_slide(_prologue_index)
			elif _current_state == State.TITLE:
				_do_interactive_bounce()
		elif event.keycode == KEY_ESCAPE:
			if _quote_popup.visible:
				_quote_popup.visible = false

	elif event is InputEventMouseButton and event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT:
		if _current_state == State.PROLOGUE and not _is_animating:
			_prologue_index += 1
			_show_prologue_slide(_prologue_index)

func _on_start_pressed() -> void:
	_play_sfx(_sfx_tap)
	SceneMgr.transition_to("res://Scence/House.tscn")

func _on_credits_pressed() -> void:
	_play_sfx(_sfx_tap)
	SceneMgr.transition_to("res://Scence/EndCredits.tscn")

func _show_quote_popup() -> void:
	_play_sfx(_sfx_tap)
	_quote_popup.visible = true

func _toggle_music() -> void:
	_music_enabled = not _music_enabled
	if _music_enabled:
		_music_toggle_btn.text = "MUSIC: ON"
		_start_music()
	else:
		_music_toggle_btn.text = "MUSIC: OFF"
		if _music_player:
			_music_player.stop()
