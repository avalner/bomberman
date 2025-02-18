using Godot;
using System;

public partial class DirectionalExplosion : Area2D
{
    private AnimatedSprite2D _animatedSprite;
    private Area2D _area2D;

    public override void _Ready()
    {
        _animatedSprite = GetNode<AnimatedSprite2D>("AnimatedSprite2D");
        BodyEntered += OnBodyEntered;
        AreaEntered += OnAreaEntered;
        _animatedSprite.AnimationFinished += OnAnimatedSprite2DAnimationFinished;
    }

    public void PlayAnimation(string animationName)
    {
        _animatedSprite.Play(animationName);
    }

    private void OnBodyEntered(Node2D body)
    {
        if (body.HasMethod("Destroy"))
        {
            body.Call("Destroy", this);
        }
    }

    private void OnAreaEntered(Area2D area)
    {
        if (area.HasMethod("Destroy"))
        {
            area.Call("Destroy", this);
        }
    }

    private void OnAnimatedSprite2DAnimationFinished()
    {
        QueueFree();
    }
}