using System;
using System.Collections.Generic;
using Godot;
using Godot.Collections;

public partial class CentralExplosion : Area2D
{
    private static readonly PackedScene DirectionalExplosionScene = GD.Load<PackedScene>("res://scenes/directional_explosion.tscn");

    public int ExplosionSize { get; set; } = 1;

    private static readonly string[] _middleAnimations = ["top_middle", "right_middle", "bottom_middle", "left_middle"];
    private static readonly string[] _endAnimations = ["top_end", "right_end", "bottom_end", "left_end"];
    private static readonly Vector2[] _directionVectors = [Vector2.Up, Vector2.Right, Vector2.Down, Vector2.Left];
    private Array<RayCast2D> _raycasts = [];
    private AnimatedSprite2D _explosionCenterSprite;
    private const int _flameDirectionCount = 4;
    private const int _middleAnimationFrame = 3;

    private readonly List<int> _flameSizes = [];
    private readonly List<StaticBody2D> _brickWallsToDestroy = [];
    private int[] FlameCurrentSizes { get; set; } = [0, 0, 0, 0];

    public override void _Ready()
    {
        _explosionCenterSprite = GetNode<AnimatedSprite2D>("AnimatedSprite2D");
        _explosionCenterSprite.AnimationFinished += OnAnimatedSprite2DAnimationFinished;
        _explosionCenterSprite.FrameChanged += OnAnimatedSprite2DFrameChanged;
        BodyEntered += OnBodyEntered;

        ConfigureRaycasts();

        foreach (var raycast in _raycasts)
        {
            int flameSize = ExplosionSize;

            if (raycast.IsColliding())
            {
                var collider = raycast.GetCollider();
                var collisionPoint = ToLocal(raycast.GetCollisionPoint());

                if (collisionPoint.X != 0)
                {
                    collisionPoint.X += collisionPoint.X < 0 ? 1 : -1;
                }

                if (collisionPoint.Y != 0)
                {
                    collisionPoint.Y += collisionPoint.Y < 0 ? 1 : -1;
                }

                var tileCoords = Utils.PositionToTileCenter(collisionPoint);
                int colliderDistance = (int)(Mathf.Max(Mathf.Abs(tileCoords.X), Mathf.Abs(tileCoords.Y)) / Globals.TILE_SIZE);

                flameSize = Math.Min(flameSize, colliderDistance);

                if (collider is BrickWall colliderNode && colliderNode.HasMethod("Destroy"))
                {
                    _brickWallsToDestroy.Add(colliderNode);
                }
            }

            _flameSizes.Add(flameSize);
        }
    }

    private void ConfigureRaycasts()
    {
        _raycasts = [
            GetNode<RayCast2D>("Raycasts/Top"),
            GetNode<RayCast2D>("Raycasts/Right"),
            GetNode<RayCast2D>("Raycasts/Bottom"),
            GetNode<RayCast2D>("Raycasts/Left")
        ];

        for (int i = 0; i < _flameDirectionCount; i++)
        {
            _raycasts[i].TargetPosition = _directionVectors[i] * ExplosionSize * Globals.TILE_SIZE;
            _raycasts[i].ForceRaycastUpdate();
        }
    }

    private void OnAnimatedSprite2DAnimationFinished()
    {
        QueueFree();
    }

    private void OnAnimatedSprite2DFrameChanged()
    {
        UpdateExplosionForFrame();
    }

    private void UpdateExplosionForFrame()
    {
        int frame = _explosionCenterSprite.Frame;

        for (int i = 0; i < _flameDirectionCount; i++)
        {
            if (frame <= _middleAnimationFrame && _flameSizes[i] > FlameCurrentSizes[i])
            {
                var flameSegment = (DirectionalExplosion)DirectionalExplosionScene.Instantiate();
                flameSegment.Position = Position + _directionVectors[i] * Globals.TILE_SIZE * frame;
                GetParent().AddChild(flameSegment);

                if (_flameSizes[i] == FlameCurrentSizes[i] + 1 && _flameSizes[i] == ExplosionSize)
                {
                    flameSegment.PlayAnimation(_endAnimations[i]);
                }
                else
                {
                    flameSegment.PlayAnimation(_middleAnimations[i]);
                }

                FlameCurrentSizes[i] += 1;
            }
            else if (_flameSizes[i] > FlameCurrentSizes[i])
            {
                for (int j = 0; j < _flameSizes[i] - FlameCurrentSizes[i]; j++)
                {
                    var flameSegment = (DirectionalExplosion)DirectionalExplosionScene.Instantiate();
                    flameSegment.Position = Position + _directionVectors[i] * Globals.TILE_SIZE * (frame + j);
                    GetParent().AddChild(flameSegment);

                    if (_flameSizes[i] - FlameCurrentSizes[i] == 1 && _flameSizes[i] == ExplosionSize)
                    {
                        flameSegment.PlayAnimation(_endAnimations[i]);
                    }
                    else
                    {
                        flameSegment.PlayAnimation(_middleAnimations[i]);
                    }

                    FlameCurrentSizes[i] += 1;
                }
            }
        }

        if (frame == _middleAnimationFrame)
        {
            foreach (var brickWall in _brickWallsToDestroy)
            {
                brickWall.Call("Destroy");
            }
        }
    }

    private void OnBodyEntered(Node2D body)
    {
        if (body.HasMethod("Destroy"))
        {
            body.Call("Destroy", this);
        }
    }
}