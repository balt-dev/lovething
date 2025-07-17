local S = Scene:new()

function S:init()
	Scene.init(self)

	local nodes = {}
	for package, scene_list in pairs(G.REGISTRIES.scenes.loadedAssets) do
		if type(scene_list) ~= "table" then goto continue end
		local buttons = {}
		for key, scene in pairs(scene_list) do
			table.insert(buttons, UI.Button(
				function()
					Scene.switch(scene:new())
				end,
				{text = key}
			))
		end
		table.insert(nodes, {
			type = UI.NODE.ROWS,
			config = {sizes = {{50, "px"}, {1, "fr"}}, background_color = {0, 0, 0, 0.1}, margin = 10, padding = 10},
			{
				type = UI.NODE.DIV,
				config = {text = package, font_size = {2, "x"}}
			},
			UI.Scrollbox(buttons, {
				base_size = {40, "px"},
				background_color = {0, 0, 0, 0.1},
				padding = 10
			})
		})
		::continue::
	end

	debug(tstr(nodes))

	self:addUI {
		type = UI.NODE.ROWS,
		config = {
			background_color = { 0.1, 0.15, 0.3, 1 },
			border_radius = 20,
			margin = 30,
			sizes = { {1, "fr"}, {5, "fr"} },
		},
		{
			type = UI.NODE.DIV,
			config = { text = "Choose a scene", font_size = {4, "x"}, color = {1, 1, 1, 1} },
		},
		UI.Scrollbox(
			nodes
		)
	}
end

return S
