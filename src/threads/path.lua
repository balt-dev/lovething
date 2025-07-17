local package, prefix = ...
require "src.utils"

local NFS = require "src.nativefs"
require "src.logging"

local pathRecv = love.thread.getChannel("pathThread.send." .. package .. "." .. prefix)
local pathSend = love.thread.getChannel("pathThread.recv." .. package .. "." .. prefix)

local totalPaths = 0

---@param tbl RegistryTable
---@param dir string
---@param loadChecker fun(ext: string): boolean
local function loadRecurse(tbl, dir, loadChecker, idPrefix)
	local items, err = NFS.getDirectoryItemsInfo(dir)
	if not items then
		warn("Failed to read " .. dir .. ": " .. err)
		return
	end
	for _, item in ipairs(items) do
		if item.type == "directory" then
			loadRecurse(tbl, dir .. "/" .. item.name, loadChecker, (idPrefix and idPrefix .. "." .. item.name) or item.name)
		else
			local stem, ext
			item.name:gsub("^(.*)%.(.*)$", function(s, e) stem, ext = s, e end)
			trace("Stem: " .. stem)
			trace("Ext: " .. ext .. " (" .. tostring(loadChecker(ext)) .. ")")
			if not ext then ext = "" stem = item.name end
			if loadChecker(ext) then
				trace("Got path " .. dir .. "/" .. item.name)
				totalPaths = totalPaths + 1
				tbl[((idPrefix and idPrefix .. ".") or "") .. stem] = dir .. "/" .. item.name
			end
		end
	end
end

local dir, loadPattern = unpack(pathRecv:demand())
trace(dir)
trace(loadPattern)

local loadChecker
if type(loadPattern) == "string" then
	loadChecker = function(ext) return ext == loadPattern end
elseif type(loadPattern) == "table" then
	loadChecker = function(ext) for _, e in ipairs(loadPattern) do if e == ext then return true end end return false end
end

local t = {}
loadRecurse(t, dir, loadChecker)
pathSend:push({t, totalPaths})
