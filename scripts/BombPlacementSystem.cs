using Godot;
using System.Threading.Tasks;

public partial class BombPlacementSystem : Node
{
    private static readonly PackedScene BombScene = GD.Load<PackedScene>("res://scenes/bomb.tscn");

    public Player Player { get; set; }
    public Node BombsContainer { get; set; }
    public Node ExplosionsContainer { get; set; }

    public void PlaceBomb()
    {
        if (BombsContainer.GetChildCount() < Globals.Instance.MaxBombCount)
        {
            var bombPosition = Utils.PositionToTileCenter(Player.Position);
            // Check if there is already a bomb in the same position
            foreach (Node2D bombNode in BombsContainer.GetChildren())
            {
                if (IsInstanceValid(bombNode) && bombNode.Position == bombPosition)
                {
                    return;
                }
            }

            if (IsBrickWallAtBombPlacementPosition(bombPosition))
            {
                return;
            }

            var bomb = (Bomb)BombScene.Instantiate();

            bomb.Position = bombPosition;
            bomb.ExplosionSize = Globals.Instance.ExplosionSize;
            bomb.AutoDetonate = Globals.Instance.AutoDetonate;
            bomb.ExplosionsContainer = ExplosionsContainer;
            Player.CollisionMask &= ~(uint)Utils.COLLISION_MASK.BOMB;
            BombsContainer.AddChild(bomb);
        }
    }

    private bool IsBrickWallAtBombPlacementPosition(Vector2 bombPosition)
    {
        var overlappingBodies = Player.Area2D.GetOverlappingBodies();

        foreach (Node2D body in overlappingBodies)
        {
            if (body is BrickWall && body.Position == bombPosition)
            {
                return true;
            }
        }

        return false;
    }

    public async Task DetonateBombs()
    {
        foreach (Node bomb in BombsContainer.GetChildren())
        {
            if (IsInstanceValid(bomb))
            {
                ((Bomb)bomb).Detonate();
            }
            await ToSignal(GetTree().CreateTimer(Globals.AUTO_DETONATE_DELAY), "timeout");
        }
    }
}