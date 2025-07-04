local S = Scene:new()

function S:init()
	Scene.init(self)

	self.registriesToLoad = {}
	for reg, _ in pairs(G.REGISTRY.assets) do
		table.insert(self.registriesToLoad, reg)
	end

	self.totalRegistries = #self.registriesToLoad
	self.currentTotal = 1
	self.loadCount = 0

	local this = Weak(self)

	debug("Assets to load: " .. tstr(G.REGISTRY.assetsToLoad))

	self:addUI {
		type = UI.NODE.COLUMNS,
		config = {
			background_color = { 0, 0, 0, 1 },
			font = "base.default", overflow = true
		},
		{},
		{
			type = UI.NODE.ROWS,
			config = {sizes = { [2] = {40, "px"}, [3] = {10, "px"}, [4] = {40, "px"} }, overflow = true },
			{
				type = UI.NODE.DIV,
				config = { text = "Loading...", color = {1, 1, 1, 1}, font_size = {2, "x"}, align = UI.ALIGN.BOTTOM}
			},
			{
				type = UI.NODE.DIV,
				config = {
					border_width = 3,
					border_color = {1, 1, 1, 1}, margin = 6,
					pre_draw = function(self, x, y, w, h)
						local progress = ((this.totalRegistries or 1) - #(this.registriesToLoad or {})) / (this.totalRegistries or 1)
						love.graphics.setColor(1, 1, 1, 1)
						love.graphics.rectangle(
							"fill",
							self.margins.left,
							self.margins.top,
							(w - self.margins.right - self.margins.left) * progress,
							h - self.margins.top - self.margins.bottom
						)
					end,
				},
			},
			{},
			{
				type = UI.NODE.DIV,
				config = {
					border_width = 3,
					border_color = {1, 1, 1, 1}, margin = 6,
					pre_draw = function(self, x, y, w, h)
						local progress = (this.loadCount or 0) / (this.currentTotal or 1)
						love.graphics.setColor(1, 1, 1, 1)
						love.graphics.rectangle(
							"fill",
							self.margins.left,
							self.margins.top,
							(w - self.margins.right - self.margins.left) * progress,
							h - self.margins.top - self.margins.bottom
						)
					end,
				},
			},
			{
				type = UI.NODE.DIV,
				config = { text = "Loading...", color = {1, 1, 1, 1}, align = UI.ALIGN.BOTTOM, update = function(self, dt)
					self.config.text = ("Loading%s..."):format((this.currentRegistry and (" " .. this.currentRegistry)) or "")
				end}
			},
			{
				type = UI.NODE.DIV,
				config = { text = "0/1", color = {1, 1, 1, 1}, update = function(self, dt)
					self.config.text = ("%d/%d"):format(this.loadCount or 0, this.currentTotal or 1)
				end}
			},
			{
				type = UI.NODE.DIV,
				config = { text = "", color = {1, 1, 1, 1}, align = UI.ALIGN.TOP, update = function(self, dt)
					self.config.text = (this.lastLoaded and ("Loaded %s"):format(this.lastLoaded)) or ""
				end}
			},
			{
				type = UI.NODE.DIV,
				config = { text = "this screen has been\nintentionally slowed for\ndemonstration purposes", color = {1, 1, 1, 1}, font_size = {1.5, "x"}, align = UI.ALIGN.BOTTOM}
			},
			{}
		},
		{}
	}
end

function S:update(dt)
	Scene.update(self, dt)
	if love.timer.getTime() < 1 then return end
	if self.doneSince then
		if (love.timer.getTime() - self.doneSince) > 0.4 then
			Scene.switch("ui_test")
		end
		return
	end
	if not self.currentRegistry then
		self.currentRegistry = table.remove(self.registriesToLoad)
		if self.currentRegistry == nil then
			debug("Done!")
			self.doneSince = love.timer.getTime()
			return
		end
		debug("Loading " .. self.currentRegistry .. "...")
		self.loadCount = 0
		self.lastLoaded = nil
		self.recv, self.currentTotal = G.REGISTRY:load(self.currentRegistry)
	end
	local currTimer = love.timer.getTime()
	while love.timer.getTime() - currTimer < 0.1 do
		local asset, id = self.recv()
		if asset == nil then return end
		if asset == false then
			self.currentRegistry = nil
			return
		end
		self.lastLoaded = id
		G.REGISTRY.assets[self.currentRegistry][id] = asset
		self.loadCount = self.loadCount + 1
	end
end

return S
