extends Node2D

const SceneMgr = preload("res://Scripts/scene_manager.gd")

@onready var player: CharacterBody2D = $"Arun_Charchter(Evin)"
@onready var teacher: GameNPC = $NPC_Teacher
@onready var exam_sequence: ExamSpotlightSequence = $ExamSpotlightSequence

func _ready() -> void:
	# Configure camera limits strictly to classroom interior (no outer void visible)
	if player and player.has_method("configure_camera"):
		player.configure_camera(Rect2(58, 180, 664, 480), Vector2(1.6, 1.6))

	var door: String = SceneMgr.get_target_door()
	if door == "from_walkway":
		# Spawn safely in the classroom aisle facing north
		if player:
			player.global_position = Vector2(391, 530)
	else:
		if player:
			player.global_position = Vector2(391, 450)

	# When Mr. Kumar finishes talking, he assigns Arun to his exam desk
	if teacher and teacher.has_signal("dialogue_finished"):
		teacher.dialogue_finished.connect(_on_teacher_dialogue_finished)

func _on_teacher_dialogue_finished(npc_name: String) -> void:
	if npc_name == "Mr. Kumar" and exam_sequence:
		exam_sequence.start_exam_sequence()
