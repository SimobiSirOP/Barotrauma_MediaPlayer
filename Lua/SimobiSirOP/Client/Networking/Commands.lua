
local MediaPlayer = require "/SimobiSirOP/Client/mediaPlayer"


-- sounds

-- "S_MP.Network.PlayMusic"

-- Play

local function PlaySoundReceive(message)
    local link = message.ReadString()
    if not link then return end

    if not string.startsWith(link, "http") then return end
    MediaPlayer.PlayLink(link)
end

Networking.Receive("S_MP.Network.PlayMusic", PlaySoundReceive)

local function PlayClientMusic(args)
    if (#args < 1) then
        Logger.LogError("Not enough arguments")
        return
    end

    local link = args[1]

    if type(link) ~= "string" or not string.startsWith(link, "http") then
        Logger.LogError("Provided link is invalid")
        return
    end

    MediaPlayer.PlayLink(link)
end

Game.AddCommand("c_playmusic", "c_playMusic [link] (client) Plays specified music link", PlayClientMusic, nil, false)

-- Stops

Game.AddCommand("c_stop", "c_stop Stops All Playing Music", MediaPlayer.StopAllChannels, nil, false)

-- Restarts

Game.AddCommand("c_restart", "c_restart Restarts music", MediaPlayer.RestartAllChannels, nil, false)
