
S_ClientGlobals = {}

S_ClientGlobals.Settings = {}

local function InitializeSettings()
    local success, myPackage = trygetpackage("SimobiSirOP Media Player")
    local successVolume, volume = ConfigService.TryGetConfig(SettingBase.Int32,myPackage, "SMusicPlayerVolume")
    local successLimit, concurrentLimit = ConfigService.TryGetConfig(SettingBase.Int32,myPackage, "SMusicPlayerLimit")
    if (successVolume and successLimit) then
        S_ClientGlobals.Settings.SMusicPlayerVolume = volume
        S_ClientGlobals.Settings.SMusicPlayerLimit = concurrentLimit
    else
        error("Failed initializing SimobiSirOP Music Player Settings")
    end
end


InitializeSettings()


dofile(S_MPGlobals.ClientPath .. "/mediaPlayer.lua")

dofile(S_MPGlobals.ClientPath .. "/Networking/Commands.lua")