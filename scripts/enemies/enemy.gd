extends CharacterBody2D

class_name Enemy

enum EnemyType {VALCOM, ONEAL}
enum State {MOVING, THINKING, MOVING_TO_PLAYER, DEAD}

const TILE_SIZE = Globals.TILE_SIZE
const DIRECTION_COUNT: int = 4
const DIRECTION_VECTORS: Array[Vector2] = [Vector2.UP, Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT]
const MIN_TIME_TO_THINK: float = 0.5
const MAX_TIME_TO_THINK: float = 1.0
const DEFAULT_SPEED: int = 30
const THINKING_CHANCE: float = 0.01

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var area_2d: Area2D = $Area2D
@onready var player: Node2D = Globals.player

signal state_changed(state: State, old_state: State)

var astar: AStarGrid2D;
var enemy_type: EnemyType
var speed: int = DEFAULT_SPEED
var state: State = State.MOVING
var raycasts: Array[RayCast2D] = []
var raycasts_ready: bool = false
var direction: Vector2 = Vector2.ZERO
var thinking_timer: Timer = Timer.new()
var time_to_think: float = 0
var total_thinking_time: float = 0
var path: Array[Vector2i] = []
var path_index: int = 0

func _ready() -> void:
	astar = Globals.main_scene.astar_grid
	state_changed.connect(_on_state_changed)
	animated_sprite.animation_finished.connect(_on_animated_sprite_2d_animation_finished)
	area_2d.body_entered.connect(_on_area_2d_body_entered)
	thinking_timer.autostart = false
	thinking_timer.one_shot = false
	thinking_timer.timeout.connect(_on_thinking_timer_timeout)
	add_child(thinking_timer)
	call_deferred("_create_raycasts")

func change_state(new_state: State) -> void:
	if state == new_state:
		return
	
	var old_state: State = state
	state = new_state
	state_changed.emit(state, old_state)

func _create_raycasts() -> void:
	for i in range(DIRECTION_COUNT):
		var raycast: RayCast2D = RayCast2D.new()
		raycast.position = DIRECTION_VECTORS[i] * 4
		raycast.target_position = DIRECTION_VECTORS[i] * 6
		raycast.collide_with_areas = true
		raycast.collide_with_bodies = true
		raycast.collision_mask = 0b10110
		raycasts.append(raycast)
		add_child(raycast)
	
	# await for phicical frame
	await Utils.wait_for_phisics_frames(10, self)
	raycasts_ready = true

func _process(_delta: float) -> void:
	adjust_sprite_direction()

func adjust_sprite_direction() -> void:
	match direction:
		Vector2.LEFT:
			animated_sprite.flip_h = true
		Vector2.RIGHT:
			animated_sprite.flip_h = false

func _physics_process(_delta: float) -> void:
	if !raycasts_ready or state == State.DEAD or Globals.game_state == Globals.GameState.LEVEL_START:
		velocity = Vector2.ZERO
		return
	
	if state == State.MOVING_TO_PLAYER:
		move_to_player()
	else:
		if Utils.is_tile_center(position) or velocity == Vector2.ZERO:
			stop_and_think()
			_tile_center_process(get_available_directions())
	
	move_and_slide()

func move_to_player() -> void:
	if path_index >= path.size():
		velocity = Vector2.ZERO
		change_state(State.MOVING)
		return
	
	var target_pos: Vector2 = Utils.cell_position_to_position(path[path_index])
		
	if position.distance_to(target_pos) < 1:
		if path_index + 1 < path.size():
			var next_pos: Vector2 = Utils.cell_position_to_position(path[path_index + 1])
			if Utils.has_bomb_at_position(get_parent().to_global(next_pos)):
				velocity = Vector2.ZERO
				change_state(State.MOVING)
				return
		path_index += 1
	else:		
		direction = (target_pos - position).normalized()
		velocity = direction * speed

func _tile_center_process(_available_directions: Array[Vector2]) -> void:
	push_error("Method '_tile_center_process' must be implemented in derived classes.")

func stop_and_think() -> void:
	if randf() < THINKING_CHANCE:
		change_state(State.THINKING)

func set_random_thinking_animation_time() -> void:
	thinking_timer.wait_time = randf_range(0.1, 1.2) # Set random interval (1 to 5 seconds)

func get_available_directions() -> Array[Vector2]:
	var available_directions: Array[Vector2] = []
	
	for i in range(DIRECTION_COUNT):
		if !raycasts[i].is_colliding():
			available_directions.append(DIRECTION_VECTORS[i])
	
	return available_directions

func destroy(_source: Node) -> void:
	change_state(State.DEAD)

func _on_state_changed(new_state: State, _old_state: State) -> void:
	match new_state:
		State.DEAD:
			animated_sprite.play("death")
			velocity = Vector2.ZERO
			collision_layer = 0
			collision_mask = 0
			area_2d.collision_layer = 0
			area_2d.collision_mask = 0
			thinking_timer.stop()
			Globals.enemy_killed.emit(enemy_type)
		State.MOVING:
			animated_sprite.play("default")
		State.THINKING:
			velocity = Vector2.ZERO
			animated_sprite.play("thinking")
			time_to_think = randf_range(MIN_TIME_TO_THINK, MAX_TIME_TO_THINK)
			set_random_thinking_animation_time()
			thinking_timer.start()
		State.MOVING_TO_PLAYER:
			animated_sprite.play("default")
			calculate_path_to_player()

func calculate_path_to_player() -> void:
	if !is_instance_valid(player) or player.state == Player.PlayerState.DYING or player.state == Player.PlayerState.DEAD:
		change_state(State.MOVING)
		return

	var fromPosition: Vector2i = Utils.position_to_cell_position(position)
	var toPosition: Vector2i = Utils.position_to_cell_position(player.position)
	
	path = astar.get_id_path(fromPosition, toPosition)
	path_index = 0

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body is Player:
		body.destroy(self)

func _on_animated_sprite_2d_animation_finished() -> void:
	match animated_sprite.animation:
		"death":
			queue_free()

func _on_thinking_timer_timeout() -> void:
	total_thinking_time += thinking_timer.wait_time
	
	if total_thinking_time >= time_to_think:
		change_state(State.MOVING_TO_PLAYER)
		total_thinking_time = 0
		thinking_timer.stop()
	else:
		animated_sprite.flip_h = !animated_sprite.flip_h
		set_random_thinking_animation_time()
