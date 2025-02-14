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

static func has_player_at_position(position: Vector2) -> bool:
	var nodes: Array[Node2D] = get_nodes_at_position(position)
	for node: Node2D in nodes:
		if node is Player: # Assuming Player is a defined class
			return true
	return false

static func has_bomb_at_position(position: Vector2) -> bool:
	var nodes: Array[Node2D] = get_nodes_at_position(position)
	for node: Node2D in nodes:
		if node is Bomb: # Assuming Bomb is a defined class
			return true
	return false


static func has_brick_wall_at_position(position: Vector2) -> bool:
	var nodes: Array[Node2D] = get_nodes_at_position(position)
	for node: Node2D in nodes:
		if node is BrickWall: # Assuming BrickWall is a defined class
			return true
	return false

static func has_wall_at_position(position: Vector2) -> bool:
	var nodes: Array[Node2D] = get_nodes_at_position(position)
	for node: Node2D in nodes:
		if node is BrickWall: # Assuming BrickWall is a defined class
			return true
	
	# Check for non-passable tiles in the TileMapLayer
	var tileMapLayer: TileMapLayer = Globals.tileMapLayer
	var cell_position: Vector2i = tileMapLayer.local_to_map(position)
	var tile_data: TileData = tileMapLayer.get_cell_tile_data(cell_position)
		
	if tile_data and not tile_data.get_custom_data("passable"):
		return true
	
	return false

static func get_nodes_at_position(position: Vector2) -> Array:
	var space_state: PhysicsDirectSpaceState2D = Globals.get_world_2d().direct_space_state
	var query_params: PhysicsPointQueryParameters2D = PhysicsPointQueryParameters2D.new()
	query_params.position = position
	query_params.collide_with_areas = true # Include Area2Ds
	query_params.collide_with_bodies = true # Include RigidBody2D, StaticBody2D, etc.
	query_params.collision_mask = COLLISTION_MASK.BRICK_WALLS | COLLISTION_MASK.PLAYER | COLLISTION_MASK.ENEMY | COLLISTION_MASK.BOMB | COLLISTION_MASK.POWERUP | COLLISTION_MASK.EXIT_DOOR
	
	var results: Array[Dictionary] = space_state.intersect_point(query_params)
	
	var nodes: Array[Node2D] = []
	for result in results:
		var node: Object = result.collider
		if node is Node2D:
			nodes.append(node)
	
	return nodes

static func is_tile_center(position: Vector2) -> bool:
	return Vector2i(round(position).x, round(position).y) % Globals.TILE_SIZE == Vector2i.ZERO

static func position_to_cell_position(position: Vector2) -> Vector2i:
	return (position / Globals.TILE_SIZE).round()

static func cell_position_to_position(cell_position: Vector2i) -> Vector2:
	return cell_position * Globals.TILE_SIZE

static func position_to_tile_center(position: Vector2) -> Vector2:
	return (position / Globals.TILE_SIZE).round() * Globals.TILE_SIZE
