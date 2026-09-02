---@meta
json = {}

---@param vs string
---@return table
function json.parse(vs) end

---@param vt table
---@return string
function json.serialize(vt) end

---@return userdata
function json.null() end

---@param v any
---@return boolean
function json.isnull(v) end

return json
