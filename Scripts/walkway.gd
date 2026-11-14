extends Node2D

const SceneMgr = preload("res://Scripts/scene_manager.gd")

@onready var player: CharacterBody2D = $"Arun_Charchter(Evin)"

func _ready() -> void:
	if player and player.has_method("configure_camera"):
		player.configure_camera(Rect2(0, 0, 1272, 855), Vector2(1.6, 1.6))

	var door: String = SceneMgr.get_target_door()
	if door == "from_school":
		if player:
			player.global_position = Vector2(1130, 430)
	elif door == "from_house":
		if player:
			player.global_position = Vector2(140, 430)
	else:
		if player:
			player.global_position = Vector2(300, 430)
