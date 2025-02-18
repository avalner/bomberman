using Godot;
using System;

public partial class Bomb : StaticBody2D
{
    private static readonly PackedScene ExplosionScene = GD.Load<PackedScene>("res://scenes/central_explosion.tscn");
    public int ExplosionSize = 1;
    public bool AutoDetonate = true;
    public Node ExplosionsContainer;

    private CollisionShape2D _collisionShape2D;
    private Area2D _area2D;
    private Godot.Timer _timer;
    private Node _player;

    private static int _unexitedBombs = 0;

    public override void _Ready()
    {
        _collisionShape2D = GetNode<CollisionShape2D>("CollisionShape2D");
        _area2D = GetNode<Area2D>("Area2D");
        _timer = GetNode<Godot.Timer>("Timer");

        _unexitedBombs += 1;
        Globals.Instance.SetAstarPointDisabled(Position);
        SoundsPlayer.PlaySound("place_bomb");

        if (AutoDetonate)
        {
            _timer.Start();
        }
    }

    private void OnTimerTimeout()
    {
        Detonate();
    }

    private void OnArea2DBodyExited(Node2D body)
    {
        // Enable bomb collision mask when player leaves the bomb area
        if (body is Player player)
        {
            if (_unexitedBombs > 0)
            {
                _unexitedBombs -= 1;
            }

            if (_unexitedBombs == 0 && !Globals.Instance.BombPass)
            {
                player.CollisionMask |= (uint)Utils.COLLISION_MASK.BOMB;
            }
        }
    }

    public void Detonate()
    {
        Globals.Instance.SetAstarPointEnabled(Position);
        SoundsPlayer.PlaySound("explosion");
        var explosion = (CentralExplosion)ExplosionScene.Instantiate();
        explosion.ExplosionSize = ExplosionSize;
        explosion.Position = Position;
        ExplosionsContainer.AddChild(explosion);
        QueueFree();
    }

    public void Destroy(Node source)
    {
        Detonate();
    }
}