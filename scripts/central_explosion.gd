extends Area2D

class_name CentralExplosion

const DIRECTIONAL_EXPLOSION_SCENE = preload("res://scenes/directional_explosion.tscn")

@onready var raycasts: Array[RayCast2D] = [$Raycasts/Top, $Raycasts/Right, $Raycasts/Bottom, $Raycasts/Left]
@onready var explosion_center_sprite: AnimatedSprite2D = $AnimatedSprite2D

const FLAME_DIRECTION_COUNT = 4
const MIDDLE_ANIMATION_FRAME = 3
const MIDDLE_ANIMATIONS = ["top_middle", "right_middle", "bottom_middle", "left_middle"]
const END_ANIMATIONS = ["top_end", "right_end", "bottom_end", "left_end"]
const DIRECTION_VECTORS: Array[Vector2] = [Vector2.UP, Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT]

var explosion_size: int = 1
var flame_sizes: Array[int] = []
var brick_walls: Array[StaticBody2D] = []
var flame_current_sizes: Array[int] = [0, 0, 0, 0]

func configure_raycasts() -> void:
	for i in range(0, FLAME_DIRECTION_COUNT):
		raycasts[i].target_position = DIRECTION_VECTORS[i] * explosion_size * Globals.TILE_SIZE
		raycasts[i].force_raycast_update()

func _ready() -> void:
	configure_raycasts()

	for raycast in raycasts:
		var flame_size: int = explosion_size

		if raycast.is_colliding():
			var collider: Object = raycast.get_collider()
			var collision_point: Vector2 = to_local(raycast.get_collision_point())
			var tile_coords: Vector2 = Vector2(floor(collision_point.x / Globals.TILE_SIZE), floor(collision_point.y / Globals.TILE_SIZE))
			var collider_position: Vector2 = tile_coords * Globals.TILE_SIZE
			var collider_distance_vec: Vector2 = abs(raycast.position - collider_position) / Globals.TILE_SIZE
			var collider_distance: int = floor(max(collider_distance_vec.x, collider_distance_vec.y))
			
			flame_size = min(flame_size, collider_distance)

			if collider.has_method("destroy"):
				brick_walls.append(collider)
		
		flame_sizes.append(flame_size)
		explosion_center_sprite.play()

func _on_animated_sprite_2d_animation_finished() -> void:
	queue_free()


func _on_animated_sprite_2d_frame_changed() -> void:
	update_explosion_for_frame()


func update_explosion_for_frame() -> void:
	var frame: int = explosion_center_sprite.frame

	for i in range(0, FLAME_DIRECTION_COUNT):
		if frame <= MIDDLE_ANIMATION_FRAME and flame_sizes[i] > flame_current_sizes[i]:
			var flame_segment: DirectionalExplosion = DIRECTIONAL_EXPLOSION_SCENE.instantiate()
			flame_segment.position = position + DIRECTION_VECTORS[i] * Globals.TILE_SIZE * frame
			get_parent().add_child(flame_segment)
			
			if flame_sizes[i] == flame_current_sizes[i] + 1 and flame_sizes[i] == explosion_size:
				flame_segment.playAnimation(END_ANIMATIONS[i])
			else:
				flame_segment.playAnimation(MIDDLE_ANIMATIONS[i])
			
			flame_current_sizes[i] += 1
		elif flame_sizes[i] > flame_current_sizes[i]:
			for j in range(0, flame_sizes[i] - flame_current_sizes[i]):
				var flame_segment: DirectionalExplosion = DIRECTIONAL_EXPLOSION_SCENE.instantiate()
				flame_segment.position = position + DIRECTION_VECTORS[i] * Globals.TILE_SIZE * (frame + j)
				get_parent().add_child(flame_segment)
				
				if flame_sizes[i] - flame_current_sizes[i] == 1 and flame_sizes[i] == explosion_size:
					flame_segment.playAnimation(END_ANIMATIONS[i])
				else:
					flame_segment.playAnimation(MIDDLE_ANIMATIONS[i])
				
				flame_current_sizes[i] += 1
	
	if frame == MIDDLE_ANIMATION_FRAME:
		for brick_wall in brick_walls:
			brick_wall.destroy()


func _on_body_entered(body: Node2D) -> void:
	if body.has_method("destroy"):
		body.destroy()
