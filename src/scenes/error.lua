local S = Scene:new()

function S:init()
	Scene.init(self)

	self:addUI {
		type = UI.NODE.ROWS,
		config = {
			background_color = { 0, 0, 0, 1 },
			font = "base.default",
			sizes = {{100, "px"}},
			margin = 50
		},
		{ type = UI.NODE.DIV, config = { text = "Error :("}},
		{
			type = UI.NODE.DIV,
			config = { text = self.message }
		},
	}
end

return S
