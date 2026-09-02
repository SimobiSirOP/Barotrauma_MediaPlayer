
S_MPGlobals = {}

S_MPGlobals.Path = ...
S_MPGlobals.MainPath = S_MPGlobals.Path .. "/Lua/SimobiSirOP"
S_MPGlobals.ClientPath = S_MPGlobals.MainPath  .. "/Client"
S_MPGlobals.ServerPath = S_MPGlobals.MainPath  .. "/Server"
S_MPGlobals.MediaPath = S_MPGlobals.Path  .. "/TempMedia"

if SERVER or not(Game.IsMultiplayer) then
    dofile(S_MPGlobals.ServerPath .. "/start.lua")
end

if CLIENT then
    dofile(S_MPGlobals.ClientPath .. "/start.lua")
end
