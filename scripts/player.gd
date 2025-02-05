@tool
extends CharacterBody2D

class_name Player

@export var bombs_container: Node = null:
	set(value):
		bombs_container = value
		update_configuration_warnings()
		
@export var explosions_container: Node = null:
	set(value):
		explosions_container = value
		update_configuration_warnings()

@onready var bomb_placement_system: BombPlacementSystem = $BombPlacementSystem
@onready var player_animations: AnimatedSprite2D = $PlayerAnimations

enum PlayerState {
	IDLE,
	MOVING_UP,
	MOVING_DOWN,
	MOVING_LEFT,
	MOVING_RIGHT,
	DYING,
	DEAD,
	REMOVED
}

signal state_changed(state: PlayerState, old_state: PlayerState)
signal powerup_taken(type: Powerup.PowerupType)

var state := PlayerState.IDLE

func _ready() -> void:
	motion_mode = MotionMode.MOTION_MODE_FLOATING
	Globals.wall_pass_changed.connect(_on_wall_pass_changed)
	Globals.bomb_pass_changed.connect(_on_bomb_pass_changed)

func changeState(new_state: PlayerState) -> void:
	if state != new_state:
		var old_state: PlayerState = state
		state = new_state
		state_changed.emit(state, old_state)

func _input(event: InputEvent) -> void:
	if !(event is InputEventKey) or state == PlayerState.DYING or state == PlayerState.DEAD:
		return
	
	if Input.is_action_pressed("right"):
		changeState(PlayerState.MOVING_RIGHT)
	elif Input.is_action_pressed("left"):
		changeState(PlayerState.MOVING_LEFT)
	elif Input.is_action_pressed("down"):
		changeState(PlayerState.MOVING_DOWN)
	elif Input.is_action_pressed("up"):
		changeState(PlayerState.MOVING_UP)
	else:
		changeState(PlayerState.IDLE)
	
	if event.is_action_pressed("place_bomb"):
		bomb_placement_system.place_bomb()
	elif event.is_action_pressed("detonate_bombs") and !Globals.auto_detonate:
		bomb_placement_system.detonate_bombs()

func _physics_process(_delta: float) -> void:
	match state:
		PlayerState.MOVING_RIGHT:
			velocity = Vector2.RIGHT * Globals.speed
		PlayerState.MOVING_LEFT:
			velocity = Vector2.LEFT * Globals.speed
		PlayerState.MOVING_DOWN:
			velocity = Vector2.DOWN * Globals.speed
		PlayerState.MOVING_UP:
			velocity = Vector2.UP * Globals.speed
		_:
			velocity = Vector2.ZERO
		

	move_and_slide()

func apply_powerup(powerup: Powerup.PowerupType) -> void:
	powerup_taken.emit(powerup)
		

func remove() -> void:
	changeState(PlayerState.REMOVED)
	queue_free()
	

func destroy(source: Node) -> void:
	if state == PlayerState.DEAD:
		return

	if (source is CentralExplosion or source is DirectionalExplosion) and Globals.immune_to_explosions:
		return

	if source is Enemy and Globals.invincible:
		return
	
	changeState(PlayerState.DYING)

func _on_wall_pass_changed(wall_pass: bool) -> void:
	if wall_pass:
		collision_mask &= ~(1 << 2) # Remove the WALL layer from the collision mask
	else:
		collision_mask |= (1 << 2) # Add the WALL layer to the collision mask

func _on_bomb_pass_changed(bomb_pass: bool) -> void:
	if bomb_pass:
		collision_mask &= ~(1 << 4) # Remove the BOMB layer from the collision mask
	else:
		collision_mask |= (1 << 4) # Add the BOMB layer to the collision mask

func _on_player_animations_animation_finished() -> void:
	if state == PlayerState.DYING:
		queue_free()
		changeState(PlayerState.DEAD)
		
func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray = PackedStringArray()
	
	if !bombs_container:
		warnings.append("bombs_container is mandatory")
	
	if !explosions_container:
		warnings.append("explosions_container is mandatory")
	
	return warnings
