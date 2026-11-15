class_name GlobalAudioManager
extends Node

## Global Audio Manager for background music, retro dialogue blips, TTS, and interaction SFX.

var _bgm_player: AudioStreamPlayer
var _voice_player: AudioStreamPlayer
var _sfx_players: Array[AudioStreamPlayer] = []
var _sfx_pool_size: int = 6
var _current_sfx_idx: int = 0

var _talk_blip_timer: float = 0.0
var _talk_blip_interval: float = 0.06

# Audio resources
var snd_tap: AudioStream
var snd_coin: AudioStream
var snd_jump: AudioStream
var snd_power_up: AudioStream
var snd_hurt: AudioStream
var bgm_stream: AudioStream

# TTS settings
var tts_enabled: bool = true
var _voices: PackedStringArray = []

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	# Load CC0 retro sound effects
	snd_tap = load("res://assests/audio/tap.wav")
	snd_coin = load("res://assests/audio/coin.wav")
	snd_jump = load("res://assests/audio/jump.wav")
	snd_power_up = load("res://assests/audio/power_up.wav")
	snd_hurt = load("res://assests/audio/hurt.wav")
	bgm_stream = load("res://assests/audio/time_for_adventure.mp3")

	# Setup BGM Player
	_bgm_player = AudioStreamPlayer.new()
	_bgm_player.volume_db = -12.0
	_bgm_player.bus = "Master"
	add_child(_bgm_player)

	# Setup Voice Player for crystal-clear character voice lines
	_voice_player = AudioStreamPlayer.new()
	_voice_player.volume_db = 0.0
	_voice_player.bus = "Master"
	add_child(_voice_player)

	# Setup SFX Pool for polyphonic sound playback
	for i in range(_sfx_pool_size):
		var p := AudioStreamPlayer.new()
		p.volume_db = -4.0
		p.bus = "Master"
		add_child(p)
		_sfx_players.append(p)

	# Detect native OS TTS voices (Windows SAPI / Mac / Linux)
	if DisplayServer.has_feature(DisplayServer.FEATURE_TEXT_TO_SPEECH):
		_voices = DisplayServer.tts_get_voices()

	# Ensure crisp 1280x720 canvas scaling across all screens and modes
	var root_win = get_tree().root
	if root_win:
		root_win.content_scale_size = Vector2i(1280, 720)
		root_win.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
		root_win.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP

	# Start background music
	start_bgm()

func _process(delta: float) -> void:
	if _talk_blip_timer > 0.0:
		_talk_blip_timer -= delta

func _unhandled_input(event: InputEvent) -> void:
	# F11 or Alt+Enter fullscreen toggle
	if event is InputEventKey and event.is_pressed() and not event.is_echo():
		if event.keycode == KEY_F11 or (event.keycode == KEY_ENTER and event.alt_pressed):
			toggle_fullscreen()

func toggle_fullscreen() -> void:
	var mode = DisplayServer.window_get_mode()
	if mode == DisplayServer.WINDOW_MODE_FULLSCREEN or mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)

func start_bgm() -> void:
	if bgm_stream and not _bgm_player.playing:
		_bgm_player.stream = bgm_stream
		_bgm_player.play()

func stop_bgm() -> void:
	if _bgm_player.playing:
		_bgm_player.stop()

func play_sfx(stream: AudioStream, pitch_scale: float = 1.0, volume_db: float = -4.0) -> void:
	if stream == null or _sfx_players.is_empty():
		return
	var player = _sfx_players[_current_sfx_idx]
	_current_sfx_idx = (_current_sfx_idx + 1) % _sfx_players.size()
	player.stream = stream
	player.pitch_scale = pitch_scale
	player.volume_db = volume_db
	player.play()

## Plays an 8-bit retro chatter blip on dialogue typewriter steps (Undertale / Animal Crossing style)
func play_talk_blip(pitch: float = 1.0) -> void:
	if _talk_blip_timer <= 0.0 and snd_tap:
		_talk_blip_timer = _talk_blip_interval
		# Add a tiny pitch jitter (+-0.05) for lively retro vocalization
		var jitter = randf_range(-0.04, 0.04)
		play_sfx(snd_tap, clampf(pitch + jitter, 0.4, 2.5), -7.0)

## Plays a crystal-clear pre-rendered Bing/Edge neural voice file
func play_voice(voice_res_path: String) -> void:
	if ResourceLoader.exists(voice_res_path):
		var stream = load(voice_res_path)
		play_voice_stream(stream)

func play_voice_stream(stream: AudioStream) -> void:
	if stream and _voice_player:
		if _voice_player.playing:
			_voice_player.stop()
		_voice_player.stream = stream
		_voice_player.play()

func stop_voice() -> void:
	if _voice_player and _voice_player.playing:
		_voice_player.stop()

## Speaks text using native OS Text-To-Speech (Windows Speech API - not AI generated)
func speak_tts(text: String, pitch: float = 1.0, rate: float = 1.0) -> void:
	if not tts_enabled:
		return
	if DisplayServer.has_feature(DisplayServer.FEATURE_TEXT_TO_SPEECH):
		if DisplayServer.tts_is_speaking():
			DisplayServer.tts_stop()
		var voice_id: String = ""
		if not _voices.is_empty():
			voice_id = _voices[0]
		DisplayServer.tts_speak(text, voice_id, 70, pitch, rate)

func stop_tts() -> void:
	stop_voice()
	if DisplayServer.has_feature(DisplayServer.FEATURE_TEXT_TO_SPEECH):
		if DisplayServer.tts_is_speaking():
			DisplayServer.tts_stop()

# Interaction SFX helpers
func play_interact() -> void:
	play_sfx(snd_tap, 1.3, -4.0)

func play_prop_open() -> void:
	play_sfx(snd_coin, 1.1, -6.0)

func play_door_transition() -> void:
	play_sfx(snd_jump, 0.85, -3.0)

func play_powerup() -> void:
	play_sfx(snd_power_up, 1.0, -3.0)

func play_magic_sparkle() -> void:
	play_sfx(snd_coin, 1.6, -4.0)
