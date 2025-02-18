using Godot;
using System;

public partial class Powerup : Area2D
{
    public enum PowerupType
    {
        NONE,
        BOMB_COUNT,
        EXPLOSION_SIZE,
        SPEED,
        REMOTE_CONTROL,
        WALL_PASS,
        BOMB_PASS,
        FLAME_PASS,
        INVINCIBILITY
    }

    public PowerupType Type = PowerupType.BOMB_COUNT;

    private Sprite2D _bombSprite;
    private Sprite2D _fireSprite;
    private Sprite2D _speedSprite;
    private Sprite2D _remoteControlSprite;
    private Sprite2D _wallPassSprite;
    private Sprite2D _bombPassSprite;
    private Sprite2D _flamePassSprite;
    private Sprite2D _invincibilitySprite;

    private Sprite2D[] sprites;
    private float fadeSpeed = 1.5f; // Speed of the fade effect
    private bool increasing = true; // Tracks whether the alpha is increasing or decreasing

    public override void _Ready()
    {
        _bombSprite = GetNode<Sprite2D>("BombSprite");
        _fireSprite = GetNode<Sprite2D>("FireSprite");
        _speedSprite = GetNode<Sprite2D>("SpeedSprite");
        _remoteControlSprite = GetNode<Sprite2D>("RemoteControlSprite");
        _wallPassSprite = GetNode<Sprite2D>("WallPassSprite");
        _bombPassSprite = GetNode<Sprite2D>("BombPassSprite");
        _flamePassSprite = GetNode<Sprite2D>("FlamePassSprite");
        _invincibilitySprite = GetNode<Sprite2D>("InvincibilitySprite");

        sprites =
        [
            _bombSprite,
            _fireSprite,
            _speedSprite,
            _remoteControlSprite,
            _wallPassSprite,
            _bombPassSprite,
            _flamePassSprite,
            _invincibilitySprite
        ];

        foreach (var sprite in sprites)
        {
            sprite.Hide();
        }

        sprites[(int)Type - 1].Show();
    }

    public override void _Process(double delta)
    {
        Animate((float)delta);
    }

    private void Animate(float delta)
    {
        if (increasing)
        {
            Modulate = new Color(Modulate, Modulate.A + fadeSpeed * delta); // Fade in
            if (Modulate.A >= 1.0f) // Clamp alpha
            {
                Modulate = new Color(Modulate, 1.0f);
                increasing = false;
            }
        }
        else
        {
            Modulate = new Color(Modulate, Modulate.A - fadeSpeed * delta); // Fade out
            if (Modulate.A <= 0.2f) // Clamp alpha
            {
                Modulate = new Color(Modulate, 0.2f);
                increasing = true;
            }
        }
    }

    private void OnBodyEntered(Node2D body)
    {
        if (body.HasMethod("ApplyPowerup") && !Utils.HasBrickWallAtPosition(GlobalPosition))
        {
            SoundsPlayer.PlaySound("powerup");
            body.Call("ApplyPowerup", (int)Type);
            QueueFree();
        }
    }

    public void Destroy(Node source)
    {
        QueueFree();
    }
}