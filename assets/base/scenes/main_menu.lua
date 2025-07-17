local S = Scene:new()

function S:init()
	Scene.init(self)

	self:addUI {
		type = UI.NODE.DIV,
		config = { text = "TODO: Main Menu" }
	}
end

function S:update(dt)
	Scene.update(self, dt)
	Scene.switch(G.REGISTRIES.scenes("base", "scene_chooser"):new())
end

return S
