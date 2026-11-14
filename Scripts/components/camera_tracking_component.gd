class_name CameraTrackingComponent
extends Node

## CameraTrackingComponent attaches and controls a Camera2D to track the target node.
## Automatically sets up zoom, smooth follow, and level boundaries.

@export var zoom: Vector2 = Vector2(1.6, 1.6)
@export var smoothing_speed: float = 7.0
@export var limit_rect: Rect2 = Rect2(0, 0, 1272, 855)

var camera: Camera2D
var target: Node2D

func setup(p_target: Node2D, p_limit_rect: Rect2 = Rect2(), p_zoom: Vector2 = Vector2.ZERO) -> void:
	target = p_target
	if p_limit_rect.size != Vector2.ZERO:
		limit_rect = p_limit_rect
	if p_zoom != Vector2.ZERO:
		zoom = p_zoom

	# Create Camera2D if not already existing
	camera = target.get_node_or_null("Camera2D")
	if camera == null:
		camera = Camera2D.new()
		camera.name = "Camera2D"
		target.add_child(camera)

	apply_settings()

func apply_settings() -> void:
	if camera == null:
		return
	camera.enabled = true
	camera.make_current()
	camera.zoom = zoom
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = smoothing_speed
	camera.limit_left = int(limit_rect.position.x)
	camera.limit_top = int(limit_rect.position.y)
	camera.limit_right = int(limit_rect.position.x + limit_rect.size.x)
	camera.limit_bottom = int(limit_rect.position.y + limit_rect.size.y)
	camera.editor_draw_limits = true
	camera.reset_smoothing()
