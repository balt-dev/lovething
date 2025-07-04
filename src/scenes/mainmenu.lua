local S = Scene:new()

function S:init()
	Scene.init(self)

	self:addUI {
		type = UI.NODE.DIV,
		config = { text = "TODO: Main Menu" }
	}
end

return S
