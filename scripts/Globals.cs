using Godot;
using System;
using System.Collections.Generic;

public partial class Globals : Node2D
{
    public const int INITIAL_LIVES = 3;
    public const int INITIAL_SPEED = 50;
    public const int SPEED_INCREMENT = 10;
    public const int MAX_SPEED = 100;
    public const int LEVEL_TIME = 300;
    public const int TILE_SIZE = 16;
    public const int LEVEL_WIDTH = 29;
    public const int LEVEL_HEIGHT = 11;
    public const float AUTO_DETONATE_DELAY = 0.2f;

    public const int POWERUP_POINTS = 1000;
    public static readonly Dictionary<Enemy.EnemyType, int> ENEMY_POINTS = new Dictionary<Enemy.EnemyType, int>
    {
        { Enemy.EnemyType.VALCOM, 100 },
        { Enemy.EnemyType.ONEAL, 200 }
    };

    public enum GameState
    {
        INITIAL,
        LEVEL_START,
        PLAYING,
        PAUSED,
        LEVEL_COMPLETE,
        LEVEL_LOST,
        GAME_OVER
    }

    [Signal] public delegate void LevelTimeChangedEventHandler(int remainingTime);
    [Signal] public delegate void PlayerLivesChangedEventHandler(int lives);
    [Signal] public delegate void ScoreChangedEventHandler(int score);
    [Signal] public delegate void PlayerSpeedChangedEventHandler(float speed);
    [Signal] public delegate void MaxBombCountChangedEventHandler(int count);
    [Signal] public delegate void ExplosionSizeChangedEventHandler(int size);
    [Signal] public delegate void AutoDetonateChangedEventHandler(bool autoDetonate);
    [Signal] public delegate void PickedPowerupChangedEventHandler(Powerup.PowerupType powerup);
    [Signal] public delegate void EnemyKilledEventHandler(Enemy.EnemyType enemyType);
    [Signal] public delegate void WallPassChangedEventHandler(bool wallPass);
    [Signal] public delegate void ImmuneToExplosionsChangedEventHandler(bool immuneToExplosions);
    [Signal] public delegate void BombPassChangedEventHandler(bool bombPass);
    [Signal] public delegate void InvincibleChangedEventHandler(bool invincible);
    [Signal] public delegate void GameStateChangedEventHandler(GameState newState, GameState oldState);

    public MainScene MainScene;
    public Player Player;
    public TileMapLayer TileMapLayer;
    public Hud Hud;
    public Node EnemiesContainer;
    public Timer GameTimer;
    public GameState CurrentGameState = GameState.INITIAL;
    public int Stage = 1;

    private int _remainingTime = LEVEL_TIME;
    public int RemainingTime
    {
        get => _remainingTime;
        set
        {
            if (value == _remainingTime) return;
            _remainingTime = value;
            EmitSignal(SignalName.LevelTimeChanged, _remainingTime);
        }
    }

    private int _lives = INITIAL_LIVES;
    public int Lives
    {
        get => _lives;
        set
        {
            if (value == _lives) return;
            _lives = value;
            EmitSignal(SignalName.PlayerLivesChanged, _lives);
        }
    }

    private int _score = 0;
    public int Score
    {
        get => _score;
        set
        {
            if (value == _score) return;
            _score = value;
            EmitSignal(SignalName.ScoreChanged, _score);
        }
    }

    private float _speed = INITIAL_SPEED;
    public float Speed
    {
        get => _speed;
        set
        {
            if (value > MAX_SPEED) value = MAX_SPEED;
            if (value == _speed) return;
            _speed = value;
            EmitSignal(SignalName.PlayerSpeedChanged, _speed);
        }
    }

    private int _maxBombCount = 1;
    public int MaxBombCount
    {
        get => _maxBombCount;
        set
        {
            if (value == _maxBombCount) return;
            _maxBombCount = value;
            EmitSignal(SignalName.MaxBombCountChanged, _maxBombCount);
        }
    }

    private int _explosionSize = 3;
    public int ExplosionSize
    {
        get => _explosionSize;
        set
        {
            if (value == _explosionSize) return;
            _explosionSize = value;
            EmitSignal(SignalName.ExplosionSizeChanged, _explosionSize);
        }
    }

    private bool _autoDetonate = true;
    public bool AutoDetonate
    {
        get => _autoDetonate;
        set
        {
            if (value == _autoDetonate) return;
            _autoDetonate = value;
            EmitSignal(SignalName.AutoDetonateChanged, _autoDetonate);
        }
    }

    private bool _wallPass = false;
    public bool WallPass
    {
        get => _wallPass;
        set
        {
            if (value == _wallPass) return;
            _wallPass = value;
            EmitSignal(SignalName.WallPassChanged, _wallPass);
        }
    }

    private bool _immuneToExplosions = false;
    public bool ImmuneToExplosions
    {
        get => _immuneToExplosions;
        set
        {
            if (value == _immuneToExplosions) return;
            _immuneToExplosions = value;
            EmitSignal(SignalName.ImmuneToExplosionsChanged, _immuneToExplosions);
        }
    }

    private bool _bombPass = false;
    public bool BombPass
    {
        get => _bombPass;
        set
        {
            if (value == _bombPass) return;
            _bombPass = value;
            EmitSignal(SignalName.BombPassChanged, _bombPass);
        }
    }

    private bool _invincible = false;
    public bool Invincible
    {
        get => _invincible;
        set
        {
            if (value == _invincible) return;
            _invincible = value;
            EmitSignal(SignalName.InvincibleChanged, _invincible);
        }
    }

    private Powerup.PowerupType _pickedPowerup = Powerup.PowerupType.NONE;
    public Powerup.PowerupType PickedPowerup
    {
        get => _pickedPowerup;
        set
        {
            if (value == _pickedPowerup) return;
            _pickedPowerup = value;
            EmitSignal(SignalName.PickedPowerupChanged, (int)_pickedPowerup);
        }
    }

    public int EnemyCount
    {
        get
        {
            int count = 0;
            foreach (Node child in EnemiesContainer.GetChildren())
            {
                if (child is Enemy enemy && enemy.CurrentState != Enemy.State.DEAD)
                {
                    count++;
                }
            }
            return count;
        }
    }

    public static Globals Instance
    {
        get
        {
            return Utils.RootNode.GetNode<Globals>("/root/Globals");
        }
    }

    public void ChangeGameState(GameState state)
    {
        if (state == CurrentGameState) return;

        GameState oldState = CurrentGameState;
        CurrentGameState = state;
        EmitSignal(SignalName.GameStateChanged, (int)state, (int)oldState);
    }

    public override void _Ready()
    {
        MainScene = (MainScene)GetTree().CurrentScene;
        ProcessMode = ProcessModeEnum.Always;
        GameStateChanged += OnGameStateChanged;
        EnemyKilled += OnEnemyKilled;
    }

    public override void _Input(InputEvent @event)
    {
        if (@event.IsActionPressed("pause"))
        {
            if (CurrentGameState == GameState.PLAYING)
            {
                ChangeGameState(GameState.PAUSED);
            }
            else if (CurrentGameState == GameState.PAUSED)
            {
                ChangeGameState(GameState.PLAYING);
            }
        }
    }

    public void Init()
    {
        MainScene = (MainScene)GetTree().CurrentScene;
        TileMapLayer = GetTree().CurrentScene.GetNode<TileMapLayer>("TileMapLayer");
        Player = GetTree().CurrentScene.GetNode<Player>("Root/Player");
        Hud = GetTree().CurrentScene.GetNode<Hud>("Hud");
        EnemiesContainer = GetTree().CurrentScene.GetNode("Root/Enemies");
        GameTimer = (Godot.Timer)GetTree().CurrentScene.GetNode("Root/GameTimer");

        Player.StateChanged += OnPlayerStateChanged;
        Player.PowerupTaken += OnPowerupTaken;
        GameTimer.Timeout += OnGameTimerTimeout;

        RemainingTime = LEVEL_TIME;

        if (Lives == 0)
        {
            Lives = INITIAL_LIVES;
        }
    }

    public void ResetGameState()
    {
        Stage = 1;
        Score = 0;
        Lives = INITIAL_LIVES;
        Speed = INITIAL_SPEED;
        MaxBombCount = 1;
        ExplosionSize = 1;
        AutoDetonate = true;
        WallPass = false;
        ImmuneToExplosions = false;
        BombPass = false;
        Invincible = false;
        PickedPowerup = Powerup.PowerupType.NONE;
    }

    private void OnGameTimerTimeout()
    {
        RemainingTime -= 1;

        if (RemainingTime == 0)
        {
            GameTimer.Stop();
            Player.Destroy(this);
        }
    }

    public void CompleteLevel()
    {
        ChangeGameState(GameState.LEVEL_COMPLETE);
    }

    private async void OnGameStateChanged(GameState newState, GameState oldState)
    {
        switch (newState)
        {
            case GameState.LEVEL_START:
                Init();
                MainScene.LevelStart.GetNode<Label>("StageLabel").Text = $"STAGE {Stage}";
                MainScene.LevelStart.Show();
                SoundsPlayer.PlaySound("level_start");
                await ToSignal(GetTree().CreateTimer(3), "timeout");
                MainScene.LevelStart.Hide();
                ChangeGameState(GameState.PLAYING);
                break;
            case GameState.PLAYING:
                GetTree().Paused = false;
                GameTimer.Start();
                if (!SoundsPlayer.IsPlaying("main_theme"))
                {
                    SoundsPlayer.PlaySound("main_theme");
                }
                break;
            case GameState.PAUSED:
                GetTree().Paused = true;
                break;
            case GameState.LEVEL_COMPLETE:
                Lives += 1;
                Stage += 1;
                Player.Remove();
                SoundsPlayer.PlaySound("level_finished");
                await ToSignal(GetTree().CreateTimer(3), "timeout");
                GetTree().ReloadCurrentScene();
                break;
            case GameState.LEVEL_LOST:
                if (Lives > 0)
                {
                    await ToSignal(GetTree().CreateTimer(4), "timeout");
                    RestartScene();
                }
                else
                {
                    ChangeGameState(GameState.GAME_OVER);
                }
                break;
            case GameState.GAME_OVER:
                await ToSignal(GetTree().CreateTimer(3), "timeout");
                MainScene.GameOver.Show();
                SoundsPlayer.PlaySound("game_over");
                await ToSignal(GetTree().CreateTimer(8), "timeout");
                ResetGameState();
                RestartScene();
                break;
        }
    }

    private void OnEnemyKilled(Enemy.EnemyType enemyType)
    {
        Score += ENEMY_POINTS[enemyType];

        if (AllEnemiesDead())
        {
            SoundsPlayer.PlaySound("all_killed");
        }
    }

    private bool AllEnemiesDead()
    {
        foreach (Node child in EnemiesContainer.GetChildren())
        {
            if (child is Enemy enemy && enemy.CurrentState != Enemy.State.DEAD)
            {
                return false;
            }
        }
        return true;
    }

    private void OnPowerupTaken(Powerup.PowerupType powerupType)
    {
        Score += POWERUP_POINTS;
        SoundsPlayer.PlaySound("powerup_theme");

        switch (powerupType)
        {
            case Powerup.PowerupType.SPEED:
                Speed += SPEED_INCREMENT;
                break;
            case Powerup.PowerupType.BOMB_COUNT:
                MaxBombCount += 1;
                break;
            case Powerup.PowerupType.EXPLOSION_SIZE:
                ExplosionSize += 1;
                break;
            case Powerup.PowerupType.REMOTE_CONTROL:
                AutoDetonate = false;
                break;
            case Powerup.PowerupType.WALL_PASS:
                WallPass = true;
                break;
            case Powerup.PowerupType.FLAME_PASS:
                ImmuneToExplosions = true;
                break;
            case Powerup.PowerupType.BOMB_PASS:
                BombPass = true;
                break;
            case Powerup.PowerupType.INVINCIBILITY:
                Invincible = true;
                break;
        }

        PickedPowerup = powerupType;
    }

    private void OnPlayerStateChanged(Player.PlayerState newState, Player.PlayerState oldState)
    {
        switch (newState)
        {
            case Player.PlayerState.DYING:
                GameTimer.Stop();
                SoundsPlayer.StopSound("main_theme");
                Lives -= 1;
                break;
            case Player.PlayerState.DEAD:
                SoundsPlayer.PlaySound("lost_life");
                ChangeGameState(GameState.LEVEL_LOST);
                break;
        }
    }

    private void RestartScene()
    {
        GetTree().ReloadCurrentScene();
    }

    public void SetAstarPointEnabled(Vector2 point)
    {
        MainScene.AstarGrid.SetPointSolid(Utils.PositionToCellPosition(point), false);
    }

    public void SetAstarPointDisabled(Vector2 point)
    {
        MainScene.AstarGrid.SetPointSolid(Utils.PositionToCellPosition(point), true);
    }
}