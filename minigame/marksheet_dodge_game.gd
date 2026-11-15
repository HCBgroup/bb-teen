class_name MarksheetDodgeGame
extends Node2D

## Emitted when the minigame completes (passed target time or HP depleted).
signal minigame_completed(result: Dictionary)
## Emitted when exit is requested back to host game.
signal minigame_exited()
## Emitted when minigame is restarted.
signal minigame_restarted()
## Emitted on score change.
signal score_changed(new_score: int)
## Emitted on player health change.
signal health_changed(current_hp: int, max_hp: int)
## Emitted when a marksheet is shredded.
signal paper_shredded(points: int, global_pos: Vector2)
## Emitted when player is hit.
signal player_damaged(damage: int, remaining_hp: int)

@export_group("Minigame Configuration")
## If true, the minigame automatically starts on _ready().
@export var auto_start: bool = true
## Target survival time in seconds. 0.0 = endless until player runs out of HP.
@export var target_survival_time: float = 0.0
## Target score to complete exam. Default 50 points.
@export var target_score: int = 50
## Starting and maximum player health.
@export var initial_player_health: int = 5
## Base falling speed of marksheets.
@export var base_marksheet_speed: float = 180.0
## Starting spawn rate in seconds.
@export var initial_spawn_interval: float = 1.1
## Fastest spawn interval as difficulty increases.
@export var min_spawn_interval: float = 0.45
## Difficulty scale multiplier.
@export var difficulty_scale: float = 1.0
## If false, hides the built-in UI so a host game can draw its own HUD.
@export var show_built_in_ui: bool = true
## If true, full scene reload on standalone restart is allowed; if false, resets internally.
@export var standalone_mode: bool = true
## Arena dimensions.
@export var arena_size: Vector2 = Vector2(1280, 720)

var score: int = 0
var papers_shredded_count: int = 0
var survival_time: float = 0.0
var is_active: bool = false
var is_game_over: bool = false
var spawn_interval: float = 1.1

const MARKSHEET_SCENE: PackedScene = preload("res://minigame/components/marksheet.tscn")

@onready var player: MarksheetDodgePlayer = %Player
@onready var marksheet_container: Node2D = %MarksheetContainer
@onready var effects_container: Node2D = %EffectsContainer
@onready var spawn_timer: Timer = %SpawnTimer
@onready var difficulty_timer: Timer = %DifficultyTimer
@onready var camera: Camera2D = %Camera2D

# Built-in UI nodes
@onready var ui_layer: CanvasLayer = %UI
@onready var hud: Control = %HUD
@onready var score_value_label: Label = %ScoreValue
@onready var hp_value_label: Label = %HpValue
@onready var timer_value_label: Label = %TimerValue
@onready var shredded_value_label: Label = %ShreddedValue
@onready var controls_tip: Label = %ControlsTip

# Results / Game Over Modal
@onready var game_over_panel: Control = %GameOverPanel
@onready var result_title_label: Label = %GameOverTitle
@onready var result_subtitle_label: Label = %GameOverSubtitle
@onready var final_score_label: Label = %FinalScore
@onready var survival_time_label: Label = %SurvivalTime
@onready var papers_shredded_stat_label: Label = %PapersShredded
@onready var restart_button: Button = %RestartButton
@onready var exit_button: Button = %ExitButton

func _ready() -> void:
	ui_layer.visible = show_built_in_ui
	game_over_panel.visible = false
	
	player.health_changed.connect(_on_player_health_changed)
	player.player_hit.connect(_on_player_hit_damage)
	player.player_died.connect(_on_player_died)

	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	difficulty_timer.timeout.connect(_on_difficulty_timer_timeout)
	restart_button.pressed.connect(_on_restart_pressed)
	exit_button.pressed.connect(_on_exit_pressed)

	if auto_start:
		start_game()

func start_game() -> void:
	score = 0
	papers_shredded_count = 0
	survival_time = 0.0
	is_game_over = false
	is_active = true
	spawn_interval = initial_spawn_interval / max(0.1, difficulty_scale)

	# Clear any previous marksheets and effects
	for child: Node in marksheet_container.get_children():
		child.queue_free()
	for child: Node in effects_container.get_children():
		child.queue_free()

	# Center player in arena
	var spawn_pos: Vector2 = Vector2(arena_size.x * 0.5, arena_size.y * 0.72)
	player.reset(spawn_pos, initial_player_health)

	spawn_timer.wait_time = spawn_interval
	spawn_timer.start()
	difficulty_timer.start()

	game_over_panel.visible = false
	update_hud()
	update_timer_display()

func stop_game() -> void:
	is_active = false
	spawn_timer.stop()
	difficulty_timer.stop()
	player.set_active(false)

func reset_game() -> void:
	emit_signal("minigame_restarted")
	start_game()

func _process(delta: float) -> void:
	if not is_active:
		if is_game_over:
			if Input.is_action_just_pressed("attack") or Input.is_key_pressed(KEY_R):
				_on_restart_pressed()
		return

	survival_time += delta
	update_timer_display()

	# Check target survival win condition
	if target_survival_time > 0.0 and survival_time >= target_survival_time:
		_finish_minigame(true)

func _on_spawn_timer_timeout() -> void:
	if not is_active:
		return

	var marksheet: Marksheet = MARKSHEET_SCENE.instantiate() as Marksheet
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.randomize()

	var spawn_x: float = rng.randf_range(80.0, arena_size.x - 80.0)
	var spawn_y: float = -60.0
	marksheet.position = Vector2(spawn_x, spawn_y)
	marksheet.base_speed = base_marksheet_speed * difficulty_scale
	marksheet.bottom_boundary = arena_size.y + 60.0

	marksheet.paper_shredded.connect(_on_paper_shredded)
	marksheet.paper_hit_player.connect(_on_paper_hit_player)
	marksheet.paper_escaped.connect(_on_paper_escaped)

	marksheet_container.add_child(marksheet)

func _on_paper_shredded(points: int, global_pos: Vector2) -> void:
	score += points
	papers_shredded_count += 1
	emit_signal("score_changed", score)
	emit_signal("paper_shredded", points, global_pos)
	spawn_floating_text("+" + str(points), global_pos, Color(0.2, 0.95, 0.3))
	update_hud()

	if target_score > 0 and score >= target_score and not is_game_over:
		_finish_minigame(true)

func _on_paper_hit_player(penalty: int, global_pos: Vector2) -> void:
	score = max(0, score - penalty)
	emit_signal("score_changed", score)
	spawn_floating_text("-" + str(penalty), global_pos, Color(0.95, 0.25, 0.25))
	screen_shake(0.25, 8.0)
	update_hud()

func _on_paper_escaped() -> void:
	pass

func _on_player_hit_damage(damage: int) -> void:
	emit_signal("player_damaged", damage, player.current_health)

func _on_player_health_changed(current_hp: int, max_hp: int) -> void:
	emit_signal("health_changed", current_hp, max_hp)
	var hearts: String = ""
	for i: int in range(max_hp):
		if i < current_hp:
			hearts += "# "
		else:
			hearts += "- "
	hp_value_label.text = hearts.strip_edges()
	if current_hp <= 1:
		hp_value_label.modulate = Color(1.0, 0.2, 0.2)
	else:
		hp_value_label.modulate = Color.WHITE

func _on_player_died() -> void:
	_finish_minigame(false)

func _finish_minigame(passed: bool) -> void:
	stop_game()
	is_game_over = true
	screen_shake(0.4, 14.0)

	var result: Dictionary = {
		"passed": passed,
		"score": score,
		"papers_shredded": papers_shredded_count,
		"survival_time": survival_time,
		"health_remaining": player.current_health,
		"max_health": initial_player_health
	}
	emit_signal("minigame_completed", result)

	# Update Game Over UI
	if passed:
		result_title_label.text = "EXAM PASSED!"
		result_title_label.add_theme_color_override("font_color", Color(0.2, 0.95, 0.4))
		result_subtitle_label.text = "You shredded through the exam! Bouncing Back to victory!"
		
		# Auto transition to End Credits
		var tw = create_tween()
		tw.tween_interval(2.0)
		tw.tween_callback(func():
			var scene_mgr = get_node_or_null("/root/SceneManager")
			if scene_mgr:
				scene_mgr.change_scene_to("res://Scence/EndCredits.tscn")
			else:
				get_tree().change_scene_to_file("res://Scence/EndCredits.tscn")
		)
	else:
		result_title_label.text = "EXAM OVER!"
		result_title_label.add_theme_color_override("font_color", Color(0.95, 0.2, 0.2))
		result_subtitle_label.text = "The marksheets caught you! Press [R] or Try Again to Bounce Back!"

	final_score_label.text = "Final Score: " + str(score)
	var minutes: int = int(survival_time / 60.0)
	var seconds: int = int(survival_time) % 60
	survival_time_label.text = "Survived: %02d:%02d" % [minutes, seconds]
	papers_shredded_stat_label.text = "Papers Shredded: " + str(papers_shredded_count)

	game_over_panel.visible = true
	game_over_panel.modulate.a = 0.0
	var tween: Tween = create_tween()
	tween.tween_property(game_over_panel, "modulate:a", 1.0, 0.35)

func _on_difficulty_timer_timeout() -> void:
	if spawn_interval > min_spawn_interval:
		spawn_interval = max(min_spawn_interval, spawn_interval - 0.05)
		spawn_timer.wait_time = spawn_interval

func update_hud() -> void:
	score_value_label.text = str(score)
	shredded_value_label.text = str(papers_shredded_count)

func update_timer_display() -> void:
	var minutes: int = int(survival_time / 60.0)
	var seconds: int = int(survival_time) % 60
	if target_survival_time > 0.0:
		var target_min: int = int(target_survival_time / 60.0)
		var target_sec: int = int(target_survival_time) % 60
		timer_value_label.text = "%02d:%02d / %02d:%02d" % [minutes, seconds, target_min, target_sec]
	else:
		timer_value_label.text = "%02d:%02d" % [minutes, seconds]

func spawn_floating_text(content: String, pos: Vector2, color: Color) -> void:
	var float_text: FloatingText = FloatingText.new()
	effects_container.add_child(float_text)
	float_text.setup(content, pos, color)

func screen_shake(duration: float, intensity: float) -> void:
	if not camera:
		return
	var tween: Tween = create_tween()
	for i: int in range(int(duration * 20)):
		var offset: Vector2 = Vector2(randf_range(-intensity, intensity), randf_range(-intensity, intensity))
		tween.tween_property(camera, "offset", offset, 0.05)
	tween.tween_property(camera, "offset", Vector2.ZERO, 0.05)

func _on_restart_pressed() -> void:
	if standalone_mode:
		get_tree().reload_current_scene()
	else:
		reset_game()

func _on_exit_pressed() -> void:
	emit_signal("minigame_exited")
	if standalone_mode:
		get_tree().quit()
	else:
		visible = false
