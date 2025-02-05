extends Node

class_name MainScene

const BRICK_WALL = preload("res://scenes/brick_wall.tscn")
const LEVEL_EXIT_DOOR = preload("res://scenes/level_exit_door.tscn")
const POWERUP = preload("res://scenes/powerup.tscn")

const VALCOM = preload("res://scenes/enemies/valcom.tscn")
const ONEAL = preload("res://scenes/enemies/o_neal.tscn")

const TILE_SIZE = Globals.TILE_SIZE
const LEVEL_WIDTH = Globals.LEVEL_WIDTH
const LEVEL_HEIGHT = Globals.LEVEL_HEIGHT
const PLAYER_AREA_SIZE = 3
const BRICK_WALL_FILL_RATE = 0.8
const LEVEL_OFFSET = Globals.LEVEL_OFFSET

@onready var level_start: PanelContainer = $LevelStart
@onready var game_over: PanelContainer = $GameOver
@onready var brick_walls_container: Node = $Root/BrickWalls
@onready var enemies_container: Node = $Root/Enemies
@onready var tile_map_layer: TileMapLayer = $Root/TileMapLayer
@onready var game_timer: Timer = $Root/GameTimer
@onready var hud: Hud = $Hud

func _ready() -> void:
	Globals.change_game_state(Globals.GameState.LEVEL_START)
	procedurely_generate_level()

func procedurely_generate_level() -> void:
	var occupied_tiles: Array[Vector2] = []
	occupied_tiles.append_array(get_player_start_area_tiles())
	occupied_tiles.append_array(get_concrete_tiles())
	
	place_random_powerup(occupied_tiles)
	place_level_exit_door(occupied_tiles)
	
	var max_brick_walls: int = int(occupied_tiles.size() * BRICK_WALL_FILL_RATE)
	place_brick_walls(max_brick_walls, occupied_tiles)
	place_enemy(VALCOM, 3, occupied_tiles)
	place_enemy(ONEAL, 3, occupied_tiles)

func get_random_tile_position(occupied_tiles: Array[Vector2]) -> Vector2:
	var x: int = randi() % LEVEL_WIDTH
	var y: int = randi() % LEVEL_HEIGHT
	
	while occupied_tiles.has(Vector2(x, y)):
		x = randi() % LEVEL_WIDTH
		y = randi() % LEVEL_HEIGHT

	occupied_tiles.append(Vector2(x, y))
	
	return Vector2(x, y)

func get_concrete_tiles() -> Array[Vector2]:
	var concrete_tile_positions: Array[Vector2] = []
	
	for x in range(LEVEL_WIDTH):
		for y in range(LEVEL_HEIGHT):
			if y % 2 != 0 and x % 2 != 0:
				concrete_tile_positions.append(Vector2(x, y))
	return concrete_tile_positions

func get_player_start_area_tiles() -> Array[Vector2]:
	var player_start_area_tiles: Array[Vector2] = []
	for y in range(PLAYER_AREA_SIZE):
		for x in range(PLAYER_AREA_SIZE):
			player_start_area_tiles.append(Vector2(x, y))
	return player_start_area_tiles

func place_level_exit_door(occupied_tiles: Array[Vector2]) -> void:
	var exit_door_position: Vector2 = get_random_tile_position(occupied_tiles)
	var door: LevelExitDoor = LEVEL_EXIT_DOOR.instantiate()
	door.name = "LevelExitDoor"
	door.position = exit_door_position * TILE_SIZE + LEVEL_OFFSET
	brick_walls_container.add_child(door)
	place_brick_wall(exit_door_position) # Place a BRICK_WALL over the LEVEL_EXIT_DOOR

func place_random_powerup(occupied_tiles: Array[Vector2]) -> void:
	var powerup_position: Vector2 = get_random_tile_position(occupied_tiles)
	var powerup_type: Powerup.PowerupType = Powerup.PowerupType.NONE
	var random: float = randf()
	
	if  random < 0.8:
		random = randf()
		
		if random < 0.25:
			powerup_type = Powerup.PowerupType.BOMB_COUNT
		elif random < 0.5:
			powerup_type = Powerup.PowerupType.EXPLOSION_SIZE
		elif random < 0.75:
			powerup_type = Powerup.PowerupType.SPEED
		else:
			powerup_type = Powerup.PowerupType.REMOTE_CONTROL
	else:
		random = randf()

		if random < 0.3:
			powerup_type = Powerup.PowerupType.WALL_PASS
		elif random < 0.6:
			powerup_type = Powerup.PowerupType.BOMB_PASS
		elif random < 0.9:
			powerup_type = Powerup.PowerupType.FLAME_PASS
		else:
			powerup_type = Powerup.PowerupType.INVINCIBILITY
	
	place_power_up(powerup_position, powerup_type)

func place_power_up(power_up_position: Vector2, type: Powerup.PowerupType) -> void:
	var powerup: Powerup = POWERUP.instantiate()
	powerup.position = power_up_position * TILE_SIZE + LEVEL_OFFSET
	powerup.powerup_type = type
	brick_walls_container.add_child(powerup)
	place_brick_wall(power_up_position) # Place a BRICK_WALL over the POWERUP

func place_brick_wall(brick_position: Vector2) -> void:
	var brick_wall: BrickWall = BRICK_WALL.instantiate()
	brick_wall.position = brick_position * TILE_SIZE + LEVEL_OFFSET
	brick_walls_container.add_child(brick_wall)

func place_enemy(enemy_scene: PackedScene, count: int, occupied_tiles: Array[Vector2]) -> void:
	for i in count:
		var enemy: Enemy = enemy_scene.instantiate()
		var balloon_position: Vector2 = get_random_tile_position(occupied_tiles)
		enemy.position = balloon_position * TILE_SIZE + LEVEL_OFFSET
		enemies_container.add_child(enemy)

func place_brick_walls(max_brick_walls: int, occupied_tiles: Array[Vector2]) -> void:
	for i in range(max_brick_walls):
		var brick_position: Vector2 = get_random_tile_position(occupied_tiles)
		place_brick_wall(brick_position)
