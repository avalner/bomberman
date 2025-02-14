extends Area2D

class_name LevelExitDoor

# Track if the player is inside the Area2D
var is_player_inside := false
var player: Player

func is_centered(body: Node2D) -> bool:
	# Get the global positions of the Area2D and the player
	var area_position: Vector2 = global_position
	var player_position: Vector2 = body.global_position

	# Calculate the distance between the centers
	var distance: float = player_position.distance_to(area_position)

	# Check if the centers are approximately aligned
	return distance < 1.0 # Tweak this value to adjust the alignment threshold
		

func _on_body_entered(body:Node2D) -> void:
	if body is Player:
		player = body
		is_player_inside = true

func _on_body_exited(body:Node2D) -> void:
	if body is Player:
		is_player_inside = false

func _process(_delta:float) -> void:
	if not is_player_inside or not is_centered(player) or Utils.has_brick_wall_at_position(global_position): return        
	if Globals.enemy_count == 0:
		Globals.complete_level()
