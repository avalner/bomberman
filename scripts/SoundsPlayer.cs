using Godot;

public static class SoundsPlayer
{
    static private Node _soundsPlayer = null;

    static private void InitSoundsPlayer()
    {
        _soundsPlayer ??= GetRootNode().GetNode("/root/SoundsPlayer");
    }
    public static Node GetRootNode()
    {
        return (Engine.GetMainLoop() as SceneTree)?.Root;
    }

    public static void PlaySound(string soundName)
    {
        InitSoundsPlayer();
        _soundsPlayer.Call("play_sound", soundName);
    }

    public static void StopSound(string soundName)
    {
        InitSoundsPlayer();
        _soundsPlayer.Call("stop_sound", soundName);
    }

    public static bool IsPlaying(string soundName)
    {
        InitSoundsPlayer();
        return (bool)_soundsPlayer.Call("is_playing", soundName);
    }

    public static void StopSoundGroup(string groupName)
    {
        InitSoundsPlayer();
        _soundsPlayer.Call("stop_sound_group", groupName);
    }

    public static void StopAllSounds()
    {
        InitSoundsPlayer();
        _soundsPlayer.Call("stop_all_sounds");
    }
}
