local T = Class:new()

function T:init()
	self.weak_entities = setmetatable({}, {__mode = "v"})
	self.entities = setmetatable({}, {__index = self.weak_entities})
end

local function forward_to_entities(fn_names)
	for _, fn in ipairs(fn_names) do
		T[fn] = function(self, ...)
			for _, entity in self:ents() do
				if entity[fn] then entity[fn](entity, ...) end
			end
		end
	end
end

forward_to_entities {
	"teardown", "update", "draw", "mousepressed", "mousereleased", "keypressed", "keyreleased",
	"textedited", "textinput", "filedropped", "directorydropped", "resize", "mousemoved",
	"wheelmoved"
}

--- Iterates through all entities in the scene.
function T:ents()
	local iter, st, val = pairs(self.entities)
	return function()
		local k, v = iter(st, val)
		if k ~= nil then val = k return k, v end
		if st == self.entities then
			iter, st, val = pairs(self.weak_entities)
			k, v = iter(st, val)
			if k ~= nil then val = k return k, v end
		end
	end
end

--- Switches to another scene with a given ID.
function T.switch(id, ...)
	if not G.SCENES[id] then
		warn("Tried to switch to nonexistent scene " .. id)
		return
	end
	G.CURRENT_SCENE:teardown()
	G.CURRENT_SCENE = G.SCENES[id]:new(...)
end

return T
