extends Node2D

const SceneMgr = preload("res://Scripts/scene_manager.gd")

@onready var player: CharacterBody2D = $"Arun_Charchter(Evin)"

func _ready() -> void:
	if player and player.has_method("configure_camera"):
		player.configure_camera(Rect2(0, 0, 782, 721), Vector2(1.8, 1.8))

	var door: String = SceneMgr.get_target_door()
	if door == "from_walkway":
		if player:
			player.global_position = Vector2(391, 610)
	else:
		if player:
			player.global_position = Vector2(391, 450)
