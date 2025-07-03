local cls = {}

function cls:new(def, ...)
	local t = setmetatable(def or {}, {__index = self})
	if self.init then self.init(t, ...) end
	return t
end

local proxy = {}

setmetatable(proxy, {
	__index = cls,
	__metatable = false,
})

return proxy
