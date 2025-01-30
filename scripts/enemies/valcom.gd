extends Enemy

class_name Valcom

func _ready() -> void:
	speed = 30
	super._ready()
	
func calculate_velocity() -> void:
	if is_tile_center():
		var available_directions: Array[Vector2] = get_available_directions()
		# select random direction from available_directions
		if available_directions.size() > 0:
			if available_directions.has(direction) and randf() < 0.9:
				velocity = direction * speed
			else:
				direction = available_directions[randi() % available_directions.size()]
				velocity = direction * speed
		else:
			velocity = Vector2.ZERO
