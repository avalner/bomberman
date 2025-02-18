using Godot;

public partial class BrickWall : StaticBody2D
{
    public AnimatedSprite2D AnimatedSprite2D;

    public override void _Ready()
    {
        AnimatedSprite2D = GetNode<AnimatedSprite2D>("AnimatedSprite2D");
        AnimatedSprite2D.AnimationFinished += OnAnimatedSprite2DAnimationFinished;
    }

    public void Destroy()
    {
        CollisionLayer = 0;
        AnimatedSprite2D.Play("destroy");
        Globals.Instance.SetAstarPointEnabled(Position);

        if (Utils.HasPlayerAtPosition(GlobalPosition))
        {
            Globals.Instance.Player.Destroy(this);
        }
    }

    private void OnAnimatedSprite2DAnimationFinished()
    {
        QueueFree();
    }
}