local utf8 = require "utf8"
require "src.logging"

function love.errorhandler(msg)
	print(msg)
	msg = tostring(msg)

	if not love.window or not love.graphics or not love.event then
		warn("Could not open error handler, exiting...")
		return
	end

	if not love.graphics.isCreated() or not love.window.isOpen() then
		local success, status = pcall(love.window.setMode, 800, 600)
		if not success or not status then
			return
		end
	end

	-- Reset state.
	if love.mouse then
		love.mouse.setVisible(true)
		love.mouse.setGrabbed(false)
		love.mouse.setRelativeMode(false)
		if love.mouse.isCursorSupported() then
			love.mouse.setCursor()
		end
	end
	if love.joystick then
		-- Stop all joystick vibrations.
		for i,v in ipairs(love.joystick.getJoysticks()) do
			v:setVibration()
		end
	end
	if love.audio then love.audio.stop() end

	love.graphics.reset()
	local font = love.graphics.newFont("assets/base/fonts/jetbrains-mono.ttf", 12, "normal")
	love.graphics.setFont(font)
	local lineHeight = font:getLineHeight() * font:getHeight()

	love.graphics.setColor(1, 1, 1)

	love.graphics.origin()

	local sanitizedmsg = {}
	for char in msg:gmatch(utf8.charpattern) do
		table.insert(sanitizedmsg, char)
	end
	sanitizedmsg = table.concat(sanitizedmsg)

	local errTable = {}

	table.insert(errTable, "Fatal error :(")

	local trace = dbg.traceback(sanitizedmsg, 2)

	if love.system then
		table.insert(errTable, "")
		table.insert(errTable, "Scroll to move this text (shift to scroll horizontally)")
		table.insert(errTable, "Click to copy the error")
		table.insert(errTable, "Press Esc to exit")
	end

	table.insert(errTable, "")

	for l in trace:gmatch("(.-)\n") do
		if not l:match("boot.lua") then
			l = l:gsub("stack traceback:", "Error traceback:")
			table.insert(errTable, l)
		end
	end

	local lineCount = #errTable + 1
	local maxLineWidth = 0
	for _, line in ipairs(errTable) do
		maxLineWidth = math.max(maxLineWidth, font:getWidth(line))
	end

	local p = table.concat(errTable, "\n")

	p = p:gsub("%[string \"(.-)\"%]", "%1")

	err(p)

	local xOffset = 0
	local yOffset = 0

	local function draw()
		if not love.graphics.isActive() then return end
		local pos = 70
		love.graphics.clear(0, 0, 0)
		love.graphics.print(p, pos - xOffset, pos - yOffset)
		love.graphics.present()
	end

	local fullErrorText = p
	local function copyToClipboard()
		if not love.system then return end
		love.system.setClipboardText(fullErrorText)
	end

	return function()
		love.event.pump()

		for e, a, b, c in love.event.poll() do
			if e == "quit" or (e == "keypressed" and a == "escape") then
				return 1
			elseif e == "mousepressed" then
				copyToClipboard()
			elseif e == "wheelmoved" then
				if love.keyboard.isDown("lshift", "rshift") then
					xOffset = math.max(xOffset - b * lineHeight * 4, 0)
					xOffset = math.min(xOffset, maxLineWidth)
					yOffset = math.max(yOffset - a * lineHeight * 4, 0)
					yOffset = math.min(yOffset, lineCount * lineHeight)
				else
					xOffset = math.max(xOffset - a * lineHeight * 4, 0)
					xOffset = math.min(xOffset, maxLineWidth)
					yOffset = math.max(yOffset - b * lineHeight * 4, 0)
					yOffset = math.min(yOffset, lineCount * lineHeight)
				end
			end
		end

		draw()

		if love.timer then
			love.timer.sleep(0.01)
		end
	end
end
