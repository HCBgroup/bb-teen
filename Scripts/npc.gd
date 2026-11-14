class_name GameNPC
extends StaticBody2D

@export var dialogue_lines: PackedStringArray = ["Hello!", "Nice day, isn't it?"]
@export var npc_name: String = "Student"
@export var sprite_texture: Texture2D

var _player_in_range: bool = false
var _dialogue_index: int = 0
var _bubble: Label
var _name_lbl: Label
var _interact_zone: Area2D
var _hide_timer: float = 0.0

func _ready() -> void:
	collision_layer = 2
	collision_mask = 0

	# Visual representation
	var spr := Sprite2D.new()
	spr.scale = Vector2(0.065, 0.065)
	spr.position = Vector2(0, -20)
	if sprite_texture:
		spr.texture = sprite_texture
	add_child(spr)

	# Collider for physics bumping
	var col := CollisionShape2D.new()
	var cap := CapsuleShape2D.new()
	cap.radius = 8.0
	cap.height = 18.0
	col.shape = cap
	col.rotation = 1.5708
	col.position = Vector2(0, -6)
	add_child(col)

	# Name label
	_name_lbl = Label.new()
	_name_lbl.text = npc_name
	_name_lbl.add_theme_font_size_override("font_size", 10)
	_name_lbl.add_theme_color_override("font_color", Color(1.0, 1.0, 0.4, 1.0))
	_name_lbl.add_theme_color_override("font_shadow_color", Color.BLACK)
	_name_lbl.position = Vector2(-30, -50)
	_name_lbl.size = Vector2(60, 16)
	_name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_name_lbl)

	# Interaction detection zone
	_interact_zone = Area2D.new()
	_interact_zone.collision_layer = 0
	_interact_zone.collision_mask = 1
	var zone_shape := CollisionShape2D.new()
	var circ := CircleShape2D.new()
	circ.radius = 42.0
	zone_shape.shape = circ
	_interact_zone.add_child(zone_shape)
	_interact_zone.body_entered.connect(_on_player_enter)
	_interact_zone.body_exited.connect(_on_player_exit)
	add_child(_interact_zone)

	# Dialogue speech bubble
	_bubble = Label.new()
	_bubble.add_theme_font_size_override("font_size", 11)
	_bubble.add_theme_color_override("font_color", Color.WHITE)
	_bubble.add_theme_color_override("font_shadow_color", Color.BLACK)
	_bubble.add_theme_constant_override("shadow_offset_x", 1)
	_bubble.add_theme_constant_override("shadow_offset_y", 1)
	_bubble.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_bubble.custom_minimum_size = Vector2(160, 0)
	_bubble.position = Vector2(-80, -85)
	_bubble.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_bubble.visible = false
	add_child(_bubble)

func _unhandled_input(event: InputEvent) -> void:
	if not _player_in_range:
		return
	if event is InputEventKey and event.is_pressed() and not event.is_echo():
		if event.keycode == KEY_E or event.physical_keycode == KEY_E:
			_show_next_dialogue()

func _process(delta: float) -> void:
	if _hide_timer > 0.0:
		_hide_timer -= delta
		if _hide_timer <= 0.0 and not _player_in_range:
			_bubble.visible = false

func _show_next_dialogue() -> void:
	if dialogue_lines.is_empty():
		return
	_bubble.text = dialogue_lines[_dialogue_index]
	_bubble.visible = true
	_hide_timer = 4.0
	_dialogue_index = (_dialogue_index + 1) % dialogue_lines.size()

func _on_player_enter(body: Node2D) -> void:
	if body is CharacterBody2D:
		_player_in_range = true
		_bubble.text = "[E] Talk to " + npc_name
		_bubble.visible = true

func _on_player_exit(body: Node2D) -> void:
	if body is CharacterBody2D:
		_player_in_range = false
		_hide_timer = 1.0
		_dialogue_index = 0
