extends Area2D

class_name DirectionalExplosion

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

func playAnimation(animation_name: String) -> void:
    animated_sprite.play(animation_name)

func _on_body_entered(body:Node2D) -> void:
    if body.has_method("destroy"):
        body.destroy()


func _on_area_entered(area: Area2D) -> void:
    if area.has_method("destroy"):
        area.destroy()


func _on_animated_sprite_2d_animation_finished() -> void:
    queue_free()
