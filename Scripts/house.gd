extends Node2D

const SceneMgr = preload("res://Scripts/scene_manager.gd")

@onready var player: CharacterBody2D = $"Arun_Charchter(Evin)"

func _ready() -> void:
	# Configure camera limits for 640x448 house interior with 2.0x zoom
	if player and player.has_method("configure_camera"):
		player.configure_camera(Rect2(48, 64, 544, 336), Vector2(2.0, 2.0))

	var door: String = SceneMgr.get_target_door()
	if door == "from_walkway":
		# Entering from front door
		if player:
			player.global_position = Vector2(432, 360)
	elif door == "from_bed":
		# Waking up in bed
		if player:
			player.global_position = Vector2(110, 180)
	else:
		# Default spawn: near bed
		if player:
			player.global_position = Vector2(120, 200)
