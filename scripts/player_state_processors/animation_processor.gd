extends Node

class_name AnimationProcessor

const animation_map = {
    Player.PlayerState.DYING: "death",
    Player.PlayerState.MOVING_LEFT: "walk_left",
    Player.PlayerState.MOVING_RIGHT: "walk_right",
    Player.PlayerState.MOVING_UP: "walk_up",
    Player.PlayerState.MOVING_DOWN: "walk_down"
}

const idle_map = {
    Player.PlayerState.MOVING_LEFT: "idle_left",
    Player.PlayerState.MOVING_RIGHT: "idle_right",
    Player.PlayerState.MOVING_UP: "idle_up",
    Player.PlayerState.MOVING_DOWN: "idle_down"
}

var player: Player

func _ready() -> void:
    player = get_parent()
    player.state_changed.connect(_on_state_changed)

func _on_state_changed(state: Player.PlayerState, old_state: Player.PlayerState) -> void:
    if state in animation_map:
        player.player_animations.play(animation_map[state])
    elif state == Player.PlayerState.IDLE:
        if old_state in idle_map:
            player.player_animations.play(idle_map[old_state])
        player.player_animations.pause()