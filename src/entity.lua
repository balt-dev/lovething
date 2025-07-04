local T = {}

local count = 0

local function uuid()
    local tmp = count
    count = count + 1
    return tmp
end

function T:init()
	self.uuid = uuid()
end

--- Adds the entity to a given scene.
function T:add(scene)
	scene.entities[self.uuid] = self
	self.scene = Weak(scene)
end

--- Adds a weak reference to the entity to a given scene.
--- The scene will not keep the entity alive - its reference must be held by something else, or it will drop.
function T:weak_add(scene)
	scene.weak_entities[self.uuid] = self
	self.scene = Weak(scene)
end

return Class:new(T)
