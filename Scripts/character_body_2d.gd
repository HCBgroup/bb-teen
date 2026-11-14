extends CharacterBody2D

# Components
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var movement_component = $MovementComponent
@onready var camera_tracking_component = $CameraTrackingComponent

func _ready() -> void:
	if movement_component:
		movement_component.setup(self, sprite)
	if camera_tracking_component:
		camera_tracking_component.setup(self)

func configure_camera(limit_rect: Rect2, zoom_val: Vector2 = Vector2.ZERO) -> void:
	if camera_tracking_component:
		camera_tracking_component.setup(self, limit_rect, zoom_val)

func _physics_process(delta: float) -> void:
	if movement_component:
		movement_component.process_movement(delta)

func take_stress(amount: float) -> void:
	if sprite:
		var flash = create_tween()
		flash.tween_property(sprite, "modulate", Color(1.0, 0.3, 0.3), 0.1)
		flash.tween_property(sprite, "modulate", Color.WHITE, 0.1)
