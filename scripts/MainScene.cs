using Godot;
using System;
using System.Collections.Generic;

public partial class MainScene : Node
{
    private const int TileSize = Globals.TILE_SIZE;
    private const int LevelWidth = Globals.LEVEL_WIDTH;
    private const int LevelHeight = Globals.LEVEL_HEIGHT;
    private const int PlayerAreaSize = 3;
    private const float BrickWallFillRate = 0.8f;

    private static readonly PackedScene BrickWallScene = GD.Load<PackedScene>("res://scenes/brick_wall.tscn");
    private static readonly PackedScene LevelExitDoorScene = GD.Load<PackedScene>("res://scenes/level_exit_door.tscn");
    private static readonly PackedScene PowerupScene = GD.Load<PackedScene>("res://scenes/powerup.tscn");
    private static readonly PackedScene ValcomScene = GD.Load<PackedScene>("res://scenes/enemies/valcom.tscn");
    private static readonly PackedScene OnealScene = GD.Load<PackedScene>("res://scenes/enemies/o_neal.tscn");

    public PanelContainer LevelStart { get; private set; }
    public PanelContainer GameOver { get; private set; }
    private Node _brickWallsContainer;
    private Node _enemiesContainer;
    private TileMapLayer _tileMapLayer;
    private Timer _gameTimer;
    private Hud _hud;

    public readonly AStarGrid2D AstarGrid = new AStarGrid2D();

    public override void _Ready()
    {
        LevelStart = GetNode<PanelContainer>("LevelStart");
        GameOver = GetNode<PanelContainer>("GameOver");
        _brickWallsContainer = GetNode<Node>("Root/BrickWalls");
        _enemiesContainer = GetNode<Node>("Root/Enemies");
        _tileMapLayer = GetNode<TileMapLayer>("TileMapLayer");
        _gameTimer = GetNode<Timer>("Root/GameTimer");
        Globals.Instance.ChangeGameState(Globals.GameState.LEVEL_START);
        ProcedurallyGenerateLevel();
        CallDeferred(nameof(InitializeAstar));
    }

    private void InitializeAstar()
    {
        // Initialize AStar2D with the map grid
        AstarGrid.Region = new Rect2I(0, 0, LevelWidth, LevelHeight);
        AstarGrid.CellSize = new Vector2(TileSize, TileSize);
        AstarGrid.DiagonalMode = AStarGrid2D.DiagonalModeEnum.Never;
        AstarGrid.Update();

        foreach (var concreteTilePos in GetConcreteTiles())
        {
            AstarGrid.SetPointSolid(concreteTilePos, true);
        }

        foreach (Node node in _brickWallsContainer.GetChildren())
        {
            if (node is BrickWall brickWall)
            {
                AstarGrid.SetPointSolid(Utils.PositionToCellPosition(brickWall.Position), true);
            }
        }
    }

    private void ProcedurallyGenerateLevel()
    {
        var occupiedTiles = new List<Vector2I>();
        occupiedTiles.AddRange(GetPlayerStartAreaTiles());
        occupiedTiles.AddRange(GetConcreteTiles());

        PlaceRandomPowerup(occupiedTiles);
        PlaceLevelExitDoor(occupiedTiles);

        int maxBrickWalls = (int)(occupiedTiles.Count * BrickWallFillRate);
        PlaceBrickWalls(maxBrickWalls, occupiedTiles);
        PlaceEnemy(ValcomScene, 3, occupiedTiles);
        PlaceEnemy(OnealScene, 3, occupiedTiles);
    }

    private Vector2I GetRandomTilePosition(List<Vector2I> occupiedTiles)
    {
        int x = (int)(GD.Randi() % LevelWidth);
        int y = (int)(GD.Randi() % LevelHeight);

        while (occupiedTiles.Contains(new Vector2I(x, y)))
        {
            x = (int)(GD.Randi() % LevelWidth);
            y = (int)(GD.Randi() % LevelHeight);
        }

        occupiedTiles.Add(new Vector2I(x, y));
        return new Vector2I(x, y);
    }

    private List<Vector2I> GetConcreteTiles()
    {
        var concreteTilePositions = new List<Vector2I>();

        for (int x = 0; x < LevelWidth; x++)
        {
            for (int y = 0; y < LevelHeight; y++)
            {
                if (y % 2 != 0 && x % 2 != 0)
                {
                    concreteTilePositions.Add(new Vector2I(x, y));
                }
            }
        }

        return concreteTilePositions;
    }

    private List<Vector2I> GetPlayerStartAreaTiles()
    {
        var playerStartAreaTiles = new List<Vector2I>();

        for (int y = 0; y < PlayerAreaSize; y++)
        {
            for (int x = 0; x < PlayerAreaSize; x++)
            {
                playerStartAreaTiles.Add(new Vector2I(x, y));
            }
        }

        return playerStartAreaTiles;
    }

    private void PlaceLevelExitDoor(List<Vector2I> occupiedTiles)
    {
        Vector2I exitDoorPosition = GetRandomTilePosition(occupiedTiles);
        var door = (LevelExitDoor)LevelExitDoorScene.Instantiate();
        door.Name = "LevelExitDoor";
        door.Position = exitDoorPosition * TileSize;
        _brickWallsContainer.AddChild(door);
        PlaceBrickWall(exitDoorPosition); // Place a BRICK_WALL over the LEVEL_EXIT_DOOR
    }

    private void PlaceRandomPowerup(List<Vector2I> occupiedTiles)
    {
        Vector2I powerupPosition = GetRandomTilePosition(occupiedTiles);
        Powerup.PowerupType powerupType = Powerup.PowerupType.NONE;
        float random = GD.Randf();

        if (random < 0.8f)
        {
            random = GD.Randf();

            if (random < 0.25f)
            {
                powerupType = Powerup.PowerupType.BOMB_COUNT;
            }
            else if (random < 0.5f)
            {
                powerupType = Powerup.PowerupType.EXPLOSION_SIZE;
            }
            else if (random < 0.75f)
            {
                powerupType = Powerup.PowerupType.SPEED;
            }
            else
            {
                powerupType = Powerup.PowerupType.REMOTE_CONTROL;
            }
        }
        else
        {
            random = GD.Randf();

            if (random < 0.3f)
            {
                powerupType = Powerup.PowerupType.WALL_PASS;
            }
            else if (random < 0.6f)
            {
                powerupType = Powerup.PowerupType.BOMB_PASS;
            }
            else if (random < 0.9f)
            {
                powerupType = Powerup.PowerupType.FLAME_PASS;
            }
            else
            {
                powerupType = Powerup.PowerupType.INVINCIBILITY;
            }
        }

        PlacePowerUp(powerupPosition, powerupType);
    }

    private void PlacePowerUp(Vector2I powerUpPosition, Powerup.PowerupType type)
    {
        var powerup = (Powerup)PowerupScene.Instantiate();
        powerup.Position = new Vector2(powerUpPosition.X, powerUpPosition.Y) * TileSize;
        powerup.Type = type;
        _brickWallsContainer.AddChild(powerup);
        PlaceBrickWall(powerUpPosition); // Place a BRICK_WALL over the POWERUP
    }

    private void PlaceBrickWall(Vector2I brickPosition)
    {
        var brickWall = (BrickWall)BrickWallScene.Instantiate();
        brickWall.Position = new Vector2(brickPosition.X, brickPosition.Y) * TileSize;
        _brickWallsContainer.AddChild(brickWall);
    }

    private void PlaceEnemy(PackedScene enemyScene, int count, List<Vector2I> occupiedTiles)
    {
        for (int i = 0; i < count; i++)
        {
            var enemy = (Enemy)enemyScene.Instantiate();
            Vector2I enemyPosition = GetRandomTilePosition(occupiedTiles);
            enemy.Position = new Vector2(enemyPosition.X, enemyPosition.Y) * TileSize;
            enemy.CurrentPlayer = Globals.Instance.Player;
            _enemiesContainer.AddChild(enemy);
        }
    }

    private void PlaceBrickWalls(int maxBrickWalls, List<Vector2I> occupiedTiles)
    {
        for (int i = 0; i < maxBrickWalls; i++)
        {
            Vector2I brickPosition = GetRandomTilePosition(occupiedTiles);
            PlaceBrickWall(brickPosition);
        }
    }
}