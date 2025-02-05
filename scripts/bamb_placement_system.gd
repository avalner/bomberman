extends Node

class_name BombPlacementSystem

const BOMB_SCENE = preload("res://scenes/bomb.tscn")

var player: Player = null
var bombs_container: Node = null
var explosions_container: Node = null

func _ready() -> void:
	player = get_parent()
	bombs_container = player.bombs_container
	explosions_container = player.explosions_container

func place_bomb() -> void:
	if bombs_container.get_child_count() < Globals.max_bomb_count:
		var bombPosition: Vector2 = (player.position / Globals.TILE_SIZE).floor() * Globals.TILE_SIZE \
			 + Vector2(Globals.TILE_SIZE / 2.0, Globals.TILE_SIZE / 2.0)
		
		# Check if there is already a bomb in the same position
		for bomb in bombs_container.get_children():
			if is_instance_valid(bomb) and bomb.position == bombPosition:
				return
		
		var bomb: Bomb = BOMB_SCENE.instantiate()
		bomb.position = bombPosition
		bomb.explosion_size = Globals.explosion_size
		bomb.auto_detonate = Globals.auto_detonate
		bomb.explosions_container = explosions_container
		player.collision_mask &= ~(1 << 4) # 1 << 4 is the bomb layer
		bombs_container.add_child(bomb)

func detonate_bombs() -> void:
	for bomb in bombs_container.get_children():
		if is_instance_valid(bomb):
			bomb.detonate()
		await get_tree().create_timer(Globals.AUTO_DETONATE_DELAY).timeout
