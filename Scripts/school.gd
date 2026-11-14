extends Node2D

const SceneMgr = preload("res://Scripts/scene_manager.gd")

@onready var player: CharacterBody2D = $"Arun_Charchter(Evin)"

func _ready() -> void:
	# Configure camera limits strictly to classroom interior (no outer void visible)
	if player and player.has_method("configure_camera"):
		player.configure_camera(Rect2(58, 56, 664, 616), Vector2(1.0, 1.0))

	var door: String = SceneMgr.get_target_door()
	if door == "from_walkway":
		# Spawn safely in the classroom aisle facing north
		if player:
			player.global_position = Vector2(391, 530)
	else:
		if player:
			player.global_position = Vector2(391, 450)
