extends Object

class_name Utils

const COLLISTION_MASK = {
    "PLAYER": 1,
    "CONCRETE_WALLS": 1 << 1,
    "BRICK_WALLS": 1 << 2,
    "ENEMY": 1 << 3,
    "BOMB": 1 << 4,
    "POWERUP": 1 << 5,
    "EXIT_DOOR": 1 << 6
}


static func wait_for_phisics_frames(frames: int, node: Node) -> void:
    for i in range(frames):
        await node.get_tree().physics_frame