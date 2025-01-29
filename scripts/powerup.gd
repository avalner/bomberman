extends Area2D

class_name Powerup

enum PowerupType {
    BOMB_COUNT,
    EXPLOSION_SIZE,
    SPEED,
    REMOTE_CONTROL,
    WALL_PASS,
    BOMB_PASS,
    FLAME_PASS,
    INVINCIBILITY
}

@onready var sprites: Array[Sprite2D] = [
    $BombSprite,
    $FireSprite,
    $SpeedSprite,
    $RemoteControlSprite,
    $WallPassSprite,
    $BombPassSprite,
    $FlamePassSprite,
    $InvincibilitySprite
]

@export var powerup_type: PowerupType = PowerupType.BOMB_COUNT

var fade_speed = 1.5 # Speed of the fade effect
var increasing = true # Tracks whether the alpha is increasing or decreasing

func _ready() -> void:
    for sprite in sprites:
        sprite.hide()
    
    sprites[powerup_type].show()

func _process(delta: float):
    animate(delta)

func animate(delta: float) -> void:
    if increasing:
        modulate.a += fade_speed * delta # Fade in
        if modulate.a >= 1.0: # Clamp alpha
            modulate.a = 1.0
            increasing = false
    else:
        modulate.a -= fade_speed * delta # Fade out
        if modulate.a <= 0.2: # Clamp alpha
            modulate.a = 0.2
            increasing = true

func _on_body_entered(body: Node2D) -> void:
    if body.has_method("apply_powerup"):
        SoundsPlayer.play_sound("powerup")
        body.apply_powerup(powerup_type)
    queue_free()

func destroy() -> void:
    queue_free()
