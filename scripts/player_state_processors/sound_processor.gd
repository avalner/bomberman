extends Node

class_name SoundProcessor

var player: Player

func _ready() -> void:
	player = get_parent()
	player.state_changed.connect(_on_state_changed)
	player.powerup_taken.connect(_on_powerup_taken)

func _on_state_changed(state: Player.PlayerState, _old_state: Player.PlayerState) -> void:
	if state == Player.PlayerState.DYING:
		SoundsPlayer.play_sound("death")
	elif state == Player.PlayerState.MOVING_LEFT or state == Player.PlayerState.MOVING_RIGHT:
		SoundsPlayer.play_sound("footsteps")
	elif state == Player.PlayerState.MOVING_UP or state == Player.PlayerState.MOVING_DOWN:
		SoundsPlayer.play_sound("footsteps_alt")
	elif state == Player.PlayerState.IDLE:
		SoundsPlayer.stop_sound_group("player")
	elif state == Player.PlayerState.DEAD:
		SoundsPlayer.stop_sound_group("player")
		SoundsPlayer.play_sound("game_over")
	elif state == Player.PlayerState.REMOVED:
		SoundsPlayer.stop_sound_group("player")

func _on_powerup_taken(_powerup_type: Powerup.PowerupType):
	SoundsPlayer.play_sound("powerup")