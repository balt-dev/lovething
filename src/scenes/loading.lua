local S = Scene:new()

function S:init()
	Scene.init(self)

	self:addUI {
		type = UI.NODE.COLUMNS,
		config = {
			background_color = {0, 0, 0, 1},
			sizes = {{2, "fr"}, {1, "fr"}, {1, "fr"}}
		},
		{
			type = UI.NODE.DIV,
			config = { margin = 3, background_color = {1, 0, 0, 1}, border_radius = 40},
			{
				type = UI.NODE.DIV,
				config = { background_color = {0.5, 0, 0, 1}, scale = 0.9 }
			},
		},
		{}, -- Spacer nodes are empty
		{
			type = UI.NODE.DIV,
			config = { margin = {0, 5}, background_color = {0, 0, 1, 1}, color = {1, 1, 1, 1}, text = "among us among us among us among us among us among us among us among us among us among us among us among us among us among us among us among us among us among us\namong us among us among us among us among us among us"}
		}
	}
end

return S
