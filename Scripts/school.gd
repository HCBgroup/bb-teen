extends Node2D

const SceneMgr = preload("res://Scripts/scene_manager.gd")

@onready var player: CharacterBody2D = $"Arun_Charchter(Evin)"

func _ready() -> void:
	# Configure camera limits strictly to classroom interior (no outer void visible)
	if player and player.has_method("configure_camera"):
		player.configure_camera(Rect2(45, 115, 690, 570), Vector2(1.8, 1.8))

	var door: String = SceneMgr.get_target_door()
	if door == "from_walkway":
		# Spawn right inside the doorway notch
		if player:
			player.global_position = Vector2(391, 610)
	else:
		if player:
			player.global_position = Vector2(391, 450)
