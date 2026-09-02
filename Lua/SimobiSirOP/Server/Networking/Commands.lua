if CLIENT then return end

if not (LuaUserData.IsRegistered("Barotrauma.DebugConsole")) then
    LuaUserData.RegisterType("Barotrauma.DebugConsole")
end

local DebugConsole = LuaUserData.CreateStatic("Barotrauma.DebugConsole")
-- Play sound command


local function OnPlaySoundCommand(args)
    if (#args < 1) then
        Logger.LogError("Not enough arguments")
        return
    end

    local link = args[1]

    if type(link) ~= "string" or not string.startsWith(link, "http") then
        Logger.LogError("Provided link is invalid")
        return
    end

    local message = Networking.Start("S_MP.Network.PlayMusic")
    message.WriteString(link)

    local clientName = args[2]
    if (clientName) then
        local cl = DebugConsole.FindClient(clientName)
        if (cl) then
            Networking.Send(message, cl.Connection)
        else
            Logger.LogError("Client " .. { clientName } .. "  not found")
            return
        end
    else
        for _, cl in pairs(Client.ClientList) do
            Networking.Send(message, cl.Connection)
        end
    end
end

Game.AddCommand("playMusic",
    "playMusic [link] (client) Plays specified music link on specified clients (or everyone if not specified)",
    OnPlaySoundCommand, nil, false)
