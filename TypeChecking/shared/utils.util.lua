---@meta
Util = {}

---@param groupName string
---@param func fun(item:Barotrauma.Item):boolean
Util.RegisterItemGroup = function(groupName, func)
end

---@param groupName string
---@return Barotrauma.Item[]
Util.GetItemGroup = function(groupName)
end

---@param id string
---@return Barotrauma.Item[]?
Util.GetItemsById = function(id)
end

---@param character Barotrauma.Character
---@return Barotrauma.Networking.Client?
Util.FindClientCharacter = function(character)
end

return Util
