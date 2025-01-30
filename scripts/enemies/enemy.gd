extends CharacterBody2D

class_name Enemy

const TILE_SIZE = Globals.TILE_SIZE
const HALF_TILE_SIZE: int = 8
const MAP_OFFSET = Vector2(TILE_SIZE, TILE_SIZE) * 1.5
const TILE_CENTER_OFFSET = Vector2i(HALF_TILE_SIZE, HALF_TILE_SIZE)
const DIRECTION_COUNT: int = 4
const DIRECTION_VECTORS: Array[Vector2] = [Vector2.UP, Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT]

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var area_2d: Area2D = $Area2D

var speed: int = 30
var raycasts: Array[RayCast2D] = []
var direction: Vector2 = Vector2.ZERO
var raycasts_ready: bool = false
var is_dead: bool = false
	
func _ready() -> void:
	animated_sprite.animation_finished.connect(_on_animated_sprite_2d_animation_finished)
	area_2d.body_entered.connect(_on_area_2d_body_entered)
	create_raycasts()

func create_raycasts() -> void:
	for i in range(DIRECTION_COUNT):
		var raycast: RayCast2D = RayCast2D.new()
		raycast.position = DIRECTION_VECTORS[i] * 6
		raycast.target_position = DIRECTION_VECTORS[i] * 4
		raycast.collide_with_areas = true
		raycast.collide_with_bodies = true
		raycast.collision_mask = 0b10110
		raycast.force_raycast_update()
		raycasts.append(raycast)
		add_child(raycast)
	
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
	if !raycasts_ready:
		return
	
	if is_dead:
		velocity = Vector2.ZERO
		return

	calculate_velocity()
	move_and_slide()


func calculate_velocity() -> void:
	push_error("Method 'calculate_velocity' must be implemented in derived classes.")

func is_tile_center() -> bool:
	return Vector2i(ceil(position)) % TILE_SIZE == TILE_CENTER_OFFSET

func get_available_directions() -> Array[Vector2]:
	var available_directions: Array[Vector2] = []
	
	for i in range(DIRECTION_COUNT):
		if !raycasts[i].is_colliding():
			var next_position: Vector2 = position + DIRECTION_VECTORS[i] * TILE_SIZE
			#check if next position is not a wall
			if !isOutOfMap(next_position):
				available_directions.append(DIRECTION_VECTORS[i])
	
	return available_directions

func isOutOfMap(pos: Vector2) -> bool:
	return pos.x > (Globals.LEVEL_WIDTH + 1) * TILE_SIZE or pos.y > (Globals.LEVEL_HEIGHT + 1) * TILE_SIZE or \
		pos.x < TILE_SIZE or pos.y < TILE_SIZE

func destroy() -> void:
	is_dead = true
	animated_sprite.play("death")

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body is Player and !is_dead:
		body.destroy()


func _on_animated_sprite_2d_animation_finished() -> void:
	if animated_sprite.animation == "death":
		queue_free()
