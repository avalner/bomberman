extends CharacterBody2D

class_name BalloonEnemy

const TILE_SIZE = Globals.TILE_SIZE
const HALF_TILE_SIZE: int = 8
const SPEED: int = 30
const MAP_OFFSET = Vector2(TILE_SIZE, TILE_SIZE) * 1.5
const TILE_CENTER_OFFSET = Vector2i(HALF_TILE_SIZE, HALF_TILE_SIZE)
const DIRECTION_COUNT: int = 4
const DIRECTION_VECTORS: Array[Vector2] = [Vector2.UP, Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT]

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var raycasts: Array[RayCast2D] = [
    $Raycasts/Top,
    $Raycasts/Right,
    $Raycasts/Bottom,
    $Raycasts/Left
]

var direction: Vector2 = Vector2.ZERO
var raycasts_ready: bool = false
var is_dead: bool = false
    
func _ready() -> void:
    call_deferred("_update_raycasts")

func _update_raycasts() -> void:
    await get_tree().physics_frame
    await get_tree().physics_frame
    for raycast in raycasts:
        raycast.force_raycast_update()
    raycasts_ready = true

func _process(_delta: float) -> void:
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
    
    if is_tile_center():
        var available_directions: Array[Vector2] = []
        
        for i in range(DIRECTION_COUNT):
            if !raycasts[i].is_colliding():
                available_directions.append(DIRECTION_VECTORS[i])
        
        # select random direction from available_directions
        if available_directions.size() > 0:
            if available_directions.has(direction) and randf() < 0.9:
                velocity = direction * SPEED
            else:
                direction = available_directions[randi() % available_directions.size()]
                velocity = direction * SPEED
        else:
            velocity = Vector2.ZERO
    
    move_and_slide()

func is_tile_center() -> bool:
    return Vector2i(ceil(position)) % TILE_SIZE == TILE_CENTER_OFFSET

func destroy() -> void:
    is_dead = true
    animated_sprite.play("death")

func _on_area_2d_body_entered(body: Node2D) -> void:
    if body is Player and !is_dead:
        body.destroy()


func _on_animated_sprite_2d_animation_finished() -> void:
    if animated_sprite.animation == "death":
        queue_free()
