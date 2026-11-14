class_name SceneTransitionDoor
extends Area2D

const SceneMgr = preload("res://Scripts/scene_manager.gd")

@export_file("*.tscn") var target_scene: String = "res://Scence/school(evin).tscn"
@export var target_door_id: String = "from_walkway"
@export var prompt_message: String = "[E] Enter"

var player_in_range: bool = false
var prompt_label: Label
var _transition_triggered: bool = false

func _ready() -> void:
	collision_layer = 0
	collision_mask = 1  # detect Arun (layer 1)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

	# World-space prompt label above the door
	prompt_label = Label.new()
	prompt_label.text = prompt_message
	prompt_label.add_theme_font_size_override("font_size", 13)
	prompt_label.add_theme_color_override("font_color", Color(1.0, 1.0, 0.4, 1.0))
	prompt_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	prompt_label.add_theme_constant_override("shadow_offset_x", 1)
	prompt_label.add_theme_constant_override("shadow_offset_y", 1)
	prompt_label.position = Vector2(-60, -45)
	prompt_label.size = Vector2(120, 24)
	prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt_label.visible = false
	add_child(prompt_label)

func _unhandled_input(event: InputEvent) -> void:
	if not player_in_range or _transition_triggered:
		return
	if event is InputEventKey and event.is_pressed() and not event.is_echo():
		if event.keycode == KEY_E or event.physical_keycode == KEY_E:
			_trigger_transition()

func _process(_delta: float) -> void:
	if not player_in_range or _transition_triggered:
		return
	if Input.is_action_just_pressed("ui_accept"):
		_trigger_transition()

func _trigger_transition() -> void:
	if target_scene != "" and not _transition_triggered:
		_transition_triggered = true
		player_in_range = false
		prompt_label.visible = false
		SceneMgr.transition_to(target_scene, target_door_id)

func _on_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D:
		player_in_range = true
		prompt_label.visible = true

func _on_body_exited(body: Node2D) -> void:
	if body is CharacterBody2D:
		player_in_range = false
		prompt_label.visible = false
