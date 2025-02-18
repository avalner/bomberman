using Godot;

public partial class LevelExitDoor : Area2D
{
    private bool _isPlayerInside = false;
    private Player _player;

    private bool IsCentered(Node2D body)
    {
        // Get the global positions of the Area2D and the player
        Vector2 areaPosition = GlobalPosition;
        Vector2 playerPosition = body.GlobalPosition;

        // Calculate the distance between the centers
        float distance = playerPosition.DistanceTo(areaPosition);

        // Check if the centers are approximately aligned
        return distance < 1.0f; // Tweak this value to adjust the alignment threshold
    }

    private void OnBodyEntered(Node2D body)
    {
        if (body is Player player)
        {
            _player = player;
            _isPlayerInside = true;
        }
    }

    private void OnBodyExited(Node2D body)
    {
        if (body is Player)
        {
            _isPlayerInside = false;
        }
    }

    public override void _Process(double delta)
    {
        if (!_isPlayerInside || !IsCentered(_player) || Utils.HasBrickWallAtPosition(GlobalPosition)) return;
        if (Globals.Instance.EnemyCount == 0)
        {
            Globals.Instance.CompleteLevel();
        }
    }

    public override void _Ready()
    {
        BodyEntered += OnBodyEntered;
        BodyExited += OnBodyExited;
    }
}