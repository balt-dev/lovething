local Registry = Singleton("REGISTRY")

Registry.assetsToLoad = {}
Registry.assetLoaders = {}
Registry.assetCount = 0
Registry.assets = {}
Registry.defaults = {}

--- Register all files in a folder with a given suffix as assets to be loaded in this registry.
---@param prefix string The asset prefix to load these assets under.
---@param file_suffix string The file extension to load as assets.
---@param default any The default asset to load if an attempt is made to load a nonexistent one.
---@param loadSingle (fun(data: love.FileData, meta: table?): any?)? Function used to load an asset using a given FileData.
function Registry:registerFolder(prefix, file_suffix, default, loadSingle)
	local items = NFS.getDirectoryItemsInfo("assets", "directory")
	for _, item in pairs(items) do
		local package_name = item.name
		local folder_path = "assets" .. PATH_SEP .. package_name .. PATH_SEP .. prefix

		Registry:registerPackage(prefix, folder_path, file_suffix, package_name .. ".", default, loadSingle)
	end
end

function Registry:registerPackage(prefix, folder_path, file_suffix, path, default, loadSingle)
	toLoad = toLoad or self.assetsToLoad[prefix]
	if loadSingle then
		self.assetLoaders[prefix] = loadSingle
	end
	if default then
		self.defaults[prefix] = default
	end
	self.assets[prefix] = setmetatable({}, {__index = function(t, k) return self.defaults[prefix] end})
	self.assetsToLoad[prefix] = self.assetsToLoad[prefix] or {}
	local items = NFS.getDirectoryItemsInfo(folder_path)
	for _, item in ipairs(items) do
		if item.type == "file" then
			local stem
			if item.name:find("%." .. file_suffix .. "$") then
				stem = item.name:gsub("^.*" .. PATH_SEP, ""):gsub("%." .. file_suffix .. "$", "")
				self.assetsToLoad[prefix][path .. stem] = self.assetsToLoad[prefix][path .. stem] or {}
				self.assetsToLoad[prefix][path .. stem][1] = folder_path .. PATH_SEP .. item.name
			elseif item.name:find("%." .. file_suffix .. "%.meta$") then
				stem = item.name:gsub("^.*" .. PATH_SEP, ""):gsub("%." .. file_suffix .. "%.meta$", "")
				self.assetsToLoad[prefix][path .. stem] = self.assetsToLoad[prefix][path .. stem] or {}
				self.assetsToLoad[prefix][path .. stem][2] = folder_path .. PATH_SEP .. item.name
			end
			self.assetCount = self.assetCount + 1
		elseif item.type == "directory" then
			self:registerFolder(folder_path .. PATH_SEP .. item.name, file_suffix, prefix, path .. item.name .. ".", default)
		end
	end
end

--- Returns a thread to start and function that can be called to pop the most recently loaded data, along with how many assets need to be loaded.
--- @return love.Thread? thread Loading thread, not yet started.
--- @return fun():any func Function to call to pop the most recent data. Will return nil if no data is available, or false if all data has been loaded.
--- @return number toLoad Amount of assets that need to be loaded.
function Registry:load(prefix)
	if self.assetCount == 0 then return nil, function() return false end end
	self.current = 0
	local send = love.thread.getChannel("loadSend")
	local recv = love.thread.getChannel("loadRecv")
	local loadThread = love.thread.newThread [[
		ini = require "src.inifile"
		require "src.logging"

		local recv = love.thread.getChannel("loadSend")
		local send = love.thread.getChannel("loadRecv")
		local res = true
		while res do
			res = recv:demand()
			if res then
				local id, file, meta = unpack(res)
				debug("Loading " .. id)
				if meta then
					meta = ini.parse(love.filesystem.read(meta))
				end
				send:push({id, love.filesystem.read("data", file), meta or {}})
			end
		end
		send:push(false)
	]]
	local toLoad = 0
	for id, pair in pairs(self.assetsToLoad[prefix]) do
		send:push {id, unpack(pair)}
		toLoad = toLoad + 1
		self.assetsToLoad[prefix][id] = nil
	end
	send:push(false)
	return loadThread, function()
		local data = recv:pop()
		if data == nil then return end
		if data == false then return false end
		local id, data, meta = unpack(data)
		local asset = self.assetLoaders[prefix](data, meta)
		self.current = self.current + 1
		return asset, id
	end, toLoad
end


return Registry
