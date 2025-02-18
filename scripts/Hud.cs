using System;
using Godot;

public partial class Hud : PanelContainer
{
    private const int WarningThreshold = 10;

    private Label _timeLabel;
    private Label _scoreLabel;
    private Label _livesLabel;

    public override void _Ready()
    {
        _timeLabel = GetNode<Label>("HBoxContainer/TimeLabel");
        _scoreLabel = GetNode<Label>("HBoxContainer/ScoreLabel");
        _livesLabel = GetNode<Label>("HBoxContainer/LivesLabel");

        UpdateTime(Globals.Instance.RemainingTime, true);
        UpdateLives(Globals.Instance.Lives);
        UpdateScore(Globals.Instance.Score);

        Globals.Instance.LevelTimeChanged += OnLevelTimeChanged;
        Globals.Instance.PlayerLivesChanged += UpdateLives;
        Globals.Instance.ScoreChanged += UpdateScore;
    }

    public override void _ExitTree()
    {
        Globals.Instance.LevelTimeChanged -= OnLevelTimeChanged;
        Globals.Instance.PlayerLivesChanged -= UpdateLives;
        Globals.Instance.ScoreChanged -= UpdateScore;
        base._ExitTree();
    }

    private void OnLevelTimeChanged(int time)
    {
        UpdateTime(time);
    }

    private void UpdateTime(int time, bool noSound = false)
    {
        _timeLabel.Text = "Time: " + time.ToString();

        if (noSound) return;

        if (time <= WarningThreshold)
        {
            _timeLabel.AddThemeColorOverride("font_color", new Color(1, 0, 0));

            if (time == 1)
            {
                SoundsPlayer.PlaySound("timer_last_tick");
            }
            else
            {
                SoundsPlayer.PlaySound("timer_tick");
            }
        }
        else
        {
            _timeLabel.AddThemeColorOverride("font_color", new Color(1, 1, 1));
        }
    }

    private void UpdateScore(int score)
    {
        _scoreLabel.Text = "Score: " + score.ToString();
    }

    private void UpdateLives(int lives)
    {
        _livesLabel.Text = "Lives: " + lives.ToString();
    }
}