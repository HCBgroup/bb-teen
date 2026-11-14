extends Node2D

## Top-down school grounds walkway scene.
## Connects MorningRun.tscn to school(evin).tscn.

const SceneMgr = preload("res://Scripts/scene_manager.gd")

@onready var player: CharacterBody2D = $"Arun_Charchter(Evin)"

func _ready() -> void:
	if player and player.has_method("configure_camera"):
		player.configure_camera(Rect2(0, 0, 1272, 855), Vector2(1.5, 1.5))

	var door: String = SceneMgr.get_target_door()
	if door == "from_school":
		if player:
			player.global_position = Vector2(1060, 430)
	elif door == "from_run":
		if player:
			player.global_position = Vector2(180, 430)
	else:
		if player:
			player.global_position = Vector2(250, 430)
