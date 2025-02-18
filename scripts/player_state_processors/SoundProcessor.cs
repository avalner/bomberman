using Godot;
using System;

public partial class SoundProcessor : Node
{
    private Player _player;

    public override void _Ready()
    {
        _player = GetParent<Player>();
        _player.StateChanged += OnStateChanged;
        _player.PowerupTaken += OnPowerupTaken;
    }

    private void OnStateChanged(Player.PlayerState state, Player.PlayerState oldState)
    {
        switch (state)
        {
            case Player.PlayerState.DYING:
                SoundsPlayer.PlaySound("death");
                break;
            case Player.PlayerState.MOVING_LEFT:
            case Player.PlayerState.MOVING_RIGHT:
                SoundsPlayer.PlaySound("footsteps");
                break;
            case Player.PlayerState.MOVING_UP:
            case Player.PlayerState.MOVING_DOWN:
                SoundsPlayer.PlaySound("footsteps_alt");
                break;
            case Player.PlayerState.IDLE:
            case Player.PlayerState.DEAD:
            case Player.PlayerState.REMOVED:
                SoundsPlayer.StopSoundGroup("player");
                if (state == Player.PlayerState.DEAD)
                {
                    SoundsPlayer.PlaySound("game_over");
                }
                break;
        }
    }

    private void OnPowerupTaken(Powerup.PowerupType powerupType)
    {
        SoundsPlayer.PlaySound("powerup");
    }
}