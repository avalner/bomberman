using System.Collections.Generic;
using Godot;

public partial class AnimationProcessor : Node
{
    private static readonly Dictionary<Player.PlayerState, string> _animationMap = new()
    {
        { Player.PlayerState.DYING, "death" },
        { Player.PlayerState.MOVING_LEFT, "walk_left" },
        { Player.PlayerState.MOVING_RIGHT, "walk_right" },
        { Player.PlayerState.MOVING_UP, "walk_up" },
        { Player.PlayerState.MOVING_DOWN, "walk_down" },
    };

    private static readonly Dictionary<Player.PlayerState, string> _idleAnimationMap = new()
    {
        { Player.PlayerState.MOVING_LEFT, "idle_left" },
        { Player.PlayerState.MOVING_RIGHT, "idle_right" },
        { Player.PlayerState.MOVING_UP, "idle_up" },
        { Player.PlayerState.MOVING_DOWN, "idle_down" }
    };

    private Player _player;

    public override void _Ready()
    {
        _player = GetParent<Player>();
        _player.StateChanged += OnStateChanged;
    }

    private void OnStateChanged(Player.PlayerState state, Player.PlayerState oldState)
    {
        if (_animationMap.TryGetValue(state, out var animation))
        {
            _player.PlayerAnimations.Play(animation);
        } else if (_idleAnimationMap.TryGetValue(oldState, out var idleAnimation))
        {
            _player.PlayerAnimations.Play(idleAnimation);
        }
    }
}