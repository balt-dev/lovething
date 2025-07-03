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

function T:add(scene)
	scene.entities[self.uuid] = self
	self.scene = Weak(scene)
end

function T:weak_add(scene)
	scene.weak_entities[self.uuid] = self
	self.scene = Weak(scene)
end

return Class:new(T)
