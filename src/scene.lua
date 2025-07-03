local T = Class:new()

function T:init()
	self.weak_entities = setmetatable({}, {__mode = "v"})
	self.entities = setmetatable({}, {__index = self.weak_entities})
end

local function forward_to_entities(fn_names)
	for _, fn in ipairs(fn_names) do
		T[fn] = function(self, ...)
			if self.entities then
				for _, entity in pairs(self.entities) do
					if entity[fn] then entity[fn](entity, ...) end
				end
			end
		end
	end
end

forward_to_entities {
	"teardown", "update", "draw", "mousepressed", "mousereleased", "keypressed", "keyreleased",
	"textedited", "textinput", "filedropped", "directorydropped", "resize", "mousemoved",
	"wheelmoved"
}

function T:ents()
	local it_s, st_s = pairs(self.entities)
	local it_w, st_w = pairs(self.weak_entities)
	local strong_ended = false
	return function(st, prev)
		strong_ended = strong_ended or st == nil
		if strong_ended then return it_w(st, prev) end
		local k, v = it_s(st, prev)
		if k == nil then
			strong_ended = true
			return it_w(st_w)
		end
		return k, v
	end, st_s
end

return T
