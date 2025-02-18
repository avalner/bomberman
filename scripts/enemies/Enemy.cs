using System.Collections.Generic;
using System.Threading.Tasks;
using Godot;
using Godot.Collections;

public partial class Enemy : CharacterBody2D
{
    public enum EnemyType { VALCOM, ONEAL }
    public enum State { MOVING, THINKING, MOVING_TO_PLAYER, DEAD }

    public static readonly Vector2[] DIRECTION_VECTORS = [Vector2.Up, Vector2.Right, Vector2.Down, Vector2.Left];
    public const int TILE_SIZE = Globals.TILE_SIZE;
    public const int DIRECTION_COUNT = 4;
    public const double MIN_TIME_TO_THINK = 0.5f;
    public const double MAX_TIME_TO_THINK = 1.0f;
    public const int DEFAULT_SPEED = 30;
    public const double THINKING_CHANCE = 0.01f;

    public Player CurrentPlayer;
    public EnemyType Type { get; protected set; }

    [Signal] public delegate void StateChangedEventHandler(State state, State oldState);

    [Export] public int Speed = DEFAULT_SPEED;

    protected Area2D _area2D;
    protected AnimatedSprite2D _animatedSprite;
    protected State _state = State.MOVING;
    protected Vector2 _direction = Vector2.Zero;
    private AStarGrid2D _astar;
    private readonly List<RayCast2D> _raycasts = [];
    private bool _raycastsReady = false;
    private Timer _thinkingTimer = new();
    private double _timeToThink = 0;
    private double _totalThinkingTime = 0;
    private Array<Vector2I> _path = new Array<Vector2I>();
    private int _pathIndex = 0;

    public State CurrentState => _state;

    public override void _Ready()
    {
        _area2D = GetNode<Area2D>("Area2D");
        _animatedSprite = GetNode<AnimatedSprite2D>("AnimatedSprite2D");
        _astar = Globals.Instance.MainScene.AstarGrid;
        StateChanged += OnStateChanged;
        _animatedSprite.AnimationFinished += OnAnimatedSpriteAnimationFinished;
        _area2D.BodyEntered += OnArea2DBodyEntered;
        _thinkingTimer.Autostart = false;
        _thinkingTimer.OneShot = false;
        _thinkingTimer.Timeout += OnThinkingTimerTimeout;
        AddChild(_thinkingTimer);
        _ = CreateRaycasts();
    }

    public void ChangeState(State newState)
    {
        if (_state == newState)
            return;

        var oldState = _state;
        _state = newState;
        EmitSignal(SignalName.StateChanged, (int)_state, (int)oldState);
    }

    private async Task CreateRaycasts()
    {
        for (int i = 0; i < DIRECTION_COUNT; i++)
        {
            var raycast = new RayCast2D
            {
                Position = DIRECTION_VECTORS[i] * 4,
                TargetPosition = DIRECTION_VECTORS[i] * 6,
                CollideWithAreas = true,
                CollideWithBodies = true,
                CollisionMask = 0b10110
            };
            _raycasts.Add(raycast);
            AddChild(raycast);
        }

        // Await for physical frame
        await Utils.WaitForPhysicsFrames(10, this).ContinueWith(_ => _raycastsReady = true);
    }

    public override void _Process(double delta)
    {
        AdjustSpriteDirection();
    }

    private void AdjustSpriteDirection()
    {
        if (_direction == Vector2.Left)
        {
            _animatedSprite.FlipH = true;
        }
        else if (_direction == Vector2.Right)
        {
            _animatedSprite.FlipH = false;
        }
    }

    public override void _PhysicsProcess(double delta)
    {
        if (!_raycastsReady || _state == State.DEAD || Globals.Instance.CurrentGameState == Globals.GameState.LEVEL_START)
        {
            Velocity = Vector2.Zero;
            return;
        }

        if (_state == State.MOVING_TO_PLAYER)
        {
            MoveToPlayer();
        }
        else
        {
            if (Utils.IsTileCenter(Position) || Velocity == Vector2.Zero)
            {
                StopAndThink();
                TileCenterProcess(GetAvailableDirections());
            }
        }

        MoveAndSlide();
    }

    private void MoveToPlayer()
    {
        if (_pathIndex >= _path.Count)
        {
            Velocity = Vector2.Zero;
            ChangeState(State.MOVING);
            return;
        }

        var targetPos = Utils.CellPositionToPosition(_path[_pathIndex]);

        if (Position.DistanceTo(targetPos) < 1)
        {
            if (_pathIndex + 1 < _path.Count)
            {
                var nextPos = Utils.CellPositionToPosition(_path[_pathIndex + 1]);
                if (Utils.HasBombAtPosition(nextPos + GetParent<Node2D>().GlobalPosition))
                {
                    Velocity = Vector2.Zero;
                    ChangeState(State.MOVING);
                    return;
                }
            }
            _pathIndex += 1;
        }
        else
        {
            _direction = (targetPos - Position).Normalized();
            Velocity = _direction * Speed;
        }
    }

    protected virtual void TileCenterProcess(List<Vector2> availableDirections)
    {
        GD.PushError("Method 'TileCenterProcess' must be implemented in derived classes.");
    }

    private void StopAndThink()
    {
        if (GD.Randf() < THINKING_CHANCE)
        {
            ChangeState(State.THINKING);
        }
    }

    private void SetRandomThinkingAnimationTime()
    {
        _thinkingTimer.WaitTime = GD.RandRange(0.1, 1.2); // Set random interval (1 to 5 seconds)
    }

    private List<Vector2> GetAvailableDirections()
    {
        var availableDirections = new List<Vector2>();

        for (int i = 0; i < DIRECTION_COUNT; i++)
        {
            if (!_raycasts[i].IsColliding())
            {
                availableDirections.Add(DIRECTION_VECTORS[i]);
            }
        }

        return availableDirections;
    }

    public void Destroy(Node source)
    {
        ChangeState(State.DEAD);
    }

    private void OnStateChanged(State newState, State oldState)
    {
        switch (newState)
        {
            case State.DEAD:
                _animatedSprite.Play("death");
                Velocity = Vector2.Zero;
                CollisionLayer = 0;
                CollisionMask = 0;
                _area2D.CollisionLayer = 0;
                _area2D.CollisionMask = 0;
                _thinkingTimer.Stop();
                Globals.Instance.EmitSignal(Globals.SignalName.EnemyKilled, (int)Type);
                break;
            case State.MOVING:
                _animatedSprite.Play("default");
                break;
            case State.THINKING:
                Velocity = Vector2.Zero;
                _animatedSprite.Play("thinking");
                _timeToThink = (float)GD.RandRange(MIN_TIME_TO_THINK, MAX_TIME_TO_THINK);
                SetRandomThinkingAnimationTime();
                _thinkingTimer.Start();
                break;
            case State.MOVING_TO_PLAYER:
                _animatedSprite.Play("default");
                CalculatePathToPlayer();
                break;
        }
    }

    private void CalculatePathToPlayer()
    {
        if (!IsInstanceValid(CurrentPlayer) || CurrentPlayer.State == Player.PlayerState.DYING || CurrentPlayer.State == Player.PlayerState.DEAD)
        {
            ChangeState(State.MOVING);
            return;
        }

        var fromPosition = Utils.PositionToCellPosition(Position);
        var toPosition = Utils.PositionToCellPosition(CurrentPlayer.Position);

        _path = _astar.GetIdPath(fromPosition, toPosition);
        _pathIndex = 0;
    }

    private void OnArea2DBodyEntered(Node2D body)
    {
        if (body is Player player)
        {
            player.Destroy(this);
        }
    }

    private void OnAnimatedSpriteAnimationFinished()
    {
        if (_animatedSprite.Animation == "death")
        {
            QueueFree();
        }
    }

    private void OnThinkingTimerTimeout()
    {
        _totalThinkingTime += _thinkingTimer.WaitTime;

        if (_totalThinkingTime >= _timeToThink)
        {
            ChangeState(State.MOVING_TO_PLAYER);
            _totalThinkingTime = 0;
            _thinkingTimer.Stop();
        }
        else
        {
            _animatedSprite.FlipH = !_animatedSprite.FlipH;
            SetRandomThinkingAnimationTime();
        }
    }
}