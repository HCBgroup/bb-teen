class_name GameNPC
extends StaticBody2D

## Interactive NPC with a stylish head-hovering dialogue speech box,
## retro typewriter chatter SFX, native OS TTS support, and physical collision.

@export var dialogue_lines: PackedStringArray = ["Hello!", "Nice day, isn't it?"]
@export var npc_name: String = "Student"
@export var sprite_texture: Texture2D
@export var talk_pitch: float = 1.0

var _player_in_range: bool = false
var _is_speaking: bool = false
var _dialogue_index: int = 0
var _char_index: int = 0
var _current_text: String = ""
var _typewriter_speed: float = 0.025
var _typewriter_timer: float = 0.0

# UI elements hovering above NPC head
var _ui_root: Node2D
var _prompt_badge: PanelContainer
var _dialogue_box: PanelContainer
var _name_label: Label
var _text_label: Label
var _footer_label: Label
var _tail_poly: Polygon2D

var _interact_zone: Area2D

func _ready() -> void:
	collision_layer = 2
	collision_mask = 0

	# Calculate character-specific talk pitch
	_configure_character_pitch()

	# Visual Sprite representation
	var spr := Sprite2D.new()
	spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	spr.position = Vector2(0, -22)
	if sprite_texture:
		spr.texture = sprite_texture
		var tex_h := float(sprite_texture.get_height())
		if tex_h > 0.0:
			var s := 50.0 / tex_h
			spr.scale = Vector2(s, s)
		else:
			spr.scale = Vector2(0.065, 0.065)
	else:
		spr.scale = Vector2(0.065, 0.065)
	add_child(spr)

	# Physical collider for collision bumping
	var col := CollisionShape2D.new()
	var cap := CapsuleShape2D.new()
	cap.radius = 8.0
	cap.height = 18.0
	col.shape = cap
	col.rotation = 1.5708
	col.position = Vector2(0, -6)
	add_child(col)

	# Interaction detection zone (Area2D)
	_interact_zone = Area2D.new()
	_interact_zone.collision_layer = 0
	_interact_zone.collision_mask = 1
	var zone_shape := CollisionShape2D.new()
	var circ := CircleShape2D.new()
	circ.radius = 45.0
	zone_shape.shape = circ
	_interact_zone.add_child(zone_shape)
	_interact_zone.body_entered.connect(_on_player_enter)
	_interact_zone.body_exited.connect(_on_player_exit)
	add_child(_interact_zone)

	# Build Hovering Dialogue Box
	_build_hovering_ui()

func _configure_character_pitch() -> void:
	var lower = npc_name.to_lower()
	if "mom" in lower:
		talk_pitch = 1.15
	elif "priya" in lower:
		talk_pitch = 1.30
	elif "meera" in lower:
		talk_pitch = 1.35
	elif "rohan" in lower:
		talk_pitch = 0.95
	elif "kumar" in lower or "teacher" in lower:
		talk_pitch = 0.75
	else:
		talk_pitch = 1.0

func _get_name_color() -> Color:
	var lower = npc_name.to_lower()
	if "mom" in lower:
		return Color(1.0, 0.78, 0.25)
	elif "priya" in lower:
		return Color(0.35, 0.9, 0.65)
	elif "meera" in lower:
		return Color(0.95, 0.6, 0.8)
	elif "rohan" in lower:
		return Color(1.0, 0.5, 0.45)
	elif "kumar" in lower or "teacher" in lower:
		return Color(1.0, 0.85, 0.3)
	return Color(0.5, 0.85, 1.0)

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

	# 2. Dialogue Box Panel (Hovering above head)
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

	# Speaker Name Header
	_name_label = Label.new()
	_name_label.text = npc_name.to_upper()
	_name_label.add_theme_font_size_override("font_size", 11)
	_name_label.add_theme_color_override("font_color", _get_name_color())
	_name_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	vbox.add_child(_name_label)

	# Dialogue Body Text
	_text_label = Label.new()
	_text_label.text = ""
	_text_label.add_theme_font_size_override("font_size", 12)
	_text_label.add_theme_color_override("font_color", Color(0.96, 0.96, 0.98))
	_text_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	_text_label.add_theme_constant_override("shadow_offset_x", 1)
	_text_label.add_theme_constant_override("shadow_offset_y", 1)
	_text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text_label.custom_minimum_size = Vector2(216, 36)
	vbox.add_child(_text_label)

	# Footer Prompt
	_footer_label = Label.new()
	_footer_label.text = "▶ [E] Next"
	_footer_label.add_theme_font_size_override("font_size", 10)
	_footer_label.add_theme_color_override("font_color", Color(0.8, 0.75, 0.5, 0.8))
	_footer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	vbox.add_child(_footer_label)

	# Pointer tail pointing down towards head
	_tail_poly = Polygon2D.new()
	_tail_poly.color = Color(0.07, 0.09, 0.15, 0.95)
	_tail_poly.polygon = PackedVector2Array([
		Vector2(-6, -70),
		Vector2(6, -70),
		Vector2(0, -60)
	])
	_tail_poly.visible = false
	_ui_root.add_child(_tail_poly)

func _process(delta: float) -> void:
	if _is_speaking and _char_index < _current_text.length():
		_typewriter_timer += delta
		if _typewriter_timer >= _typewriter_speed:
			_typewriter_timer = 0.0
			_char_index += 1
			_text_label.text = _current_text.substr(0, _char_index)

			# Play retro speech blip every 2 characters
			if _char_index % 2 == 0:
				var audio_mgr = get_node_or_null("/root/AudioManager")
				if audio_mgr and audio_mgr.has_method("play_talk_blip"):
					audio_mgr.play_talk_blip(talk_pitch)

func _unhandled_input(event: InputEvent) -> void:
	if not _player_in_range:
		return
	if event is InputEventKey and event.is_pressed() and not event.is_echo():
		if event.keycode == KEY_E or event.physical_keycode == KEY_E or event.keycode == KEY_SPACE:
			_handle_interaction()

func _handle_interaction() -> void:
	if dialogue_lines.is_empty():
		return

	if not _is_speaking:
		# Open dialogue box
		_prompt_badge.visible = false
		_dialogue_box.visible = true
		_tail_poly.visible = true
		_dialogue_index = 0
		_show_current_line()
	else:
		# If typing, finish immediately
		if _char_index < _current_text.length():
			_char_index = _current_text.length()
			_text_label.text = _current_text
		else:
			# Advance line or close
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

	# Update footer prompt
	if _dialogue_index == dialogue_lines.size() - 1:
		_footer_label.text = "▶ [E] Done"
	else:
		_footer_label.text = "▶ [E] Next"

	# Audio & optional TTS
	var audio_mgr = get_node_or_null("/root/AudioManager")
	if audio_mgr:
		if audio_mgr.has_method("play_interact"):
			audio_mgr.play_interact()
		if audio_mgr.has_method("speak_tts"):
			audio_mgr.speak_tts(_current_text, talk_pitch)

func _close_dialogue() -> void:
	_is_speaking = false
	_dialogue_box.visible = false
	_tail_poly.visible = false
	if _player_in_range:
		_prompt_badge.visible = true

	var audio_mgr = get_node_or_null("/root/AudioManager")
	if audio_mgr and audio_mgr.has_method("stop_tts"):
		audio_mgr.stop_tts()

func _on_player_enter(body: Node2D) -> void:
	if body is CharacterBody2D:
		_player_in_range = true
		if not _is_speaking:
			_prompt_badge.visible = true

func _on_player_exit(body: Node2D) -> void:
	if body is CharacterBody2D:
		_player_in_range = false
		_prompt_badge.visible = false
		if _is_speaking:
			_close_dialogue()
