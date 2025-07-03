local T = {}

T.NODE = {
	-- The root element of the UI tree.
	ROOT = Singleton("ROOT"),
	-- Splits the given space into equal segments top-to-bottom.
	ROWS = Singleton("ROWS"),
	-- Splits the given space into equal segments left-to-right.
	COLUMNS = Singleton("COLUMNS"),
	-- Allows adding styling effects to the background of the child node, if it has one. May have text
	DIV = Singleton("DIV"),
	-- Spacer node. No entity is created for this.
	SPACER = Singleton("SPACER"),
}

T.ALIGN = {
	TOP_LEFT = function(w, h) return 0, 0 end,
	TOP = function(w, h) return w / 2, 0 end,
	TOP_RIGHT = function(w, h) return w, 0 end,
	LEFT = function(w, h) return 0, h / 2 end,
	CENTER = function(w, h) return w / 2, h / 2 end,
	RIGHT = function(w, h) return w, h / 2 end,
	BOTTOM_LEFT = function(w, h) return 0, h end,
	BOTTOM = function(w, h) return w / 2, h end,
	BOTTOM_RIGHT = function(w, h) return w, h end
}

local NodeEntity = {}

-- Each node has a type, a config, and children, as so:
--[[
local ui = UI.NodeEntity:from {
	type = UI.NODE.ROWS,
	config = {sizes = { {2, "fr"}, {}, {2, "fr"} }}, -- {} is short for 1fr
	{
		{ type = UI.NODE.DIV },
		-- Column 2 is either 100px or 1fr, whichever's bigger
		{ type = UI.NODE.COLUMNS, config = { sizes = { {}, {{{100, "px"}, {1, "fr"}}, "max"}, {} } } }, {
			{ type = UI.NODE.DIV },
			{
				type = UI.NODE.DIV,
				config = {
					extra = { clicks = 0 },
					text = "Clicks: 0", color = G.COL.WHITE,
					update = function(self, dt)
						-- Dumb example, but it works
						self.config.scale = 60 * dt
					end,
					onclick = function(self, x, y, button)
						self.config.extra.clicks = self.config.extra.clicks + 1
						self.text = ("Clicks: %d"):format(self.config.extra.clicks)
						self:recalculate()
					end,
					align = UI.ALIGN.CENTER
				} },
			{ type = UI.NODE.DIV },
		},
		{ type = UI.NODE.DIV },
	}
}
--]]


local function calc_sizes(unit_list, available_space)
	local orig_space = available_space
	local sizes = {}
	local fr_denom = 0
	for i, unit in ipairs(unit_list) do
		if unit[2] == "px" then
			available_space = available_space - unit[1]
			sizes[i] = {unit[1], 0}
		elseif unit[2] == "fr" then
			fr_denom = fr_denom + unit[1]
		end
	end
	if fr_denom == 0 then
		if available_space > 0 then
			local gap_size = available_space / #sizes
			for i, size in ipairs(sizes) do
				size[i][2] = gap_size * (i - 1)
			end
		end
		return sizes
	end
	for i, unit in ipairs(unit_list) do
		if unit[2] == "fr" then
			sizes[i] = {(unit[1] / fr_denom) * available_space, 0}
		end
	end
	return sizes
end

T.NodeEntity = Entity:new(NodeEntity)

local function layout_ui_tree(scene, tree, ent)
	if ent.dirty then return end
	ent.dirty = true
	ent.config = tree.config
	ent.type = tree.type
	if ent.type == T.NODE.ROOT then
		ent.tree = tree
	end
	ent.children = {}
	local sizes
	local l, t, b, r = 0, 0, 0, 0
	if tree.config and tree.config.margin then
		local margin = tree.config.margin
		if type(margin) == "number" then
			l = margin t = l b = l r = l
		elseif #margin == 2 then
			l = margin[1]
			t = margin[2]
			b = t r = l
		else
			l, t, b, r = unpack(margin)
		end
	end
	if tree.type == T.NODE.ROWS then
		sizes = calc_sizes(tree.config.sizes, ent.h - t - b)
	elseif tree.type == T.NODE.COLUMNS then
		sizes = calc_sizes(tree.config.sizes, ent.w - l - r)
	else
		sizes = {{ent.w - l - r, ent.x + l}}
	end
	local ox, oy = 0, 0
	for i, child in ipairs(tree) do
		local x, y, w, h
		if tree.type == T.NODE.ROWS then
			x, w = ent.x + l, ent.w - l - r
			h, y = unpack(sizes[i])
			x, y = x + ox, y + oy
			oy = oy + h
		else
			w, x = unpack(sizes[i])
			y, h = ent.y + t, ent.h - t - b
			x, y = x + ox, y + oy
			ox = ox + w
		end
		if child.type then
			local child_ent = T.NodeEntity:new({}, scene, x, y, w, h, child)
			table.insert(ent.children, child_ent)
			child_ent:weak_add(scene)
		end
	end
	ent.dirty = false
end

function NodeEntity:init(scene, x, y, w, h, tree)
	Entity.init(self)
	self.x = x
	self.y = y
	self.w = w
	self.h = h
	layout_ui_tree(scene, tree, self)
end

function NodeEntity:update(dt)
	local conf = self.config or {}
	if conf.update then
		conf.update(self, dt)
	end
	for _, child in ipairs(self.children) do
		child:update(dt)
	end
end

function NodeEntity:draw()
	local conf = self.config or {}
	local x, y, w, h = self.x, self.y, self.w, self.h

	love.graphics.push("all")

	if conf.pre_draw then conf.pre_draw(self, x, y, w, h) end
	if conf.scale then
		love.graphics.translate(w/2, h/2)
		love.graphics.scale(conf.scale, conf.scale)
		love.graphics.translate(-w/2, -h/2)
	end
	if conf.rotate then
		love.graphics.rotate(conf.rotate)
	end
	if conf.translate then
		love.graphics.translate(conf.translate.x, conf.translate.y)
	end
	if conf.transform then
		love.graphics.replaceTransform(conf.transform)
	end
	love.graphics.translate(x, y)
	if conf.background_color then
		love.graphics.setColor(unpack(conf.background_color))
		if conf.border_radius then
			love.graphics.rectangle("fill", 0, 0, w, h, conf.border_radius, conf.border_radius, 16)
		else
			love.graphics.rectangle("fill", 0, 0, w, h)
		end
	end
	if conf.border_color and conf.border_width and conf.border_radius then
		love.graphics.setColor(unpack(conf.background_color))
		love.graphics.setLineWidth(conf.border_width * math.min(w, h))
		if conf.border_radius then
			love.graphics.rectangle("line", 0, 0, w, h, conf.border_radius, conf.border_radius, 16)
		else
			love.graphics.rectangle("line", 0, 0, w, h)
		end
	end
	-- TODO: Nine-slices?
	if conf.color then
		love.graphics.setColor(unpack(conf.color))
	else
		love.graphics.setColor({1, 1, 1, 1})
	end

	if conf.text then
		local font = love.graphics.getFont()
		local text_width = font:getWidth(conf.text)
		local text_height = font:getHeight()
	    love.graphics.stencil(function()
	    	love.graphics.clear({}, true)
	    	love.graphics.rectangle("fill", 0, 0, w, h)
	    end, "replace", 1)
        love.graphics.setStencilTest("greater", 0)
        local ox, oy = (conf.text_align or T.ALIGN.CENTER)(w - text_width, h - text_height)
        love.graphics.print(conf.text, math.floor(ox), math.floor(oy))
	    love.graphics.setStencilTest()
	end

	for _, child in ipairs(self.children) do
		child:draw()
	end

	if conf.post_draw then conf.post_draw(self, x, y, w, h) end

	love.graphics.pop()
end

function NodeEntity:resize(w, h)
	print("Recalculating layout")
	if self.type ~= T.NODE.ROOT then return end
	if not self.scene then return end
	self.w = w
	self.h = h
	self.children = {}
	layout_ui_tree(self.scene, self.tree, self)
end

function Scene:addUI(def)
	local w, h = love.graphics.getDimensions()
	local ent = UI.NodeEntity:new({}, self, 0, 0, w, h, {type = T.NODE.ROOT, def})
	ent:add(self)
end

return Class:new(T)
