if SERVER then return end

local SoundHelpers = require "/SimobiSirOP/Helpers/SoundHelpers"

S_MediaPlayer = {}

local CurrentChannels = {}

local function GetChannel(i)
    if not CurrentChannels[i] then return nil end

    if SoundHelpers.IsChannelDisposed(CurrentChannels[i]) then
        table.remove(CurrentChannels, i)
        return nil
    end

    return CurrentChannels[i]
end


local SavedLinksCache = {}
local currentCounter = 0;

local function GetGain()
    return S_ClientGlobals.Settings.SMusicPlayerVolume.value / 100
end

LuaUserData.RegisterType("NVorbis.VorbisReader")
LuaUserData.MakeFieldAccessible(Descriptors["Barotrauma.Sounds.OggSound"], "streamReader")
local function extractSoundData(sound)
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

-- Displaying title

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
        local slot = Character.Controlled.Inventory.visualSlots[1]
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
        pcall(DisplaySoundTitle, sound)
        table.insert(CurrentChannels, result)
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
    if (maxChannels <= #CurrentChannels) then
        if (maxChannels <= 0) then
            return
        end

        table.remove(CurrentChannels, 1)
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

-- So will sounds will end during round end

function S_MediaPlayer.StopAllChannels()
    for _, channel in ipairs(CurrentChannels) do
        channel.FadeOutAndDispose()
    end
    CurrentChannels = {}
end

function S_MediaPlayer.StopChannel(channel)
    for i, ch in ipairs(CurrentChannels) do
        if (ch.ALSourceIndex == channel.ALSourceIndex) then
            table.remove(CurrentChannels, i)
            return
        end
    end
    channel.FadeOutAndDispose()
end

-- Settings change

-- In percentage
local function ChangeVolume(value)
    local gainValue = value / 100
    for _, channel in ipairs(CurrentChannels) do
        channel.gain = gainValue
    end
end

local function OnMusicPlayerVolumeChange(cfg)
    ChangeVolume(cfg.value)
end
S_ClientGlobals.Settings.SMusicPlayerVolume.OnValueChanged.add(OnMusicPlayerVolumeChange)

local function OnMusicPlayerLimitChange(cfg)
    if (#CurrentChannels > cfg.value) then
        local toRemove = #CurrentChannels - cfg.value
        for i = 1, toRemove, 1 do
            CurrentChannels[1].FadeOutAndDispose()
            table.remove(CurrentChannels, 1)
        end
    end
end
S_ClientGlobals.Settings.SMusicPlayerLimit.OnValueChanged.add(OnMusicPlayerLimitChange)



-- Clearing
Hook.Add("roundEnd", "S_MP_RoundEnd", S_MediaPlayer.StopAllChannels)

Hook.Add("roundStart", "S_MP_RoundStart", S_MediaPlayer.StopAllChannels)

return S_MediaPlayer
