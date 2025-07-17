local UI = {}

UI.NODE = {
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

UI.ALIGN = {
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


local function calc_sizes(unit_list, available_space, child_count, font_size, offset, base_size, collapse_children)
	local orig_space = available_space
	local sizes = {}
	local ul = {}
	local fr_denom = 0
	local total_used = 0
	for i = 1, child_count do
		ul[i] = (unit_list and unit_list[i]) or base_size
	end
	for i, unit in ipairs(ul) do
		if unit[2] == "px" then
			local size = unit[1] * love.graphics.getDPIScale()
			available_space = available_space - size
			sizes[i] = {size, offset}
			total_used = total_used + size
		elseif unit[2] == "em" then
			local size = unit[1] * font_size
			available_space = available_space - size
			sizes[i] = {size, offset}
			total_used = total_used + size
		elseif unit[2] == "fr" then
			fr_denom = fr_denom + unit[1]
		end
	end
	if fr_denom == 0 then
		if available_space > 0 and not collapse_children then
			total_used = available_space
			local gap_size = available_space / #sizes
			for i, size in ipairs(sizes) do
				sizes[i][2] = sizes[i][2] + gap_size * (i - 1)
			end
		end
		return sizes, total_used
	end
	total_used = available_space
	for i, unit in ipairs(ul) do
		if unit[2] == "fr" then
			sizes[i] = {(unit[1] / fr_denom) * available_space, offset}
		end
	end
	return sizes, total_used
end

UI.NodeEntity = Entity:new(NodeEntity)

local DEFAULT_FONT_SIZE = 15

local function layout_ui_tree(scene, tree, ent, font, font_size)
	if ent.dirty then return end
	ent.dirty = true
	tree.config = tree.config or {}
	ent.config = tree.config
	ent.type = tree.type
	if ent.type == UI.NODE.ROOT then
		ent.tree = tree
	end
	ent.children = {}
	local sizes
	local l, t, b, r = 0, 0, 0, 0

	font_size = font_size or DEFAULT_FONT_SIZE

	font = font or love.graphics.getFont()
	if ent.config.font then
		font = G.REGISTRIES.fonts(ent.config.font)(math.floor(font_size)) or font
	end

	if ent.config.margin then
		local pad = ent.config.margin
		if type(pad) == "number" then
			l, t, r, b = l + pad, t + pad, r + pad, b + pad
		else
			local L, T, R, B = unpack(pad)
			if R == nil then R = L end
			if B == nil then B = T end
			l, t, r, b = l + L, t + T, r + R, b + B
		end
	end

	local L, T, R, B = l, t, r, b

	if ent.config.padding then
		local pad = ent.config.padding
		if type(pad) == "number" then
			L, T, R, B = L + pad, T + pad, R + pad, B + pad
		else
			local l, t, r, b = unpack(pad)
			if r == nil then r = l end
			if b == nil then b = t end
			L, T, R, B = l + L, t + T, r + R, b + B
		end
	end

	if ent.config.font_size then
		if ent.config.font_size[2] == "x" then font_size = font_size * ent.config.font_size[1]
		elseif ent.config.font_size[2] == "h" then font_size = ent.h * ent.config.font_size[1]
		elseif ent.config.font_size[2] == "px" then font_size = ent.config.font_size[1] * love.graphics.getDPIScale()
		end
	end
	local child_count = #tree
	if tree.type == UI.NODE.ROWS then
		sizes, ent.used_space = calc_sizes(tree.config.sizes, ent.h - T - B, child_count, font_size, T, tree.config.base_size or {1, "fr"}, tree.config.collapse_children)
	elseif tree.type == UI.NODE.COLUMNS then
		sizes, ent.used_space = calc_sizes(tree.config.sizes, ent.w - L - R, child_count, font_size, L, tree.config.base_size or {1, "fr"}, tree.config.collapse_children)
	else
		sizes, ent.used_space = {{ent.w - L - R, ent.x + L}}, ent.w - L - R
	end
	local ox, oy = 0, 0
	for i, child in ipairs(tree) do
		local x, w, y, h = L, ent.w - L - R, T, ent.h - T - B
		if tree.type == UI.NODE.ROWS then
			h = sizes[i][1]
			x, y = sizes[i][2] + ox, y + oy
			oy = oy + h
		else
			w = sizes[i][1]
			x, y = sizes[i][2] + ox, y + oy
			ox = ox + w
		end
		if child.type then
			local child_ent = UI.NodeEntity:new({}, scene, x, y, w, h, child)
			table.insert(ent.children, child_ent)
			child_ent:weak_add(scene)
		end
	end
	ent.margin = {left = l, top = t, bottom = b, right = r}
	ent.padding = {left = L - l, top = T - t, bottom = B - b, right = R - r}
	ent.calc_font_size = font_size
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
	if self.config.update then
		self.config.update(self, dt)
	end
end

function NodeEntity:draw(depth, font)
	if not depth and self.type ~= UI.NODE.ROOT then return end

	local conf = self.config or {}
	local x, y, w, h = self.x, self.y, self.w, self.h
	if conf.margin then
		if type(conf.margin) == "number" then
			x, y = x + conf.margin, y + conf.margin
			w, h = w - conf.margin * 2, h - conf.margin * 2
		else
			local l, t, r, b = unpack(conf.margin)
			if r == nil then r = l end
			if b == nil then b = t end
			x, y = x + l, y + t
			w, h = w - l - r, h - t - b
		end
	end
	if self.w < 0 or self.h < 0 then return end

	love.graphics.push("all")

	if not depth then
		love.graphics.stencil(function()
			love.graphics.rectangle("fill", self.x, self.y, self.w, self.h)
		end, "replace", 0)
	end
	depth = depth or 1

	font = conf.font or font

	love.graphics.setFont(G.REGISTRIES.fonts(font or "")(math.floor(self.calc_font_size)))
	-- This cascades to the child nodes, as should be expected

	if conf.scale then
		love.graphics.translate(w/2, h/2)
		love.graphics.scale(conf.scale, conf.scale)
		love.graphics.translate(-w/2, -h/2)
	end
	if conf.rotate then
		love.graphics.rotate(conf.rotate)
	end
	local tx, ty = x, y
	if conf.translate then
		tx, ty = tx + conf.translate.x, ty + conf.translate.y
	end
	love.graphics.translate(math.floor(tx), math.floor(ty))

	love.graphics.stencil(function()
		love.graphics.rectangle("fill", 0, 0, w, h)
    end, "increment", 1, true)

    love.graphics.setStencilTest("greater", depth - 1)

	if conf.pre_draw then conf.pre_draw(self, x, y, w, h) end

	if conf.background_color then
		love.graphics.setColor(conf.background_color)
		if conf.border_radius then
			love.graphics.rectangle("fill", 0, 0, w, h, conf.border_radius, conf.border_radius, 16)
		else
			love.graphics.rectangle("fill", 0, 0, w, h)
		end
	end
	if conf.background_image then
		---@type love.Texture
		love.graphics.setColor({1, 1, 1, 1})
		local tex = G.REGISTRIES.textures(conf.background_image)
		if conf.nine_slice then
			nine_slice(tex, 0, 0, w, h, conf.nine_slice)
		else
			local tw, th = tex:getDimensions()
			love.graphics.draw(tex, 0, 0, 0, w / tw, h / th)
		end
	end
	if conf.border_color and conf.border_width then
		love.graphics.setColor(conf.border_color)
		love.graphics.setLineWidth(conf.border_width)
		local hw = conf.border_width / 2
		if conf.border_radius then
			love.graphics.rectangle("line", hw, hw, w - hw * 2, h - hw * 2, conf.border_radius, conf.border_radius, 16)
		else
			love.graphics.rectangle("line", hw, hw, w - hw * 2, h - hw * 2)
		end
	end

	if conf.text then
        love.graphics.push("all")
		if conf.text_color then
			love.graphics.setColor(conf.text_color)
		else
			love.graphics.setColor({1, 1, 1, 1})
		end
		local font = love.graphics.getFont()
		local text_width = font:getWidth(conf.text)
		local lines = 1
		for _ in conf.text:gmatch("\n") do lines = lines + 1 end
		local text_height = self.calc_font_size * (lines + 0.25)
        local ox, oy = (conf.align or UI.ALIGN.CENTER)(w - text_width, h - text_height)
        love.graphics.translate(math.floor(ox), math.floor(oy))
        love.graphics.print(conf.text, 0, 0)
        love.graphics.pop()
	end

	if UI._DEBUG then
		love.graphics.setFont(G.REGISTRIES.fonts.default(DEFAULT_FONT_SIZE))
	    love.graphics.print(self.uuid, 0, 0)
	end

	if conf.post_draw then conf.post_draw(self, x, y, w, h) end

	if conf.child_translate then
		love.graphics.translate(math.floor(conf.child_translate.x or 0), math.floor(conf.child_translate.y or 0))
	end

	for _, child in ipairs(self.children) do
		child:draw(depth + 1, font)
	end

	if conf.child_translate then
		love.graphics.translate(-math.floor(conf.child_translate.x or 0), -math.floor(conf.child_translate.y or 0))
	end

	love.graphics.stencil(function()
		love.graphics.rectangle("fill", 0, 0, w, h)
    end, "decrement", 1, true)

	love.graphics.setStencilTest()

	love.graphics.pop()
end

function NodeEntity:resize(w, h)
	if self.type ~= UI.NODE.ROOT then return end
	if not self.scene then return end
	self.w = w
	self.h = h
	self.children = {}
	layout_ui_tree(self.scene, self.tree, self)
end

local always_true = function() return true end

function NodeEntity:hit_test(x, y, cond)
	cond = cond or always_true
	local conf = self.config or {}
	local ox, oy, dw, dh = 0, 0, 0, 0
	if conf.margin then
		if type(conf.margin) == "number" then
			dw, dh = -conf.margin * 2, -conf.margin * 2
		else
			local l, t, r, b = unpack(conf.margin)
			if r == nil then r = l end
			if b == nil then b = t end
			dw, dh = -l-r, -t-b
		end
	end

	if cond(self) and x >= 0 and y >= 0 and x < self.w + dw and y < self.h + dh then
		return self
	end
end

function NodeEntity:hit_test_recursive(x, y, cond)
	local conf = self.config
	local ox, oy, dw, dh = 0, 0, 0, 0
	if conf.margin then
		if type(conf.margin) == "number" then
			ox, oy = conf.margin, conf.margin
			dw, dh = -conf.margin * 2, -conf.margin * 2
		else
			local l, t, r, b = unpack(conf.margin)
			if r == nil then r = l end
			if b == nil then b = t end
			ox, oy = l, t
			dw, dh = -l-r, -t-b
		end
	end
	if conf.translate then
		ox, oy = ox + conf.translate.x, oy + conf.translate.y
	end
	local tr = love.math.newTransform(
		ox + self.x,
		oy + self.y,
		conf.rotate or 0, conf.scale or 1, conf.scale or 1
	)
	x, y = tr:inverseTransformPoint(x, y)
	local trC = love.math.newTransform(((conf.child_translate and conf.child_translate.x) or 0), ((conf.child_translate and conf.child_translate.y) or 0))
	for i = #self.children, 1, -1 do
		local child = self.children[i]
		local Cx, Cy = trC:inverseTransformPoint(x, y)

		local res = child:hit_test_recursive(Cx, Cy, cond)
		if res then return res end
	end
	return self:hit_test(x, y, cond)
end

function NodeEntity:mousemoved(x, y)
	if self.type ~= UI.NODE.ROOT then return end
	local hit = self:hit_test_recursive(x, y)
	if self.last_hovered then
		if
			hit ~= self.last_hovered
			and self.last_hovered.config.onmouseexit
		then
			self.last_hovered.config.onmouseexit(self.last_hovered)
		end
		self.last_hovered = nil
	end
	if not self.last_hovered then
		self.last_hovered = hit
		if hit and
			hit.config.onmouseenter
		then
			hit.config.onmouseenter(hit)
		end
	end
end

function NodeEntity:mousepressed(x, y, ...)
	if self.type ~= UI.NODE.ROOT then return end
	local hit = self:hit_test_recursive(x, y)
	if not hit then return end
	debug("at " .. x .. ", " .. y .. ": " .. tstr(hit))
	if hit.config.onclick then
		hit.config.onclick(hit, x - hit.x, y - hit.y, ...)
	end
end

function NodeEntity:mousereleased(x, y, ...)
	if self.type ~= UI.NODE.ROOT then return end
	local hit = self:hit_test_recursive(x, y)
	if not hit then return end
	if hit.config.onunclick then
		hit.config.onunclick(hit, x - hit.x, y - hit.y, ...)
	end
end

function NodeEntity:wheelmoved(dx, dy)
	if self.type ~= UI.NODE.ROOT then return end
	local x, y = love.mouse.getPosition()
	local hit = self:hit_test_recursive(x, y, function(h) return h.config.onscroll ~= nil end)
	if hit and hit.config.onscroll then
		hit.config.onscroll(hit, x - hit.x, y - hit.y, dx, dy)
	end
end


function Scene:addUI(def)
	local w, h = love.graphics.getDimensions()
	local ent = UI.NodeEntity:new({}, self, 0, 0, w, h, {type = UI.NODE.ROOT, def})
	ent:add(self)
end

return Class:new(UI)
