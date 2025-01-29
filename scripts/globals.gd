extends Node

const TILE_SIZE = 16
const AUTO_DETONATE_DELAY: float = 0.2

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

var player: Player

var game_state: GameState = GameState.INITIAL
        
func change_game_state(state: GameState) -> void:
    if state == game_state: return
    
    var old_state: GameState = game_state
    game_state = state
    game_state_changed.emit(state, old_state)

func _ready() -> void:
    game_state_changed.connect(_on_game_state_changed)
    init()

func init() -> void:
    player = get_tree().current_scene.get_node("Player")
    player.state_changed.connect(_on_player_state_changed)
    player.powerup_taken.connect(_on_powerup_taken)


func complete_level() -> void:
    change_game_state(GameState.LEVEL_COMPLETE)

func _on_game_state_changed(new_state: GameState, _old_state: GameState) -> void:
    match new_state:
        GameState.LEVEL_START:
            init()
            SoundsPlayer.play_sound("level_start")
            await get_tree().create_timer(3).timeout
            change_game_state(GameState.PLAYING)
        GameState.PLAYING:
            SoundsPlayer.play_sound("main_theme")
        GameState.LEVEL_COMPLETE:            
            player.remove()
            SoundsPlayer.play_sound("level_finished")
            await get_tree().create_timer(3).timeout
            get_tree().reload_current_scene()

func _on_powerup_taken(_powerup_type: Powerup.PowerupType) -> void:
    SoundsPlayer.play_sound("powerup_theme")

func _on_player_state_changed(new_state: Player.PlayerState, _old_state: Player.PlayerState) -> void:
    match new_state:
        Player.PlayerState.DYING:
            SoundsPlayer.stop_sound("main_theme")
        Player.PlayerState.DEAD:
            SoundsPlayer.play_sound("lost_life")
            var timer: Timer = Timer.new()
            timer.wait_time = 3.0
            timer.one_shot = true
            timer.timeout.connect(restart_game)
            add_child(timer)
            timer.start()

func restart_game() -> void:
    get_tree().reload_current_scene()