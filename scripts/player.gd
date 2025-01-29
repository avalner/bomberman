extends CharacterBody2D

class_name Player

@export var bombs_container: Node = null
@export var explosions_container: Node = null
@onready var bomb_placement_system: BambPlacementSystem = $BambPlacementSystem
@onready var player_animations: AnimatedSprite2D = $PlayerAnimations

static var speed: float = 50
static var max_bomb_count: int = 1
static var explosion_size: int = 1
static var auto_detonate: bool = true

var picked_powerup: Powerup.PowerupType = Powerup.PowerupType.BOMB_COUNT

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

func changeState(new_state: PlayerState) -> void:
	if state != new_state:
		var old_state = state
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
			velocity = Vector2.RIGHT * speed
		PlayerState.MOVING_LEFT:
			velocity = Vector2.LEFT * speed
		PlayerState.MOVING_DOWN:
			velocity = Vector2.DOWN * speed
		PlayerState.MOVING_UP:
			velocity = Vector2.UP * speed
		_:
			velocity = Vector2.ZERO
		

	move_and_slide()

func apply_powerup(powerup: Powerup.PowerupType) -> void:
	match powerup:
		Powerup.PowerupType.SPEED:
			speed += 10
		Powerup.PowerupType.BOMB_COUNT:
			max_bomb_count += 1
		Powerup.PowerupType.EXPLOSION_SIZE:
			explosion_size += 1
		Powerup.PowerupType.REMOTE_CONTROL:
			auto_detonate = false
	
	picked_powerup = powerup
	powerup_taken.emit(powerup)
		

func remove():
	changeState(PlayerState.REMOVED)
	queue_free()
	

func destroy() -> void:
	changeState(PlayerState.DYING)


func _on_player_animations_animation_finished() -> void:
	if state == PlayerState.DYING:
		queue_free()
		changeState(PlayerState.DEAD)
