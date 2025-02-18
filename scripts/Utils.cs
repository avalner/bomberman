using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using Godot;

public static class Utils
{
    [Flags]
    public enum COLLISION_MASK : uint
    {
        PLAYER = 1,
        CONCRETE_WALLS = 1 << 1,
        BRICK_WALLS = 1 << 2,
        ENEMY = 1 << 3,
        BOMB = 1 << 4,
        POWERUP = 1 << 5,
        EXIT_DOOR = 1 << 6
    }

    public static Node RootNode
    {
        get
        {
            return (Engine.GetMainLoop() as SceneTree)?.Root;
        }
    }

    public static async Task WaitForPhysicsFrames(int frames, Node node)
    {
        for (int i = 0; i < frames; i++)
        {
            await node.ToSignal(Engine.GetMainLoop(), "physics_frame");
        }
    }

    public static bool HasPlayerAtPosition(Vector2 position)
    {
        var nodes = GetNodesAtPosition(position);
        foreach (var node in nodes)
        {
            if (node is Player)
            {
                return true;
            }
        }
        return false;
    }

    public static bool HasBombAtPosition(Vector2 position)
    {
        var nodes = GetNodesAtPosition(position);
        foreach (var node in nodes)
        {
            if (node is Bomb)
            {
                return true;
            }
        }
        return false;
    }

    public static bool HasBrickWallAtPosition(Vector2 position)
    {
        var nodes = GetNodesAtPosition(position);
        foreach (var node in nodes)
        {
            if (node is BrickWall)
            {
                return true;
            }
        }
        return false;
    }

    public static bool HasWallAtPosition(Vector2 position)
    {
        var nodes = GetNodesAtPosition(position);

        foreach (var node in nodes)
        {
            if (node is BrickWall)
            {
                return true;
            }
        }

        // Check for non-passable tiles in the TileMapLayerWWWW
        var tileMapLayer = Globals.Instance.TileMapLayer;
        var cellPosition = tileMapLayer.LocalToMap(position);
        var tileData = tileMapLayer.GetCellTileData(cellPosition);

        return tileData != null && !(bool)tileData.GetCustomData("passable");
    }

    public static List<Node2D> GetNodesAtPosition(Vector2 position)
    {
        var spaceState = Globals.Instance.GetWorld2D().DirectSpaceState;
        var queryParams = new PhysicsPointQueryParameters2D
        {
            Position = position,
            CollideWithAreas = true, // Include Area2Ds
            CollideWithBodies = true, // Include RigidBody2D, StaticBody2D, etc.
            CollisionMask = (uint)(COLLISION_MASK.BRICK_WALLS | COLLISION_MASK.PLAYER | COLLISION_MASK.ENEMY | COLLISION_MASK.BOMB | COLLISION_MASK.POWERUP | COLLISION_MASK.EXIT_DOOR)
        };

        var results = spaceState.IntersectPoint(queryParams);
        var nodes = new List<Node2D>();

        foreach (var result in results)
        {
            if (result["collider"].As<Node>() is Node2D node)
            {
                nodes.Add(node);
            }
        }

        return nodes;
    }

    public static bool IsTileCenter(Vector2 position)
    {
        return (new Vector2I((int)Math.Round(position.X), (int)Math.Round(position.Y)) % Globals.TILE_SIZE) == Vector2I.Zero;
    }

    public static Vector2I PositionToCellPosition(Vector2 position)
    {
        return (Vector2I)(position / Globals.TILE_SIZE).Round();
    }

    public static Vector2 CellPositionToPosition(Vector2I cellPosition)
    {
        return cellPosition * Globals.TILE_SIZE;
    }

    public static Vector2 PositionToTileCenter(Vector2 position)
    {
        return (position / Globals.TILE_SIZE).Round() * Globals.TILE_SIZE;
    }
}