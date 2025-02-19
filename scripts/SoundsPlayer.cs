using Godot;
using Godot.Collections;
using System;
using System.Collections.Generic;
using System.Linq;

public class SoundsPlayer
{
    public struct Player
    {
        public AudioStreamPlayer player;
        public Timer timer;
    }

    private static readonly Dictionary jsonSounds;

    private static readonly Godot.Collections.Dictionary<string, Dictionary> sounds;
    private static readonly System.Collections.Generic.Dictionary<string, List<Player>> players = [];
    private static Node soundsPlayerNode;


    static SoundsPlayer()
    {
        jsonSounds = LoadJson("res://config/sounds.json");
        sounds = MapDictionary(jsonSounds);
    }

    public static Node SoundsPlayerNode
    {
        get
        {
            if (soundsPlayerNode == null)
            {
                soundsPlayerNode = new Node
                {
                    Name = "SoundsPlayer"
                };

                Utils.RootNode.CallDeferred(Node.MethodName.AddChild, soundsPlayerNode);
            }
            return soundsPlayerNode;
        }
    }

    private static Godot.Collections.Dictionary<string, Dictionary> MapDictionary(Dictionary original)
    {
        var result = new Godot.Collections.Dictionary<string, Dictionary>();

        foreach (string key in original.Keys.Select(v => (string)v))
        {
            var originalEntry = (Dictionary)original[key];
            var entry = new Dictionary
            {
                ["audio_stream"] = (AudioStream)GD.Load(originalEntry["file"].AsString())
            };

            if (originalEntry.ContainsKey("group"))
            {
                entry["group"] = originalEntry["group"];
            }

            if (originalEntry.ContainsKey("volume_db"))
            {
                entry["volume_db"] = originalEntry["volume_db"];
            }

            if (originalEntry.ContainsKey("pitch_scale"))
            {
                entry["pitch_scale"] = originalEntry["pitch_scale"];
            }

            if (originalEntry.ContainsKey("loop"))
            {
                entry["loop"] = originalEntry["loop"];
            }

            if (originalEntry.ContainsKey("delay"))
            {
                entry["delay"] = originalEntry["delay"];
            }

            if (originalEntry.ContainsKey("bus"))
            {
                entry["bus"] = originalEntry["bus"];
            }

            result[key] = entry;
        }

        return result;
    }

    private static Dictionary LoadJson(string filePath)
    {
        using var file = FileAccess.Open(filePath, FileAccess.ModeFlags.Read);
        if (file == null)
        {
            GD.Print("Error: Unable to open JSON file.");
            return [];
        }

        string content = file.GetAsText();
        file.Close();

        var jsonParser = new Json();
        var error = jsonParser.Parse(content);

        if (error != Error.Ok)
        {
            GD.Print("Error parsing JSON: " + jsonParser.GetErrorMessage());
            return [];
        }

        return jsonParser.Data.AsGodotDictionary();
    }

    public static bool IsPlaying(string soundName)
    {
        return players.ContainsKey(soundName);
    }

    public static void PlaySound(string soundName)
    {
        if (!sounds.TryGetValue(soundName, out Dictionary config))
        {
            GD.Print("Sound not found: " + soundName);
            return;
        }


        var player = new AudioStreamPlayer();
        Timer timer = null;

        player.Stream = (AudioStream)config["audio_stream"];

        if (config.ContainsKey("group"))
        {
            StopSoundGroup(config["group"].AsString());
        }

        if (config.ContainsKey("bus"))
        {
            player.Bus = config["bus"].AsString();
        }

        if (config.ContainsKey("volume_db"))
        {
            player.VolumeDb = config["volume_db"].AsSingle();
        }

        if (config.ContainsKey("pitch_scale"))
        {
            player.PitchScale = config["pitch_scale"].AsSingle();
        }

        if (config.ContainsKey("loop") && config["loop"].AsBool() && !config.ContainsKey("delay"))
        {
            // Check if the stream type supports looping
            if (player.Stream is AudioStreamWav streamSample)
            {
                streamSample.LoopMode = AudioStreamWav.LoopModeEnum.Forward;
            }
            else if (player.Stream is AudioStreamOggVorbis streamOgg)
            {
                streamOgg.Loop = true;
            }
            else if (player.Stream is AudioStreamMP3 streamMp3)
            {
                streamMp3.Loop = true;
            }
            else
            {
                GD.Print("Warning: Looping not supported for this audio stream type.");
            }
        }
        if (config.ContainsKey("delay"))
        {
            timer = new Timer();
            timer.Timeout += () => player.Play();
            timer.WaitTime = config["delay"].AsSingle();
            SoundsPlayerNode.CallDeferred(Node.MethodName.AddChild, timer);
            timer.CallDeferred(Timer.MethodName.Start);
        }

        var playerItem = new Player { player = player };

        if (timer != null)
        {
            playerItem.timer = timer;
        }

        if (players.TryGetValue(soundName, out List<Player> value))
        {
            value.Add(playerItem);
        }
        else
        {
            players[soundName] = [playerItem];
        }

        SoundsPlayerNode.CallDeferred(Node.MethodName.AddChild, player);
        player.CallDeferred(AudioStreamPlayer.MethodName.Play);

        // Automatically queue the player for deletion when the sound ends
        if (timer == null)
        {
            player.Finished += () =>
            {
                if (GodotObject.IsInstanceValid(player))
                {
                    player.QueueFree();
                }
            };
        }
    }

    public static void StopSound(string soundName)
    {
        if (players.TryGetValue(soundName, out List<Player> value))
        {
            foreach (Player playerItem in value)
            {
                if (playerItem.timer != null)
                {
                    playerItem.timer.Stop();
                    playerItem.timer.QueueFree();
                }

                if (playerItem.player != null && GodotObject.IsInstanceValid(playerItem.player))
                {
                    playerItem.player.Stop();
                    playerItem.player.QueueFree();
                }
            }
            players.Remove(soundName);
        }
    }

    public static void StopSoundGroup(string groupName)
    {
        foreach (var soundName in players.Keys)
        {
            if (sounds[soundName].ContainsKey("group") && sounds[soundName]["group"].AsString() == groupName)
            {
                StopSound(soundName);
            }
        }
    }

    public static void StopAllSounds()
    {
        foreach (var soundName in new List<string>(players.Keys)) // Create a copy to avoid modification during iteration
        {
            StopSound(soundName);
        }
    }
}