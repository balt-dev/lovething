require "src.utils"
local socket = require "socket"

local savedir = love.filesystem.getSaveDirectory()

love.filesystem.createDirectory(savedir .. "/log")

logFile = logFile or love.filesystem.newFile(savedir .. PATH_SEP .. os.date("%Y-%m-%d-%H-%M-%S") .. ".log")
if not logFileOpen then
	logFileOpen, logErr = logFile:open("w")
end

logLevel = ({trace = 5, debug = 4, info = 3, warn = 2, error = 1})[(os.getenv("LOG_LEVEL") or "info")] or 3

local function log(level, str)
	if level > logLevel then return end
	level = ({"ERROR", "WARN", "INFO", "DEBUG", "TRACE"})[level]
	local message = "[" .. level .. "] " .. os.date("!%Y-%m-%d %H:%M:%S") .. (".%.4d"):format((socket.gettime() * 10000) % 10000) .. ": " .. str
	if logFileOpen then
		logFile:write(message .. "\n")
	end
	print(message)
end

if not logFileOpen then
	log(2, "Opening log file failed: " .. logErr)
end

local logChannel = love.thread.getChannel("logging")
while true do
	local res = logChannel:demand()
	if type(res) ~= "table" then
		log(2, "Malformed log entry: " .. tostring(res))
	else
		local level, msg = unpack(res)
		if msg == nil then
			msg = level
			level = 3
		end
		msg = (type(msg) == "table" and tstr(msg)) or tostring(msg)
		level = (type(level) == "number" and level) or 3
		log(level, msg)
	end
end

