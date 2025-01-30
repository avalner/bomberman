extends Node

const BRICK_WALL = preload("res://scenes/brick_wall.tscn")
const LEVEL_EXIT_DOOR = preload("res://scenes/level_exit_door.tscn")
const POWERUP = preload("res://scenes/powerup.tscn")
const BALLOON_ENEMY = preload("res://scenes/enemies/valcom.tscn")

const TILE_SIZE = Globals.TILE_SIZE
const LEVEL_WIDTH = 29
const LEVEL_HEIGHT = 11
const PLAYER_AREA_SIZE = 3
const BRICK_WALL_FILL_RATE = 0.5
const LEVEL_OFFSET = Vector2(TILE_SIZE, TILE_SIZE) * 1.5

@onready var brick_walls_container: Node = $BrickWalls
@onready var enemies_container: Node = $Enemies
@onready var tile_map_layer: TileMapLayer = $TileMapLayer

func _ready() -> void:
    Globals.change_game_state(Globals.GameState.LEVEL_START)
    procedurely_generate_level()

func procedurely_generate_level() -> void:
    var occupied_tiles: Array[Vector2] = []
    occupied_tiles.append_array(get_player_start_area_tiles())
    occupied_tiles.append_array(get_concrete_tiles())
    var powerup_position: Vector2 = get_random_tile_position(occupied_tiles)
    var exit_door_position: Vector2 = get_random_tile_position(occupied_tiles)

    place_power_up(powerup_position, Powerup.PowerupType.BOMB_COUNT)
    place_level_exit_door(exit_door_position)
    
    var max_brick_walls: int = int(occupied_tiles.size() * BRICK_WALL_FILL_RATE)
    place_brick_walls(max_brick_walls, occupied_tiles)
    place_valcoms(5, occupied_tiles)

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
            if y % 2 != 0 or x % 2 != 0:
                concrete_tile_positions.append(Vector2(x, y))
    return concrete_tile_positions

func get_player_start_area_tiles() -> Array[Vector2]:
    var player_start_area_tiles: Array[Vector2] = []
    for y in range(PLAYER_AREA_SIZE):
        for x in range(PLAYER_AREA_SIZE):
            player_start_area_tiles.append(Vector2(x, y))
    return player_start_area_tiles

func place_level_exit_door(exit_door_position: Vector2) -> void:
    var door: LevelExitDoor = LEVEL_EXIT_DOOR.instantiate()
    door.name = "LevelExitDoor"
    door.position = exit_door_position * TILE_SIZE + LEVEL_OFFSET
    brick_walls_container.add_child(door)
    place_brick_wall(exit_door_position) # Place a BRICK_WALL over the LEVEL_EXIT_DOOR

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

func place_valcoms(count: int, occupied_tiles: Array[Vector2]) -> void:
    for i in count:
        var balloon: Valcom = BALLOON_ENEMY.instantiate()
        var balloon_position: Vector2 = get_random_tile_position(occupied_tiles)
        balloon.position = balloon_position * TILE_SIZE + LEVEL_OFFSET
        enemies_container.add_child(balloon)

func place_brick_walls(max_brick_walls: int, occupied_tiles: Array[Vector2]) -> void:
    var brick_wall_count: int = 0
    
    for y in range(LEVEL_HEIGHT):
        for x in range(LEVEL_WIDTH):
            var wall_position: Vector2 = Vector2(x, y)
            
            if occupied_tiles.has(wall_position):
                continue
            else:
                # Place a BRICK_WALL if limit not reached
                if randi() % 100 < int(BRICK_WALL_FILL_RATE * 100) and brick_wall_count < max_brick_walls:
                    place_brick_wall(Vector2(x, y))
                    brick_wall_count += 1
