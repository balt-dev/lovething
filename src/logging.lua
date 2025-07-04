
local logChannel = love.thread.getChannel("logging")

function trace(msg)
	logChannel:push{5, msg}
end

dbg = debug

function debug(msg)
	logChannel:push{4, msg}
end

function info(msg)
	logChannel:push{3, msg}
end

function warn(msg)
	logChannel:push{2, msg}
end

function err(msg)
	logChannel:push{1, msg}
end

print = info
