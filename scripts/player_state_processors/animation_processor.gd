extends Node

class_name AnimationProcessor

var player: Player

func _ready() -> void:
    player = get_parent()
    player.state_changed.connect(_on_state_changed)

func _on_state_changed(state: Player.PlayerState, _old_state: Player.PlayerState) -> void:
    if state == Player.PlayerState.DYING:
        player.player_animations.play("death")
    elif state == Player.PlayerState.MOVING_LEFT:
        player.player_animations.play("walk_left")
    elif state == Player.PlayerState.MOVING_RIGHT:
        player.player_animations.play("walk_right")
    elif state == Player.PlayerState.MOVING_UP:
        player.player_animations.play("walk_up")
    elif state == Player.PlayerState.MOVING_DOWN:
        player.player_animations.play("walk_down")
    elif state == Player.PlayerState.IDLE:
        player.player_animations.pause()