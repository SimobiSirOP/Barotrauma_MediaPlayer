if SERVER then return end

-- TODO Add albums that can be shared with Loading.
-- TODO Split Media player to multiple files
-- TODO Add better channel management


if not (File.DirectoryExists(S_MPGlobals.MediaPath)) then
    File.CreateDirectory(S_MPGlobals.MediaPath)
end

local SoundHelpers = require "/SimobiSirOP/Helpers/SoundHelpers"

S_MediaPlayer = {}

--- Current MediaPlayer channels
---@type table
S_MediaPlayer.CurrentChannels = {}

local function GetChannel(i)
    if not S_MediaPlayer.CurrentChannels[i] then return nil end

    if SoundHelpers.IsChannelDisposed(S_MediaPlayer.CurrentChannels[i]) then
        table.remove(S_MediaPlayer.CurrentChannels, i)
        return nil
    end

    return S_MediaPlayer.CurrentChannels[i]
end

-- Caching links so we won't have to download it everytime
local SavedLinksCache = {}
local currentCounter = 0;

local function GetGain()
    return S_ClientGlobals.Settings.SMusicPlayerVolume.value / 100
end

if (CSActive) then 
    LuaUserData.RegisterType("NVorbis.VorbisReader")
    LuaUserData.MakeFieldAccessible(Descriptors["Barotrauma.Sounds.OggSound"], "streamReader")
end

local function extractSoundData(sound)

    if not CSActive then error("Trying to execute a non-sandboxed method in sandboxed environment") end

    local data = {}
    local comments = sound.streamReader.Comments

    for _, comment in ipairs(comments) do
        local key, value = comment:match("^%s*(%w+)%s*=%s*(.-)%s*$")

        if key ~= nil then
            local field = key:sub(1, 1):upper() .. key:sub(2)
            data[field] = value
        end
    end

    return data
end



local function DisplaySoundTitle(sound)
    local soundData = extractSoundData(sound)
    if not soundData.Title then return end

    local text = string.format(TextManager.Get("SimobiSirOP_MP.MediaPlayer.ScreenDisplayText").ToString(),
        soundData.Title)
    
    Logger.LogMessage("[Simobi's Media player] " .. text, nil, Color.White)


    local frame = Game.GameScreen.Frame


    local label = GUI.TextBlock(
       GUI.RectTransform(Vector2(1, 0), frame.RectTransform, GUI.Anchor.BottomCenter), text,
       Color.White, nil, GUI.Alignment.Left)

    -- Putting above the hud if there is a character for inventory (So it will look better)
    if Character.Controlled and Character.Controlled.Inventory and Character.Controlled.Inventory.visualSlots[1] then
        local slot = Character.Controlled.Inventory.visualSlots[1] -- Relative to 
        label.RectTransform.AbsoluteOffset = Point(
            slot.Rect.Center.X - label.Rect.Width/2,
            slot.Rect.Height + 70
        )
    end

    
    label.Color = Color.White
    label.FadeOut(1, true, 5, nil, true)
end

local function PlayWhenLoaded(sound, position)
    if sound == nil then
        return
    end

    if sound.Loading then
        Timer.Wait(function()
            PlayWhenLoaded(sound, position)
        end, 100)

        return
    end

    if sound.Disposed then
        return
    end

    local channel
    if position then
        channel = SoundPlayer.PlaySound(sound, position, GetGain(), 1500, nil, nil, false, true)
    else
        channel = sound.Play(GetGain())
    end
    if not channel then return end


    return channel
end

local function PlayFile(fileName, position)
    local sound = Game.SoundManager.LoadSound(fileName, true)
    local success, result = pcall(PlayWhenLoaded, sound, position)



    if (success) then
        if CSActive then 
            pcall(DisplaySoundTitle, sound)
        end
        table.insert(S_MediaPlayer.CurrentChannels, result)
        return result
    else
        Logger.LogError(result)
    end
end






local function GetFileName()
    return S_MPGlobals.MediaPath .. "/" .. currentCounter .. "_c.ogg"
end

local function DownloadOggFile(url, callback)
    -- Getting File name
    local success = false;
    local fileName
    local attempts = 0
    while not success or attempts > 20 do
        fileName = GetFileName();
        if not (File.Exists(fileName)) then 
            success = true 
            break;
        end

        local fstream
        success, fstream = pcall(File.OpenWrite, fileName)
        if success and fstream then 
            fstream.Close()
        end
        attempts = attempts + 1
        currentCounter = currentCounter + 1
    end

    if (attempts > 20) then
        Logger.LogError("Exceeded amount of tried allowed to check file accessibility")
        return
    end

    Networking.HttpGet(url, function(response) callback(response, fileName) end, nil, fileName)
    return fileName
end

function S_MediaPlayer.PlayLink(url, position)
    local maxChannels = S_ClientGlobals.Settings.SMusicPlayerLimit.value;
    if (maxChannels <= #S_MediaPlayer.CurrentChannels) then
        if (maxChannels <= 0) then
            return
        end

        table.remove(S_MediaPlayer.CurrentChannels, 1)
    end


    local fileName;
    if (SavedLinksCache[url] and File.Exists(SavedLinksCache[url])) then
        fileName = SavedLinksCache[url]
        PlayFile(fileName, position)
    else
        fileName = DownloadOggFile(url, function(response, file)
            if not (SoundHelpers.IsOgg(response)) then
                Logger.LogError("Provided url: " .. url .. " wasn't a OGG sound file")
                return;
            end

            PlayFile(file)
        end)
        SavedLinksCache[url] = fileName
    end
end



--- Stops all channels (Results in stopping all music, even looping one)
function S_MediaPlayer.StopAllChannels()
    for _, channel in ipairs(S_MediaPlayer.CurrentChannels) do
        channel.FadeOutAndDispose()
    end
    S_MediaPlayer.CurrentChannels = {}
end

--- Stops specific channel if it exists in MediaPlayer.S_MediaPlayer.CurrentChannels
function S_MediaPlayer.StopChannel(channel)
    for i, ch in ipairs(S_MediaPlayer.CurrentChannels) do
        if (ch.ALSourceIndex == channel.ALSourceIndex) then
            table.remove(S_MediaPlayer.CurrentChannels, i)
            return
        end
    end
    channel.FadeOutAndDispose()
end

--- Restarts all channels
---@return NewChannels table New channels of restarted music
function S_MediaPlayer.RestartAllChannels()
    local NewChannels = {}
    for i,ch in pairs(S_MediaPlayer.CurrentChannels) do
        local sound = ch.Sound
        local position = ch.Position
        ch.FadeOutAndDispose()

        local newCh
        if ch.Position then
            newCh = SoundPlayer.PlaySound(sound, position, GetGain(), 1500, nil, nil, false, true)
        else
            newCh = sound.Play(GetGain())
        end
        table.insert(NewChannels, newCh)
    end
    S_MediaPlayer.CurrentChannels = NewChannels
    return S_MediaPlayer.CurrentChannels
end

-- Settings change

--- Changes volume of all channels
---@param volume int (volume)
local function ChangeVolume(volume)
    local gainValue = volume
    for _, channel in ipairs(S_MediaPlayer.CurrentChannels) do
        channel.gain = gainValue
    end
end

local function OnMusicPlayerVolumeChange(cfg)
    ChangeVolume(cfg.value)
end
S_ClientGlobals.Settings.SMusicPlayerVolume.OnValueChanged.add(OnMusicPlayerVolumeChange)

local function OnMusicPlayerLimitChange(cfg)
    if (#S_MediaPlayer.CurrentChannels > cfg.value) then
        local toRemove = #S_MediaPlayer.CurrentChannels - cfg.value
        for i = 1, toRemove, 1 do
            S_MediaPlayer.CurrentChannels[1].FadeOutAndDispose()
            table.remove(S_MediaPlayer.CurrentChannels, 1)
        end
    end
end
S_ClientGlobals.Settings.SMusicPlayerLimit.OnValueChanged.add(OnMusicPlayerLimitChange)



-- Clearing
Hook.Add("roundEnd", "S_MP_RoundEnd", S_MediaPlayer.StopAllChannels)

Hook.Add("roundStart", "S_MP_RoundStart", S_MediaPlayer.StopAllChannels)

return S_MediaPlayer
