local S = Scene:new()

function S:init()
	Scene.init(self)

	self:addUI {
		type = UI.NODE.COLUMNS,
		config = {
			background_color = { 0, 0, 0, 1 },
			sizes = { {1, "fr"}, { 50, "px" }, { 1, "fr" } },
		},
		{
			type = UI.NODE.ROWS,
			config = { margin = 30, background_color = { 1, 0, 0, 1 }, border_radius = 40, },
			{
				type = UI.NODE.COLUMNS,
				config = { background_color = { 0.5, 0, 0, 1 }, border_width = 3, border_color = { 0, 0, 0, 1 }, overflow = true },
				{
					type = UI.NODE.DIV,
					config = { background_color = { 0, 1, 0, 1 }, translate = {x = 50, y = 0},
						text = "This element intentionally overflows."
					}
				},
			},
			{
				type = UI.NODE.DIV,
				config = {
					background_color = { 0, 0, 0, 0.2 },
					clicks = 0,
					text = "clicks: 0",
					onclick = function(self, x, y)
						self.config.clicks = self.config.clicks + 1
						self.config.text = ("clicks: %d"):format(self.config.clicks)
						self.config.background_color = {0, 0, 0, 0.8}
					end,
					onunclick = function(self, x, y)
						self.config.background_color = {0, 0, 0, 0.7}
					end,
					onmouseenter = function(self)
						self.config.background_color = {0, 0, 0, 0.7}
						self.config.prevCursor = love.mouse.getCursor()
						love.mouse.setCursor(love.mouse.getSystemCursor("hand"))
					end,
					onmouseexit = function(self)
						self.config.background_color = {0, 0, 0, 0.2}
						love.mouse.setCursor(self.config.prevCursor or love.mouse.getSystemCursor("arrow"))
					end
				}
			},
		},
		{}, -- Spacer nodes are empty
		{
			type = UI.NODE.ROWS,
			{
				type = UI.NODE.DIV,
				config = {
					color = { 1, 1, 1, 1 }, text = "The quick brown fox jumps over\nthe lazy dog.",
					background_image = "base.nineslice_test", nine_slice = 16
				}
			},
			{
				type = UI.NODE.DIV,
				config = {
					color = { 1, 1, 1, 1 }, text = "----------------------------------------------------------------------------Text overflow------------------------------------------------------------------------------------",
					background_image = "base.nineslice_test"
				}
			},
			{
				type = UI.NODE.DIV,
				config = {
					color = { 1, 1, 1, 1 }, text = "Fallback texture, different font",
					font = "base.jetbrains-mono",
					background_image = ""
				}
			},
			{
				type = UI.NODE.DIV,
				config = {
					background_color = { 0, 0, 0, 0.2 },
					text = "Click to crash",
					onclick = function(self, x, y)
						error(":clueless:")
					end,
				}
			},
		},
	}
end

return S
