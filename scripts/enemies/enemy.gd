extends CharacterBody2D

class_name Enemy

enum State {MOVING, THINKING, MOVING_TO_PLAYER, DEAD}

const TILE_SIZE = Globals.TILE_SIZE
const HALF_TILE_SIZE: int = 8
const MAP_OFFSET = Vector2(TILE_SIZE, TILE_SIZE) * 1.5
const TILE_CENTER_OFFSET = Vector2i(HALF_TILE_SIZE, HALF_TILE_SIZE)
const DIRECTION_COUNT: int = 4
const DIRECTION_VECTORS: Array[Vector2] = [Vector2.UP, Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT]
const MIN_TIME_TO_THINK: float = 0.5
const MAX_TIME_TO_THINK: float = 1.0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var area_2d: Area2D = $Area2D

signal state_changed(state: State, old_state: State)

var state: State = State.MOVING
var raycasts: Array[RayCast2D] = []
var raycasts_ready: bool = false
var direction: Vector2 = Vector2.ZERO
var thinking_timer: Timer = Timer.new()
var time_to_think: float = 0
var total_thinking_time: float = 0

func _ready() -> void:
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
		raycast.position = DIRECTION_VECTORS[i] * 6
		raycast.target_position = DIRECTION_VECTORS[i] * 4
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
	if !raycasts_ready or state == State.DEAD:
		velocity = Vector2.ZERO
		return
	
	if is_tile_center():
		stop_and_think()
		_tile_center_process(get_available_directions())
	
	move_and_slide()


func _tile_center_process(_available_directions: Array[Vector2]) -> void:
	push_error("Method '_tile_center_process' must be implemented in derived classes.")

func stop_and_think() -> void:
	if randf() < 0.01:
		change_state(State.THINKING)

func set_random_thinking_animation_time() -> void:
	thinking_timer.wait_time = randf_range(0.1, 1.2) # Set random interval (1 to 5 seconds)

func is_tile_center() -> bool:
	return Vector2i(ceil(position)) % TILE_SIZE == TILE_CENTER_OFFSET

func get_available_directions() -> Array[Vector2]:
	var available_directions: Array[Vector2] = []
	
	for i in range(DIRECTION_COUNT):
		if !raycasts[i].is_colliding():
			available_directions.append(DIRECTION_VECTORS[i])
	
	return available_directions

func destroy() -> void:
	change_state(State.DEAD)
	animated_sprite.play("death")

func _on_state_changed(new_state: State, _old_state: State) -> void:
	match new_state:
		State.DEAD:
			velocity = Vector2.ZERO
		State.MOVING:
			animated_sprite.play("default")
		State.THINKING:
			velocity = Vector2.ZERO
			animated_sprite.play("thinking")
			time_to_think = randf_range(MIN_TIME_TO_THINK, MAX_TIME_TO_THINK)
			set_random_thinking_animation_time()
			thinking_timer.start()
			

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body is Player and state != State.DEAD:
		body.destroy()


func _on_animated_sprite_2d_animation_finished() -> void:
	match animated_sprite.animation:
		"death":
			queue_free()

func _on_thinking_timer_timeout() -> void:
	total_thinking_time += thinking_timer.wait_time
	
	if total_thinking_time >= time_to_think:
		change_state(State.MOVING)
		total_thinking_time = 0
		thinking_timer.stop()
	else:
		animated_sprite.flip_h = !animated_sprite.flip_h
		set_random_thinking_animation_time()
