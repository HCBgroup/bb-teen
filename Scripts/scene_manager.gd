class_name GlobalSceneManager
extends Node

## Global scene state and door transitions between Walkway and School
## Handles smooth fade transitions.

static var instance: GlobalSceneManager
static var target_door_id: String = ""
var default_scene: String = "res://Scence/Walkway.tscn"

# Overlay for fade in/out
var _overlay: ColorRect
var _canvas: CanvasLayer

func _enter_tree() -> void:
	instance = self

func _ready() -> void:
	instance = self
	_canvas = CanvasLayer.new()
	_canvas.layer = 100
	add_child(_canvas)

	_overlay = ColorRect.new()
	_overlay.color = Color.BLACK
	_overlay.modulate.a = 0.0
	_overlay.anchor_right = 1.0
	_overlay.anchor_bottom = 1.0
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_canvas.add_child(_overlay)

static func get_target_door() -> String:
	return target_door_id

static func transition_to(scene_path: String, door_id: String = "") -> void:
	target_door_id = door_id
	if instance:
		instance.change_scene_to(scene_path, door_id)
		return
	var tree := Engine.get_main_loop() as SceneTree
	if tree:
		if tree.root.has_node("SceneManager"):
			tree.root.get_node("SceneManager").change_scene_to(scene_path, door_id)
		else:
			tree.change_scene_to_file(scene_path)

func change_scene_to(scene_path: String, door_id: String = "") -> void:
	target_door_id = door_id
	# Fade out, change scene, then fade in
	var tween = create_tween()
	tween.tween_property(_overlay, "modulate:a", 1.0, 0.22)
	tween.tween_callback(func():
		get_tree().change_scene_to_file(scene_path)
	)
	tween.tween_interval(0.08)
	tween.tween_property(_overlay, "modulate:a", 0.0, 0.28)
