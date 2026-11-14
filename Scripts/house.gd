extends Node2D

const SceneMgr = preload("res://Scripts/scene_manager.gd")

@onready var player: CharacterBody2D = $"Arun_Charchter(Evin)"

func _ready() -> void:
	# Configure camera limits for full 1280x720 house framing
	if player and player.has_method("configure_camera"):
		player.configure_camera(Rect2(0, 0, 1280, 720), Vector2(1.0, 1.0))

	var door: String = SceneMgr.get_target_door()
	if door == "from_walkway":
		# Entering from front door into kitchen/living area
		if player:
			player.global_position = Vector2(1040, 580)
	elif door == "from_bed":
		# Waking up near bed
		if player:
			player.global_position = Vector2(170, 420)
	else:
		# Default spawn: bedroom foot of bed
		if player:
			player.global_position = Vector2(170, 420)
