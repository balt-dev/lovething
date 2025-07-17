local function isIdent(str)
    return string.match(str, "^[%a_][%w_]*$") ~= nil and not ({
        	["and"] = true,
    		["break"] = true,
    		["do"] = true,
    		["else"] = true,
    		["elseif"] = true,
    		["end"] = true,
    		["false"] = true,
    		["for"] = true,
    		["function"] = true,
    		["if"] = true,
    		["in"] = true,
    		["local"] = true,
    		["nil"] = true,
    		["not"] = true,
    		["or"] = true,
    		["repeat"] = true,
    		["return"] = true,
    		["then"] = true,
    		["true"] = true,
    		["until"] = true,
    		["while"] = true
        })[str]
end

local function isSane(value)
	return type(value) ~= "table" and (type(value) ~= "string" or #value < 16)
end

--- Turns a table into a string.
--- @param tbl table
--- @return string
function tstr(tbl, seen, indent)
	if type(tbl) == "string" then
		return ("%q"):format(tbl)
	end
	if type(tbl) ~= "table" or (
		getmetatable(tbl) and
		type(getmetatable(tbl)) == "table" and
		getmetatable(tbl).__tostring
	) then return tostring(tbl) end
	seen = seen or {}
	if seen[tbl] then return "..." end
	seen[tbl] = true
	indent = indent or 1
	local printed = false
	local strings = { "{" }
	local newLine = "\n" .. ("\t"):rep(indent)
	local needNewline = #tbl > 8
	for i, value in ipairs(tbl) do
		printed = true
		if type(value) == "table" then needNewline = true end
		table.insert(strings, newLine)
		table.insert(strings, tstr(value, seen, indent + 1))
		table.insert(strings, ", ")
	end
	local pairCount = 0
	for key, value in pairs(tbl) do
		pairCount = pairCount + 1
		needNewline = needNewline or not (#tbl < 5 and
			pairCount < 3 and
			isSane(key) and
			isSane(value))
		if not (type(key) == "number" and key <= #tbl) then
			printed = true
			table.insert(strings, newLine)
			if type(key) == "string" and isIdent(key) then
				table.insert(strings, ("%s = "):format(key))
			else
				table.insert(strings, ("[%s] = "):format(tstr(key, seen, indent + 1)))
			end
			if type(value) == "string" then
				table.insert(strings, ("%q"):format(value))
			else
				table.insert(strings, ("%s"):format(tstr(value, seen, indent + 1)))
			end
			table.insert(strings, ", ")
		end
	end

	if printed then
		strings[#strings] = "\n" .. ("\t"):rep(indent - 1)
	end

	if not needNewline then
		for i, string in ipairs(strings) do
			if string:match("^\n\t*$") then
				strings[i] = ""
			end
		end
	end

	return table.concat(strings, "") .. "}"
end

love.system = love.system or require "love.system"

local os = love.system.getOS()
PATH_SEP = (os == "Windows" and "\\") or "/"


local slice_cache = {}

---@param tex love.Texture
---@param x number
---@param y number
---@param w number
---@param h number
---@param scale number
function nine_slice(tex, x, y, w, h, scale)
    scale = scale or 1
    local texture_width = tex:getWidth()
    local texture_height = tex:getHeight()

    local slices = slice_cache[tex]
    if slices == nil then
        slice_cache[tex] = {}
        for tex_x = 1, 3 do
            for tex_y = 1, 3 do
                slice_cache[tex][tex_x + (tex_y - 1) * 3] = love.graphics.newQuad(
                    (tex_x - 1) * texture_width / 3, (tex_y - 1) * texture_height / 3,
                    texture_width / 3, texture_height / 3,
                    texture_width, texture_height
                )
            end
        end
        slices = slice_cache[tex]
    end

    local spacing_x = (texture_width / 3) * scale
    local spacing_y = (texture_height / 3) * scale

    local left      = x
    local hmid      = left + spacing_x
    local right     = hmid + (w - (2 * spacing_x))

    local top       = y
    local vmid      = top + spacing_y
    local bottom    = vmid + (h - (2 * spacing_y))

    love.graphics.draw(tex, slices[1], left, top, 0, scale)
    love.graphics.draw(tex, slices[3], right, top, 0, scale)
    love.graphics.draw(tex, slices[7], left, bottom, 0, scale)
    love.graphics.draw(tex, slices[9], right, bottom, 0, scale)

    local space_x = right - hmid
    local space_y = bottom - vmid

    local scale_x = (space_x / spacing_x) * scale
    local scale_y = (space_y / spacing_y) * scale

    love.graphics.draw(tex, slices[2], hmid, top, 0, scale_x, scale)
    love.graphics.draw(tex, slices[4], left, vmid, 0, scale, scale_y)
    love.graphics.draw(tex, slices[5], hmid, vmid, 0, scale_x, scale_y)
    love.graphics.draw(tex, slices[6], right, vmid, 0, scale, scale_y)
    love.graphics.draw(tex, slices[8], hmid, bottom, 0, scale_x, scale)

    return hmid, right, vmid, bottom
end

--- Returns a shallow copy of this table.
function table:copy()
	if type(self) ~= "table" then error("cannot copy non-table", 2) end
	local t = {}
	for k, v in pairs(self) do
		t[k] = v
	end
	return t
end
