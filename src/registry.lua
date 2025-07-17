---@class RegistryManager: Singleton
local RegistryManager = Singleton("REGISTRY")

RegistryManager.registries = {}

--- @generic Asset The asset type that is loaded.
---@alias RegistryTable {[string]: (Asset|RegistryTable)}

---@class Registry<Asset>: Class
local Registry = Class:new()

--- @generic Asset The asset type that is loaded.
---@alias LoaderFunc fun(data: love.FileData, key: string): Asset

--- Creates a registry for the given prefix that loads assets using the given function.
--- @generic Asset The asset type that is loaded.
--- @param prefix string The prefix to load the assets under.
--- @param loadChecker string|string[] A string or list of strings to check against the file extension.
--- @param loader LoaderFunc<Asset> The function to load assets with.
--- @param default Asset The asset to load as a default when fetching an ID from this registry that doesn't exist.
--- @param dependencies string[]? Any registries this depends on.
--- @param prefixPath string? The path to load the assets from. Defaults to the prefix.
--- @return Registry<Asset>
function RegistryManager:create(prefix, loadChecker, loader, default, dependencies, prefixPath)
	prefixPath = prefixPath or prefix
	if RegistryManager.registries[prefix] then
		error("Registry with prefix " .. prefix .. " already exists", 2)
	end
	local reg = Registry:new {
		prefix = prefix,
		prefixPath = prefixPath,
		loader = loader,
		loadChecker = loadChecker,
		loadedAssets = {},
		loadedPackages = {},
		dependencies = dependencies or {},
		currentPackages = 0
	}
	setmetatable(reg, {__index = Registry, __call = function(t, package, assetKey, noDefault)
		noDefault = noDefault or false
		if not assetKey then
			package:gsub("^(.-)%.(.*)$", function(p, k) package = p assetKey = k end)
		end
		res = reg.loadedAssets[package] and reg.loadedAssets[package][assetKey]
		if not res and not noDefault then res = default end
		return res
	end})
	RegistryManager.registries[prefix] = RegistryManager.registries[prefix] or reg
	return reg
end

RegistryManager.loadedPackage = {}

--- Loads assets from a specific package for all registries.
--- This will return a coroutine, giving messages in the form of `{[1]: string, [2]: any?}`.
function RegistryManager:loadPackage(package, dependencies)
	self.loadedPackage[package] = nil
	dependencies = dependencies or {}
	local this = self
	local coro = coroutine.create(function()
		local registryQueue = {}
		local registryCount = 0
		local queueIndex = 0
		local totaledPaths = 0
		local totalPaths = 0
		for prefix, registry in pairs(this.registries) do
			table.insert(registryQueue, {prefix, registry})
			registryCount = registryCount + 1
		end
		debug("Registry count: " .. registryCount)
		coroutine.yield({"subTaskCount", registryCount})
		local registriesDone = 0
		while registriesDone < registryCount do
			local idx = (queueIndex % registryCount) + 1
			local current = registryQueue[idx]
			local prefix, registry, coro = unpack(current)
			local coro = coro or registry:beginLoad(package, dependencies[prefix] or {})
			current[3] = coro
			if
			 	coroutine.status(coro) ~= "dead"
		 	then
				local ok, res
				while true do
					if coroutine.status(coro) == "dead" then break end
					ok, res = coroutine.resume(coro)
					if not ok then error(res) end
					if res == nil then coroutine.yield()
					else break end
				end
				local message, data
				if not res then goto continue end
				message, data = unpack(res)
				if message == "waitingOnRegistry" then
					debug("Can't load registry " .. prefix .. " yet, delaying until " .. data .. " loaded")
					queueIndex = queueIndex + 1
					goto continue
				elseif message == "totalPaths" then
					totaledPaths = totaledPaths + 1
					totalPaths = totalPaths + data
					coroutine.yield({"totalPaths", totalPaths})
					queueIndex = queueIndex + 1
				elseif message ~= "done" then coroutine.yield(res)
				else
					debug("Registry " .. prefix .. " done")
					registriesDone = registriesDone + 1
					queueIndex = queueIndex + 1
					coroutine.yield({"finishedSubTask"})
					goto continue
				end
				::continue::
				coroutine.yield()
			else
				queueIndex = queueIndex + 1
			end
			trace("Done: " .. registriesDone .. " of " .. registryCount)
		end
		this.loadedPackage[package] = true
		debug("Done!")
		coroutine.yield({"done"})
	end)
	return coro
end

--- Loads assets for this registry from a specific package.
--- This will return a coroutine, giving messages in the form of `{[1]: string, [2]: any?}`.
---@param package string The asset package to load the assets from.
---@param dependencies string[]? Any packages this depends on.
---@return thread
function Registry:beginLoad(package, dependencies)
	dependencies = {}
	debug("Loading registry " .. self.prefix .. " for package " .. package)

	self.currentPackages = self.currentPackages + 1
	self.loadedAssets[package] = {}
	self.loadedPackages[package] = nil

	local pathThread = love.thread.newThread("src/threads/path.lua")
	local pathSend = love.thread.getChannel("pathThread.send." .. package .. "." .. self.prefix)
	local pathRecv = love.thread.getChannel("pathThread.recv." .. package .. "." .. self.prefix)
	pathThread:start(package, self.prefix)

	local loadThread = love.thread.newThread("src/threads/load.lua")
	local loadSend = love.thread.getChannel("loadThread.send." .. package .. "." .. self.prefix)
	local loadRecv = love.thread.getChannel("loadThread.recv." .. package .. "." .. self.prefix)
	loadThread:start(package, self.prefix)

	pathSend:push({"assets/" .. package .. "/" .. self.prefixPath, self.loadChecker})

	local this = self
	local coro = coroutine.create(function()
		local dependenciesLoaded = false
		while not dependenciesLoaded do
			dependenciesLoaded = true
			local waitingOn = {}
			for _, registry in ipairs(this.dependencies) do
				if not (RegistryManager.registries[registry] and RegistryManager.registries[registry].loadedPackages[package]) then
					dependenciesLoaded = false
					coroutine.yield({"waitingOnRegistry", registry})
				else
					coroutine.yield()
				end
			end
		end

		dependenciesLoaded = false
		while not dependenciesLoaded do
			dependenciesLoaded = true
			for _, pck in ipairs(dependencies) do
				if not RegistryManager.loadedPackage[pck] then
					dependenciesLoaded = false
					coroutine.yield({"waitingOnPackage", pck})
				else
					coroutine.yield()
				end
			end
			coroutine.yield()
		end

		local totalPaths = 0
		local pathsToLoad = {}
		while true do
			local res = pathRecv:pop()
			if res == nil then coroutine.yield()
			else
				pathsToLoad, totalPaths = unpack(res)
				break
			end
		end

		coroutine.yield({"totalPaths", totalPaths})

		for key, path in pairs(pathsToLoad) do
			loadSend:push(path)
			local res
			while true do
				res = loadRecv:pop()
				if res ~= nil then break end
				coroutine.yield()
			end

			local ok, contents = unpack(res)
			if not ok then
				warn("Failed to load file at path " .. path .. ": " .. contents)
				coroutine.yield()
			else
				local asset = this.loader(contents, package, key)
				this.loadedAssets[package][key] = asset
				coroutine.yield({"loadedPath", path})
			end
		end
		setmetatable(pathsToLoad, this.default)

		this.currentPackages = this.currentPackages - 1
		this.loadedPackages[package] = true
		coroutine.yield({"done"})
	end)
	return coro
end

return RegistryManager
