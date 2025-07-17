require "src"

function love.load()
    G.CURRENT_SCENE = (require "src.loadingScene"):new()
end

function love.update(dt)
	G.CURRENT_SCENE:update(dt)
end

function love.resize(w, h)
	G.CURRENT_SCENE:resize(w, h)
end

function love.draw()
	G.CURRENT_SCENE:draw()
end

function love.mousepressed(x, y, button)
   	G.CURRENT_SCENE:mousepressed(x, y, button)
end

function love.mousereleased(x, y, button)
	G.CURRENT_SCENE:mousereleased(x, y, button)
end

function love.keypressed(key, unicode)
	G.CURRENT_SCENE:keypressed(key, unicode)
end

function love.keyreleased(key, unicode)
	G.CURRENT_SCENE:keyreleased(key, unicode)
end

function love.textedited(text, start, length)
	G.CURRENT_SCENE:textedited(text, start, length)
end

function love.textinput(text)
	G.CURRENT_SCENE:textinput(text)
end

function love.filedropped(file)
	G.CURRENT_SCENE:filedropped(file)
end

function love.directorydropped(path)
	G.CURRENT_SCENE:directorydropped(path)
end

function love.mousemoved(x, y, dx, dy, istouch)
	G.CURRENT_SCENE:mousemoved(x, y, dx, dy, istouch)
end

function love.wheelmoved(x, y)
	G.CURRENT_SCENE:wheelmoved(x, y)
end

function love.threaderror(thread, err)
	error("Fatal error in " .. tostring(thread) .. ": " .. err)
end

function love.quit()
	G.CURRENT_SCENE:teardown()
end
