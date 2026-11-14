# Marksheet Dodge Minigame (Embeddable Scene)

An embeddable Godot 4.x arcade dodge-and-shred minigame where the player dodges falling exam question papers (marksheets) and shreds them for points.

---

## 📁 Project Architecture & Clean Asset Paths

```
res://
├── assets/
│   ├── backgrounds/
│   │   └── bg_blue_tile.png          # Space/grid background tile
│   ├── marksheet/
│   │   └── paper_marksheet.png       # Clean-cropped marksheet sprite (180x192)
│   └── player/
│       └── player_spritesheet.png    # Player character spritesheet (32x32 frames)
│
└── minigame/
    ├── marksheet_dodge_game.gd       # Main game controller (class_name MarksheetDodgeGame)
    ├── marksheet_dodge_game.tscn     # The embeddable scene root
    │
    └── components/
        ├── player.gd                 # Player controller (class_name MarksheetDodgePlayer)
        ├── player.tscn               # Player scene with 8-directional movement & attack
        ├── player_sprite_frames.tres # Sliced SpriteFrames resource (idle/run/attack)
        ├── marksheet.gd              # Falling paper logic (class_name Marksheet)
        ├── marksheet.tscn            # Marksheet Area2D scene
        └── floating_text.gd          # Animated floating score popup (class_name FloatingText)
```

---

## 🎮 Game Rules

1. **Player Movement & Attack**:
   - Move with `WASD` or Arrow keys.
   - Attack with `Space` or `Z` key to swing and shred nearby marksheets (+10 score, green popup).
2. **Dodging Marksheets**:
   - Getting hit by a marksheet reduces score (-5 score, red popup) and costs 1 HP.
   - Player receives 0.8s invulnerability frames with visual flicker upon taking damage.
3. **Escaping Papers**:
   - When a marksheet reaches the bottom / hits the wall, **nothing happens** (no penalty, no reward).
4. **Difficulty Scaling**:
   - Spawn interval decreases dynamically every 5 seconds from 1.1s down to 0.45s.

---

## 🔌 Embedding in Another Godot Game

The scene `res://minigame/marksheet_dodge_game.tscn` is designed to be instantiated and embedded directly inside any parent scene or minigame manager.

### Basic Integration Example

```gdscript
extends Node2D

func _ready() -> void:
    # 1. Load and instantiate the minigame
    var minigame_scene: PackedScene = preload("res://minigame/marksheet_dodge_game.tscn")
    var minigame: MarksheetDodgeGame = minigame_scene.instantiate()

    # 2. Configure embedding settings
    minigame.standalone_mode = false          # Prevents quitting process or reloading scene
    minigame.target_survival_time = 30.0      # 30-second survival challenge (0 = endless)
    minigame.initial_player_health = 3        # Custom difficulty health
    minigame.show_built_in_ui = true          # Set false if you want your own host HUD

    # 3. Connect to minigame signals
    minigame.minigame_completed.connect(_on_minigame_completed)
    minigame.minigame_exited.connect(_on_minigame_exited)
    minigame.score_changed.connect(_on_score_changed)

    # 4. Add to your scene tree
    add_child(minigame)

func _on_minigame_completed(result: Dictionary) -> void:
    print("Minigame Completed!")
    print("Passed:", result.passed)
    print("Final Score:", result.score)
    print("Papers Shredded:", result.papers_shredded)
    print("Survival Time:", result.survival_time)
    print("Health Remaining:", result.health_remaining)

func _on_minigame_exited() -> void:
    # Handle closing/removing minigame back to host game menu/world
    queue_free()

func _on_score_changed(new_score: int) -> void:
    print("Host HUD Score:", new_score)
```

---

## ⚙️ Export Properties Reference

| Property | Type | Default | Description |
|---|---|---|---|
| `auto_start` | `bool` | `true` | If true, game starts on `_ready()`. Set false to call `start_game()` manually. |
| `target_survival_time` | `float` | `0.0` | Target seconds to win. `0.0` = endless until HP is depleted. |
| `initial_player_health`| `int` | `5` | Starting and maximum player health. |
| `base_marksheet_speed` | `float` | `180.0` | Base falling velocity in pixels/second. |
| `initial_spawn_interval`| `float`| `1.1` | Starting time in seconds between paper spawns. |
| `min_spawn_interval` | `float` | `0.45` | Minimum spawn interval at maximum difficulty. |
| `difficulty_scale` | `float` | `1.0` | Multiplier for speed and spawn rate. |
| `show_built_in_ui` | `bool` | `true` | Toggles the built-in CanvasLayer HUD & modal. |
| `standalone_mode` | `bool` | `true` | If false, restart resets internally and exit emits signal without quitting Godot. |
| `arena_size` | `Vector2` | `(1280, 720)`| Dimensions of the playing field. |

---

## 📡 Public Signals Reference

| Signal | Parameters | Description |
|---|---|---|
| `minigame_completed` | `result: Dictionary` | Emitted when win condition or game over is met. |
| `minigame_exited` | None | Emitted when the exit/back button is clicked. |
| `minigame_restarted` | None | Emitted when the game restarts. |
| `score_changed` | `new_score: int` | Emitted whenever score is updated (+10 or -5). |
| `health_changed` | `current_hp: int, max_hp: int` | Emitted on player HP changes. |
| `paper_shredded` | `points: int, global_pos: Vector2` | Emitted when player shreds a marksheet. |
| `player_damaged` | `damage: int, remaining_hp: int` | Emitted when player gets hit by a paper. |

---

## 🔧 Public Methods

- `start_game()`: Starts/resets a new round.
- `stop_game()`: Pauses game timers and input.
- `reset_game()`: Resets game state internally without reloading the Godot scene tree.
