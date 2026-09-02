---@meta
math = {}

---@param a number
---@param b number
---@param t number
---@return number
math.lerp = function(a, b, t) end

---@param value number
---@param min number
---@param max number
---@return number
math.clamp = function(value, min, max) end

---@param value number
---@param decimals number
---@return number
math.round = function(value, decimals) end

---@param value number
---@return integer
math.sign = function(value) end

---@param value number
---@param inMin number
---@param inMax number
---@param outMin number
---@param outMax number
---@return number
math.remap = function(value, inMin, inMax, outMin, outMax) end

return math
