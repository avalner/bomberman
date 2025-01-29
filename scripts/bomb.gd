extends StaticBody2D

const EXPLOSION_SCENE = preload("res://scenes/central_explosion.tscn")

@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D
@onready var timer: Timer = $Timer

var explosions_container: Node = null
var explosion_size := 1
var auto_detonate := true

func _ready() -> void:
	SoundsPlayer.play_sound("place_bomb")

	if auto_detonate:
		timer.start()

func _on_timer_timeout() -> void:
	detonate()
			
func _on_area_2d_body_exited(body: Node2D) -> void:
	# Enable bomb collistion mask when player leaves the bomb area
	if body is Player:
		body.collision_mask = body.collision_mask | (1 << 4) # 1 << 4 is the bomb layer

func detonate() -> void:
	SoundsPlayer.play_sound("explosion")
	var explosion = EXPLOSION_SCENE.instantiate()
	explosion.explosion_size = explosion_size
	explosion.global_position = global_position
	explosions_container.call_deferred("add_child", explosion)
	queue_free()

func destroy() -> void:
	detonate()
