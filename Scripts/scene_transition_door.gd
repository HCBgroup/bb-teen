class_name SceneTransitionDoor
extends Area2D

const SceneMgr = preload("res://Scripts/scene_manager.gd")

@export_file("*.tscn") var target_scene: String = "res://Scence/school(evin).tscn"
@export var target_door_id: String = "from_walkway"
@export var prompt_message: String = "[E] Enter"
@export var auto_transition: bool = false # Require [E] to prevent accidental bounce loops

static var transition_lock_timer: float = 0.8 # Global immunity after scene load

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
	prompt_label.add_theme_font_size_override("font_size", 14)
	prompt_label.add_theme_color_override("font_color", Color(1.0, 1.0, 0.4, 1.0))
	prompt_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	prompt_label.add_theme_constant_override("shadow_offset_x", 1)
	prompt_label.add_theme_constant_override("shadow_offset_y", 1)
	prompt_label.position = Vector2(-70, -45)
	prompt_label.size = Vector2(140, 24)
	prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt_label.visible = false
	add_child(prompt_label)

func _process(delta: float) -> void:
	if transition_lock_timer > 0.0:
		transition_lock_timer -= delta

	if not player_in_range or _transition_triggered or transition_lock_timer > 0.0:
		return

	if Input.is_action_just_pressed("ui_accept"):
		_trigger_transition()

func _unhandled_input(event: InputEvent) -> void:
	if not player_in_range or _transition_triggered or transition_lock_timer > 0.0:
		return
	if event is InputEventKey and event.is_pressed() and not event.is_echo():
		if event.keycode == KEY_E or event.physical_keycode == KEY_E or event.keycode == KEY_ENTER or event.physical_keycode == KEY_ENTER:
			_trigger_transition()

func _trigger_transition() -> void:
	if target_scene != "" and not _transition_triggered and transition_lock_timer <= 0.0:
		_transition_triggered = true
		player_in_range = false
		prompt_label.visible = false
		transition_lock_timer = 1.0 # Lock transitions for 1.0s across scene reload

		var audio_mgr = get_node_or_null("/root/AudioManager")
		if audio_mgr and audio_mgr.has_method("play_door_transition"):
			audio_mgr.play_door_transition()

		SceneMgr.transition_to(target_scene, target_door_id)

func _on_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D:
		player_in_range = true
		if auto_transition and transition_lock_timer <= 0.0:
			_trigger_transition()
		else:
			prompt_label.visible = true

func _on_body_exited(body: Node2D) -> void:
	if body is CharacterBody2D:
		player_in_range = false
		prompt_label.visible = false
