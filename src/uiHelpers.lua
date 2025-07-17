function UI.ProgressBar(progressCallback, settings)
	settings = settings or {}
	settings.color = settings.color or {1, 1, 1, 1}
	settings.border_color = settings.color
	settings.border_width = settings.border_width or 3
	settings.padding = settings.padding or settings.border_width * 2
	local config = {
		pre_draw = function(self, x, y, w, h)
			local progress = math.min(math.max(progressCallback(), 0), 1)
			love.graphics.setColor(unpack(settings.color))
			love.graphics.rectangle(
				"fill",
				self.padding.left,
				self.padding.top,
				(w - self.padding.right - self.padding.left) * progress,
				(h - self.padding.bottom - self.padding.top)
			)
		end,
	}
	for key, value in pairs(settings) do
		config[key] = value
	end
	return { type = UI.NODE.DIV,
		config = config
	}
end

function UI.Button(clickCallback, settings)
	settings = settings or {}
	settings.background_color_idle = settings.background_color_idle or {0, 0, 0, 0.2}
	settings.background_color_hover = settings.background_color_hover or {0, 0, 0, 0.5}
	settings.background_color_click = settings.background_color_click or {0, 0, 0, 0.8}
	local config = {
		background_color = settings.background_color_idle,
		onclick = function(self, x, y)
			self.config.background_color = self.config.background_color_click
			self.config.background_image = self.config.background_image_click
			clickCallback(self, x, y)
		end,
		onunclick = function(self, x, y)
			self.config.background_color = self.config.background_color_hover
			self.config.background_image = self.config.background_image_hover
		end,
		onmouseenter = function(self)
			self.config.background_color = self.config.background_color_hover
			self.config.background_image = self.config.background_image_hover
			self.config.prevCursor = love.mouse.getCursor()
			love.mouse.setCursor(love.mouse.getSystemCursor("hand"))
		end,
		onmouseexit = function(self)
			self.config.background_color = self.config.background_color_idle
			self.config.background_image = self.config.background_image_idle
			love.mouse.setCursor(self.config.prevCursor or love.mouse.getSystemCursor("arrow"))
		end
	}
	for key, value in pairs(settings) do
		config[key] = value
	end
	return {
		type = UI.NODE.DIV,
		config = config
	}
end
