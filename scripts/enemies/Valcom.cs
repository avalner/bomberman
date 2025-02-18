using System.Collections.Generic;
using Godot;

public partial class Valcom : Enemy
{
    public Valcom()
    {
        Type = EnemyType.VALCOM;
        Speed = 30;
    }

    protected override void TileCenterProcess(List<Vector2> availableDirections)
    {
        switch (_state)
        {
            case State.MOVING:
                // Select random direction from available_directions
                if (availableDirections.Count > 0)
                {
                    if (availableDirections.Contains(_direction) && GD.Randf() < 0.9f)
                    {
                        Velocity = _direction * Speed;
                    }
                    else
                    {
                        _direction = availableDirections[(int)(GD.Randi() % availableDirections.Count)];
                        Velocity = _direction * Speed;
                    }
                }
                else
                {
                    Velocity = Vector2.Zero;
                }
                break;
        }
    }
}