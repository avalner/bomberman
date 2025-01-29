extends Control

class_name DebugDisplay

var debug_positions: Array[Vector2] = []

func _ready() -> void:
	set_process(true)
	
func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	for pos in debug_positions:
		var local_position = pos - global_position;
		draw_circle(local_position, 2, Color("red"))
	
func set_debug_position(pos: Vector2) -> void:
	debug_positions.append(pos)