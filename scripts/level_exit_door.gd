extends Area2D

class_name LevelExitDoor

# Track if the player is inside the Area2D
var is_player_inside := false
var player: Player

func check_if_centered(body):
    # Get the global positions of the Area2D and the player
    var area_position = global_position
    var player_position = body.global_position

    # Calculate the distance between the centers
    var distance = player_position.distance_to(area_position)

    # Check if the centers are approximately aligned
    if distance < 1.0: # Tweak this value to adjust the alignment threshold
        Globals.complete_level()

func _on_body_entered(body:Node2D) -> void:
    if body is Player:
        player = body
        is_player_inside = true

func _on_body_exited(body:Node2D) -> void:
    if body is Player:
        is_player_inside = false

func _process(_delta:float) -> void:
    if is_player_inside:
        check_if_centered(player)

