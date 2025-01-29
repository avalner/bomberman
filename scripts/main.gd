extends Node

const BRICK_WALL = preload("res://scenes/brick_wall.tscn")
const LEVEL_EXIT_DOOR = preload("res://scenes/level_exit_door.tscn")
const POWERUP = preload("res://scenes/powerup.tscn")
const TILE_SIZE = Globals.TILE_SIZE
const LEVEL_WIDTH = 29
const LEVEL_HEIGHT = 11
const CONCRETE_TILE_COUNT = 70
const PLAYER_AREA_SIZE = 3
const BRICK_WALL_FILL_RATE = 0.2
const LEVEL_OFFSET = Vector2(TILE_SIZE, TILE_SIZE) * 1.5

@onready var brick_walls_container: Node = $BrickWalls
@onready var tile_map_layer: TileMapLayer = $TileMapLayer

func _ready() -> void:
	Globals.change_game_state(Globals.GameState.LEVEL_START)
	procedurely_generate_level()

func procedurely_generate_level() -> void:
	var brick_wall_count = 0
	var available_tiles = LEVEL_WIDTH * LEVEL_HEIGHT - CONCRETE_TILE_COUNT - PLAYER_AREA_SIZE ** 2
	var max_brick_walls = int(available_tiles * BRICK_WALL_FILL_RATE)
	var powerup_x = randi() % LEVEL_WIDTH
	var powerup_y = randi() % LEVEL_HEIGHT
	var exit_door_x = randi() % LEVEL_WIDTH
	var exit_door_y = randi() % LEVEL_HEIGHT

	# Randomly determine coordinates for the powerup
	while (powerup_x < PLAYER_AREA_SIZE and powerup_y < PLAYER_AREA_SIZE) or (powerup_y % 2 != 0 and powerup_x % 2 != 0):
		powerup_x = randi() % LEVEL_WIDTH
		powerup_y = randi() % LEVEL_HEIGHT

	# Randomly determine coordinates for the level exit door
	while (exit_door_x < PLAYER_AREA_SIZE and exit_door_y < PLAYER_AREA_SIZE) or (exit_door_y % 2 != 0 and exit_door_x % 2 != 0):
		if (exit_door_x == powerup_x and exit_door_y == powerup_y): continue
		exit_door_x = randi() % LEVEL_WIDTH
		exit_door_y = randi() % LEVEL_HEIGHT

	var powerup = POWERUP.instantiate()
	powerup.position = Vector2(powerup_x * TILE_SIZE, powerup_y * TILE_SIZE) + LEVEL_OFFSET
	powerup.powerup_type = Powerup.PowerupType.BOMB_COUNT
	brick_walls_container.add_child(powerup)

	# Place a BRICK_WALL over the POWERUP
	var brick_wall = BRICK_WALL.instantiate()
	brick_wall.position = Vector2(powerup_x * TILE_SIZE, powerup_y * TILE_SIZE) + LEVEL_OFFSET
	brick_walls_container.add_child(brick_wall)
	brick_wall_count += 1

	var door = LEVEL_EXIT_DOOR.instantiate()
	door.name = "LevelExitDoor"
	door.position = Vector2(exit_door_x * TILE_SIZE, exit_door_y * TILE_SIZE) + LEVEL_OFFSET
	brick_walls_container.add_child(door)

	# Place a BRICK_WALL over the POWERUP
	brick_wall = BRICK_WALL.instantiate()
	brick_wall.position = Vector2(exit_door_x * TILE_SIZE, exit_door_y * TILE_SIZE) + LEVEL_OFFSET
	brick_walls_container.add_child(brick_wall)
	brick_wall_count += 1

	for y in range(LEVEL_HEIGHT):
		for x in range(LEVEL_WIDTH):
			# Skip the top-left 3x3 area for the player
			if (x < PLAYER_AREA_SIZE and y < PLAYER_AREA_SIZE) or (y % 2 != 0 and x % 2 != 0) or (x == powerup_x and y == powerup_y) or (x == exit_door_x and y == exit_door_y):
				continue
			else:
				# Place a BRICK_WALL if limit not reached
				if randi() % 100 < int(BRICK_WALL_FILL_RATE * 100) and brick_wall_count < max_brick_walls:
					brick_wall = BRICK_WALL.instantiate()
					brick_wall.position = Vector2(x * TILE_SIZE, y * TILE_SIZE) + LEVEL_OFFSET
					brick_walls_container.add_child(brick_wall)
					brick_wall_count += 1
