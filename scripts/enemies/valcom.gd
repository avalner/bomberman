extends Enemy

class_name Valcom

const SPEED: int = 30

func _init() -> void:
	enemy_type = EnemyType.VALCOM
	speed = SPEED

func _tile_center_process(available_directions: Array[Vector2]) -> void:
	match state:
		State.MOVING:
			# select random direction from available_directions
			if available_directions.size() > 0:
				if available_directions.has(direction) and randf() < 0.9:
					velocity = direction * speed
				else:
					direction = available_directions[randi() % available_directions.size()]
					velocity = direction * speed
			else:
				velocity = Vector2.ZERO
