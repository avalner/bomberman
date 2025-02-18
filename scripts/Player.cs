using Godot;
using System;

public partial class Player : CharacterBody2D
{
    [Export] public Node BombsContainer { get; set; }
    [Export] public Node ExplosionsContainer { get; set; }

    public AnimatedSprite2D PlayerAnimations { get; private set; }
    public Area2D Area2D { get; private set; }

    private BombPlacementSystem _bombPlacementSystem;
    private CollisionShape2D _collisionShape2D;

    public enum PlayerState
    {
        IDLE,
        MOVING_UP,
        MOVING_DOWN,
        MOVING_LEFT,
        MOVING_RIGHT,
        DYING,
        DEAD,
        REMOVED
    }

    [Signal] public delegate void StateChangedEventHandler(PlayerState state, PlayerState oldState);
    [Signal] public delegate void PowerupTakenEventHandler(Powerup.PowerupType type);

    public PlayerState State { get; private set; } = PlayerState.IDLE;

    public override void _Ready()
    {
        Area2D = GetNode<Area2D>("Area2D");
        PlayerAnimations = GetNode<AnimatedSprite2D>("PlayerAnimations");
        _collisionShape2D = GetNode<CollisionShape2D>("CollisionShape");
        _bombPlacementSystem = GetNode<BombPlacementSystem>("BombPlacementSystem");
        MotionMode = MotionModeEnum.Floating;
        var physicsMaterial = new PhysicsMaterial
        {
            Friction = 0.0f,
            Bounce = 0.0f
        };
        _collisionShape2D.Shape.Set("physics_material_override", physicsMaterial);

        _bombPlacementSystem.Player = this;
        _bombPlacementSystem.BombsContainer = BombsContainer;
        _bombPlacementSystem.ExplosionsContainer = ExplosionsContainer;

        if (Globals.Instance.WallPass)
        {
            CollisionMask &= ~(uint)Utils.COLLISION_MASK.BRICK_WALLS;
        }

        if (Globals.Instance.BombPass)
        {
            CollisionMask &= ~(uint)Utils.COLLISION_MASK.BOMB;
        }

        Globals.Instance.WallPassChanged += OnWallPassChanged;
        Globals.Instance.BombPassChanged += OnBombPassChanged;
    }

    public override void _ExitTree()
    {
        Globals.Instance.WallPassChanged -= OnWallPassChanged;
        Globals.Instance.BombPassChanged -= OnBombPassChanged;
        base._ExitTree();
    }

    public void ChangeState(PlayerState newState)
    {
        if (State != newState)
        {
            var oldState = State;
            State = newState;
            EmitSignal(SignalName.StateChanged, (int)State, (int)oldState);
        }
    }

    public override void _Input(InputEvent @event)
    {
        if (@event is not InputEventKey || State == PlayerState.DYING || State == PlayerState.DEAD)
        {
            return;
        }

        if (Input.IsActionPressed("right"))
        {
            ChangeState(PlayerState.MOVING_RIGHT);
        }
        else if (Input.IsActionPressed("left"))
        {
            ChangeState(PlayerState.MOVING_LEFT);
        }
        else if (Input.IsActionPressed("down"))
        {
            ChangeState(PlayerState.MOVING_DOWN);
        }
        else if (Input.IsActionPressed("up"))
        {
            ChangeState(PlayerState.MOVING_UP);
        }
        else
        {
            ChangeState(PlayerState.IDLE);
        }

        if (@event.IsActionPressed("place_bomb"))
        {
            _bombPlacementSystem.PlaceBomb();
        }
        else if (@event.IsActionPressed("detonate_bombs") && !Globals.Instance.AutoDetonate)
        {
            _ = _bombPlacementSystem.DetonateBombs();
        }
    }

    public override void _PhysicsProcess(double delta)
    {
        switch (State)
        {
            case PlayerState.MOVING_RIGHT:
                Velocity = Vector2.Right * Globals.Instance.Speed;
                break;
            case PlayerState.MOVING_LEFT:
                Velocity = Vector2.Left * Globals.Instance.Speed;
                break;
            case PlayerState.MOVING_DOWN:
                Velocity = Vector2.Down * Globals.Instance.Speed;
                break;
            case PlayerState.MOVING_UP:
                Velocity = Vector2.Up * Globals.Instance.Speed;
                break;
            default:
                Velocity = Vector2.Zero;
                break;
        }

        MoveAndSlide();
    }

    public void ApplyPowerup(Powerup.PowerupType powerup)
    {
        EmitSignal(SignalName.PowerupTaken, (int)powerup);
    }

    public void Remove()
    {
        ChangeState(PlayerState.REMOVED);
        QueueFree();
    }

    public void Destroy(Node source)
    {
        if (State == PlayerState.DEAD)
        {
            return;
        }

        if ((source is CentralExplosion || source is DirectionalExplosion || source is BrickWall) && Globals.Instance.ImmuneToExplosions)
        {
            return;
        }

        if (source is Enemy && Globals.Instance.Invincible)
        {
            return;
        }

        ChangeState(PlayerState.DYING);
    }

    private void OnWallPassChanged(bool wallPass)
    {
        if (wallPass)
        {
            CollisionMask &= ~(uint)Utils.COLLISION_MASK.BRICK_WALLS;
        }
        else
        {
            CollisionMask |= (uint)Utils.COLLISION_MASK.BRICK_WALLS;
        }
    }

    private void OnBombPassChanged(bool bombPass)
    {
        if (bombPass)
        {
            CollisionMask &= ~(uint)Utils.COLLISION_MASK.BOMB;
        }
        else
        {
            CollisionMask |= (uint)Utils.COLLISION_MASK.BOMB;
        }
    }

    private void OnPlayerAnimationsAnimationFinished()
    {
        if (State == PlayerState.DYING)
        {
            QueueFree();
            ChangeState(PlayerState.DEAD);
        }
    }
}