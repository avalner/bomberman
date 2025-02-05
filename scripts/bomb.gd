extends StaticBody2D

class_name Bomb

const EXPLOSION_SCENE = preload("res://scenes/central_explosion.tscn")

@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D
@onready var area_2d: Area2D = $Area2D
@onready var timer: Timer = $Timer

static var unexited_bombs: int = 0

var explosions_container: Node = null
var explosion_size := 1
var auto_detonate := true

func _ready() -> void:
	unexited_bombs += 1
	SoundsPlayer.play_sound("place_bomb")

	if auto_detonate:
		timer.start()

func _on_timer_timeout() -> void:
	detonate()
			
func _on_area_2d_body_exited(body: Node2D) -> void:
	# Enable bomb collistion mask when player leaves the bomb area
	if body is Player:
		if unexited_bombs > 0:
			unexited_bombs -= 1
		
		if unexited_bombs == 0:
			body.collision_mask |= Utils.COLLISTION_MASK.BOMB

func detonate() -> void:
	SoundsPlayer.play_sound("explosion")
	var explosion: CentralExplosion = EXPLOSION_SCENE.instantiate()
	explosion.explosion_size = explosion_size
	explosion.position = position
	explosions_container.add_child(explosion)
	queue_free()

func destroy(_source: Node) -> void:
	detonate()
