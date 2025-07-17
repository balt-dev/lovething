local NFS = require "src.nativefs"
local inifile = require "src.inifile"

local S = Scene:new()

function S:init(def)
	Scene.init(self)
	def = def or {}
	self.returnScene = def.returnScene

	local this = self

	self:addUI {
		type = UI.NODE.ROWS,
		config = {
			sizes = { nil, {40, "px"}, {40, "px"}, {20, "px"}, {40, "px"}, {40, "px"} },
			overflow = true,
			background_color = { 0, 0, 0, 1 },
			font = "base.default", overflow = true
		},
		{
			type = UI.NODE.DIV,
			config = { text = "Loading...", color = {1, 1, 1, 1}, font_size = {2, "x"}, align = UI.ALIGN.BOTTOM}
		},
		{ type = UI.NODE.COLUMNS, config = {sizes = {{1, "fr"}, {2, "fr"}, {1, "fr"}}}, {}, {
			type = UI.NODE.DIV,
			config = {
				border_width = 3,
				border_color = {1, 1, 1, 1}, margin = 6,
				pre_draw = function(self, x, y, w, h)
					local progress = this.coroProgress / math.max(this.coroCount or 1, 1)
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
		}, {}},
		{
			type = UI.NODE.DIV,
			config = { text = "0/1", color = {1, 1, 1, 1}, update = function(self, dt)
				self.config.text = ("%d/%d registries loaded"):format(this.coroProgress or 0, this.coroCount or 1)
			end, align = UI.ALIGN.CENTER}
		},
		{},
		{ type = UI.NODE.COLUMNS, config = {sizes = {{1, "fr"}, {2, "fr"}, {1, "fr"}}}, {}, {
			type = UI.NODE.DIV,
			config = {
				border_width = 3,
				border_color = {1, 1, 1, 1}, margin = 6,
				pre_draw = function(self, x, y, w, h)
					local progress = this.totalProgress / math.max(this.totalCount or 1, 1)
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
		}, {}},
		{
			type = UI.NODE.DIV,
			config = { text = "0/1", color = {1, 1, 1, 1}, update = function(self, dt)
				self.config.text = ("%d/%d files loaded"):format(this.totalProgress or 0, this.totalCount or 1)
			end, align = UI.ALIGN.CENTER}
		},
		{
			type = UI.NODE.DIV,
			config = { text = "", color = {1, 1, 1, 1}, align = UI.ALIGN.TOP, update = function(self, dt)
				self.config.text = (this.lastLoadedPath and ("Loaded %s"):format(this.lastLoadedPath)) or ""
			end, align = UI.ALIGN.CENTER}
		},
	}

	self.lastUpdate = love.timer.getTime()
end

function S:update(dt)
	Scene.update(self, dt)

	if not self.loadCoroutines then
		self.loadCoroutines = {}
		self.totalProgress = 0
		self.totalCount = 0
		self.coroProgress = 0
		self.coroCount = 0
		local validPackages = {}
		for _, package in ipairs(NFS.getDirectoryItems("assets")) do
			validPackages[package] = true
			debug("Loading package " .. package)
		end
		for package in pairs(validPackages) do
			local meta = NFS.read("assets/" .. package .. "/package.ini")
			meta = inifile.parse(meta)

			local deps = meta.dependencies or {}
			local dependencies = {}
			if deps then
				for _, pck in ipairs(deps) do
					if not validPackages[pck] then error("Package " .. package .. " depends on nonexistent package " .. pck) end
					table.insert(dependencies, pck)
				end
			end
			table.insert(self.loadCoroutines, G.REGISTRY_MANAGER:loadPackage(package, dependencies))
		end
	end

	local lastUpdate = love.timer.getTime()

	local done = true
	local toRemove = {}
	while love.timer.getTime() - lastUpdate < 0.01 do
		for key, coro in pairs(self.loadCoroutines) do
			done = false
			if coroutine.status(coro) == "dead" then table.insert(toRemove, key)
			else
				local ok, res = coroutine.resume(coro)
				if not ok then
					error(res)
				end
				if res then
					local message, data = unpack(res)
					if message == "done" then table.insert(toRemove, key) end
					if message == "subTaskCount" then self.coroCount = self.coroCount + data end
					if message == "finishedSubTask" then self.coroProgress = self.coroProgress + 1 end
					if message == "totalPaths" then self.totalCount = data end
					if message == "loadedPath" then
						self.lastLoadedPath = data
						self.totalProgress = self.totalProgress + 1
					end
					trace("Coroutine message: " .. message .. ": " .. tostring(data))
				end
			end
		end
		for _, key in ipairs(toRemove) do
			self.loadCoroutines[key] = nil
		end
	end

	if done then
		trace("Done!")
		local scene = self.returnScene
		debug(tstr(G.REGISTRIES.scenes))
		scene = scene or G.REGISTRIES.scenes("base.scene_chooser"):new()
		Scene.switch(scene)
	end
end

return S
