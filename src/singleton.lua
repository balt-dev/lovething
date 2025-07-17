---@class Singleton

---@param label string The singleton's label.
---@return Singleton
return function(label)
	local t = {}
	label = label or ("<anon: " .. tostring("t"):sub(7) .. ">")
	setmetatable(t, {__tostring = function(self) return label end})
	return t
end
