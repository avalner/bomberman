extends Object
class_name Utils

static func wait_for_phisics_frames(frames: int, node: Node) -> void:
    for i in range(frames):
        await node.get_tree().physics_frame