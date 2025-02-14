extends StaticBody2D

class_name BrickWall

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

func destroy() -> void:
    collision_layer = 0
    animated_sprite_2d.play("destroy")
    Globals.set_astar_point_enabled(position)
    
    if Utils.has_player_at_position(global_position):
         Globals.player.destroy(self)
    
func _on_animated_sprite_2d_animation_finished() -> void:
    queue_free()
