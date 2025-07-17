local NFS = require "src.nativefs"
require "src.logging"

local package, prefix = ...

local recv = love.thread.getChannel("loadThread.send." .. package .. "." .. prefix)
local send = love.thread.getChannel("loadThread.recv." .. package .. "." .. prefix)

while true do
	filepath = recv:demand()
	trace("Loading file at path " .. filepath)
	local contents, err = NFS.read("data", filepath)
	if not contents then
		warn("Failed to load asset: " .. err)
		send:push({false, err})
	else
		send:push({true, contents})
	end
end
