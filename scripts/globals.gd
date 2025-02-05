extends Node

const INITIAL_LIVES = 3
const INITIAL_SPEED = 50
const LEVEL_TIME = 300
const TILE_SIZE = 16
const LEVEL_WIDTH = 29
const LEVEL_HEIGHT = 11
const LEVEL_OFFSET = Vector2(TILE_SIZE, TILE_SIZE) * 1.5
const AUTO_DETONATE_DELAY: float = 0.2

const POWERUP_POINTS = 1000
const ENEMY_POINTS = {
	Enemy.EnemyType.VALCOM: 100,
	Enemy.EnemyType.ONEAL: 200
}

enum GameState {
	INITIAL,
	LEVEL_START,
	PLAYING,
	PAUSED,
	PLAYING_POWERED_UP,
	LEVEL_COMPLETE,
	LEVEL_LOST,
	GAME_OVER
}

signal game_state_changed(state: GameState, old_state: GameState)
signal level_time_changed(remaining_time: int)
signal player_lives_changed(lives: int)
signal score_changed(score: int)
signal player_speed_changed(speed: float)
signal max_bomb_count_changed(count: int)
signal explosion_size_changed(size: int)
signal auto_detonate_changed(auto_detonate: bool)
signal picked_powerup_changed(powerup: Powerup.PowerupType)
signal enemy_killed(enemy_type: Enemy.EnemyType)
signal wall_pass_changed(wall_pass: bool)
signal immune_to_explosions_changed(immune_to_explosions: bool)
signal bomb_pass_changed(bomb_pass: bool)
signal invincible_changed(invincible: bool)

var main_scene: MainScene
var player: Player
var hud: Hud
var game_timer: Timer
var game_state: GameState = GameState.INITIAL
var stage: int = 1

var remaining_time: int = LEVEL_TIME:
	set(value):
		if value == remaining_time: return
		remaining_time = value
		level_time_changed.emit(remaining_time)

var lives: int = INITIAL_LIVES:
	set(value):
		if value == lives: return
		lives = value
		player_lives_changed.emit(lives)

var score: int = 0:
	set(value):
		if value == score: return
		score = value
		score_changed.emit(score)

var speed: float = INITIAL_SPEED:
	set(value):
		if value == speed: return
		speed = value
		player_speed_changed.emit(speed)

var max_bomb_count: int = 1:
	set(value):
		if value == max_bomb_count: return
		max_bomb_count = value
		max_bomb_count_changed.emit(max_bomb_count)

var explosion_size: int = 2:
	set(value):
		if value == explosion_size: return
		explosion_size = value
		explosion_size_changed.emit(explosion_size)

var auto_detonate: bool = true:
	set(value):
		if value == auto_detonate: return
		auto_detonate = value
		auto_detonate_changed.emit(auto_detonate)

var wall_pass: bool = false:
	set(value):
		if value == wall_pass: return
		wall_pass = value
		wall_pass_changed.emit(wall_pass)

var immune_to_explosions: bool = true:
	set(value):
		if value == immune_to_explosions: return
		immune_to_explosions = value
		immune_to_explosions_changed.emit(immune_to_explosions)

var bomb_pass: bool = false:
	set(value):
		if value == bomb_pass: return
		bomb_pass = value
		bomb_pass_changed.emit(bomb_pass)

var invincible: bool = false:
	set(value):
		if value == invincible: return
		invincible = value
		invincible_changed.emit(invincible)

var picked_powerup: Powerup.PowerupType = Powerup.PowerupType.NONE:
	set(value):
		if value == picked_powerup: return
		picked_powerup = value
		picked_powerup_changed.emit(picked_powerup)

func change_game_state(state: GameState) -> void:
	if state == game_state: return
	
	var old_state: GameState = game_state
	game_state = state
	game_state_changed.emit(state, old_state)

func _ready() -> void:
	game_state_changed.connect(_on_game_state_changed)
	enemy_killed.connect(_on_enemy_killed)

func init() -> void:
	main_scene = get_tree().current_scene
	player = get_tree().current_scene.get_node("Root/Player")
	hud = get_tree().current_scene.get_node("Hud")
	game_timer = get_tree().current_scene.get_node("Root/GameTimer")
	player.state_changed.connect(_on_player_state_changed)
	player.powerup_taken.connect(_on_powerup_taken)
	game_timer.timeout.connect(_on_game_timer_timeout)
	remaining_time = LEVEL_TIME;

	if lives == 0:
		lives = INITIAL_LIVES

func reset_game_state() -> void:
	stage = 1
	score = 0
	lives = INITIAL_LIVES
	speed = INITIAL_SPEED
	max_bomb_count = 1
	explosion_size = 1
	auto_detonate = true
	wall_pass = false
	immune_to_explosions = false
	bomb_pass = false
	invincible = false
	picked_powerup = Powerup.PowerupType.NONE

func _on_game_timer_timeout() -> void:
	remaining_time -= 1

	if remaining_time == 0:
		game_timer.stop()
		player.destroy(self)

func complete_level() -> void:
	change_game_state(GameState.LEVEL_COMPLETE)

func _on_game_state_changed(new_state: GameState, _old_state: GameState) -> void:
	match new_state:
		GameState.LEVEL_START:
			init()
			main_scene.level_start.get_node("StageLabel").text = "STAGE %s" % stage
			main_scene.level_start.show()
			SoundsPlayer.play_sound("level_start")
			await get_tree().create_timer(3).timeout
			main_scene.level_start.hide()
			change_game_state(GameState.PLAYING)
		GameState.PLAYING:
			game_timer.start()
			SoundsPlayer.play_sound("main_theme")
		GameState.LEVEL_COMPLETE:
			lives += 1
			stage += 1
			player.remove()
			SoundsPlayer.play_sound("level_finished")
			await get_tree().create_timer(3).timeout
			get_tree().reload_current_scene()
		GameState.LEVEL_LOST:
			if lives > 0:
				await get_tree().create_timer(4).timeout
				restart_scene()
			else:
				change_game_state(GameState.GAME_OVER)
		GameState.GAME_OVER:
			await get_tree().create_timer(3).timeout
			main_scene.game_over.show()
			SoundsPlayer.play_sound("game_over")
			await get_tree().create_timer(8).timeout
			reset_game_state()
			restart_scene()
		

func _on_enemy_killed(enemy_type: Enemy.EnemyType) -> void:
	score += ENEMY_POINTS[enemy_type]

func _on_powerup_taken(powerup_type: Powerup.PowerupType) -> void:
	score += POWERUP_POINTS
	
	if not SoundsPlayer.is_playing("powerup_theme"):
		SoundsPlayer.stop_sound("powerup_theme")
	
	match powerup_type:
		Powerup.PowerupType.SPEED:
			speed += 10
		Powerup.PowerupType.BOMB_COUNT:
			max_bomb_count += 1
		Powerup.PowerupType.EXPLOSION_SIZE:
			explosion_size += 1
		Powerup.PowerupType.REMOTE_CONTROL:
			auto_detonate = false
		Powerup.PowerupType.WALL_PASS:
			wall_pass = true
		Powerup.PowerupType.FLAME_PASS:
			immune_to_explosions = true
		Powerup.PowerupType.BOMB_PASS:
			bomb_pass = true
		Powerup.PowerupType.INVINCIBILITY:
			invincible = true
	
	picked_powerup = powerup_type

func _on_player_state_changed(new_state: Player.PlayerState, _old_state: Player.PlayerState) -> void:
	match new_state:
		Player.PlayerState.DYING:
			game_timer.stop()
			SoundsPlayer.stop_sound("main_theme")
			lives -= 1
		Player.PlayerState.DEAD:
			SoundsPlayer.play_sound("lost_life")
			change_game_state(GameState.LEVEL_LOST)
			
func restart_scene() -> void:
	get_tree().reload_current_scene()
