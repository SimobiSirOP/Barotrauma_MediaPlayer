
local MediaPlayer = require "/SimobiSirOP/Client/mediaPlayer"


-- sounds

-- "S_MP.Network.PlayMusic"

local function PlaySoundReceive(message)
    local link = message.ReadString()
    if not link then return end

    if not string.startsWith(link, "http") then return end
    MediaPlayer.PlayLink(link)
end

Networking.Receive("S_MP.Network.PlayMusic", PlaySoundReceive)