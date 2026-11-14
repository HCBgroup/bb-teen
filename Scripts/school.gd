extends Node2D

const SceneMgr = preload("res://Scripts/scene_manager.gd")

@onready var player: CharacterBody2D = $"Arun_Charchter(Evin)"
@onready var teacher: GameNPC = $NPC_Teacher
@onready var exam_zone: ExamSpotlightSequence = $ExamSpotlightSequence
@onready var classmate_meera: GameNPC = $NPC_Classmate
@onready var classmate_rohan: GameNPC = $NPC_Rohan

var _desk_indicator: Polygon2D
var _indicator_tween: Tween

func _ready() -> void:
	# Configure camera limits strictly to classroom interior (no outer void)
	if player and player.has_method("configure_camera"):
		player.configure_camera(Rect2(58, 180, 664, 480), Vector2(1.5, 1.5))

	var door: String = SceneMgr.get_target_door()
	if door == "from_walkway":
		if player:
			player.global_position = Vector2(391, 540)
	else:
		if player:
			player.global_position = Vector2(391, 460)

	_setup_teacher()
	_setup_desk_indicator()

func _setup_teacher() -> void:
	if teacher:
		teacher.npc_name = "Mr. Kumar"
		teacher.dialogue_lines = [
			"Ah, Arun! Right on time. We are about to commence the Mathematics Mid-Term Examination.",
			"Please take your assigned seat at Desk #5 immediately. Silence in the examination hall!",
			"Keep your head cool, stay focused, and do your best. Your exam begins now!"
		]
		teacher.dialogue_finished.connect(_on_teacher_dialogue_finished)

func _setup_desk_indicator() -> void:
	# Bouncing yellow arrow pointing down at Desk #5
	_desk_indicator = Polygon2D.new()
	_desk_indicator.polygon = PackedVector2Array([
		Vector2(-10, -25), Vector2(10, -25),
		Vector2(10, -10), Vector2(18, -10),
		Vector2(0, 5), Vector2(-18, -10),
		Vector2(-10, -10)
	])
	_desk_indicator.color = Color(1.0, 0.85, 0.2, 0.9)
	_desk_indicator.position = Vector2(418, 440)
	_desk_indicator.visible = false
	add_child(_desk_indicator)

	# Bouncing tween
	_indicator_tween = create_tween().set_loops()
	_indicator_tween.tween_property(_desk_indicator, "position:y", 432.0, 0.5).set_trans(Tween.TRANS_SINE)
	_indicator_tween.tween_property(_desk_indicator, "position:y", 442.0, 0.5).set_trans(Tween.TRANS_SINE)

func _on_teacher_dialogue_finished() -> void:
	# Show indicator over Desk #5 and enable exam seat
	if _desk_indicator:
		_desk_indicator.visible = true
	if exam_zone and exam_zone.has_method("enable_exam_seat"):
		exam_zone.enable_exam_seat()

func set_classmates_writing(writing: bool) -> void:
	if _desk_indicator:
		_desk_indicator.visible = false
		if _indicator_tween:
			_indicator_tween.kill()

	# Position and animate classmates head-down at their desks writing
	var classmates: Array = [classmate_meera, classmate_rohan]
	for c in classmates:
		if is_instance_valid(c):
			# Slight head-down tilt and subtle paper writing shake
			var spr = c.get_node_or_null("Sprite2D")
			if not spr:
				# Find any child sprite
				for child in c.get_children():
					if child is Sprite2D or child is AnimatedSprite2D:
						spr = child
						break
			if spr:
				var tw = create_tween().set_loops(10)
				tw.tween_property(spr, "rotation", deg_to_rad(4.0), 0.3)
				tw.tween_property(spr, "rotation", deg_to_rad(-2.0), 0.3)
