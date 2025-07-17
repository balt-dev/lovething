local inifile = require "src.inifile"

local missingTex = love.graphics.newImage("assets/base/textures/missing.png")
missingTex:setFilter("nearest", "nearest")

G.REGISTRY_MANAGER:create(
	"texturesMeta", "ini", function(data)
		local res = inifile.parse(data:getString())
		res.min = res.min or "nearest"
		res.mag = res.mag or "nearest"
		return res
	end, {min = "nearest", mag = "nearest"}, {}, "textures"
)

G.REGISTRY_MANAGER:create(
	"textures", "png",
	function(data, package, key)
		local m = G.REGISTRIES.texturesMeta(package, key)
		local meta = table.copy(m)
		min, mag = meta.min, meta.mag
		meta.min = nil
		meta.mag = nil
		local im = love.graphics.newImage(data, meta)
		im:setFilter(min, mag)
		return im
	end, missingTex, {"texturesMeta"}
)

local cached_default_fonts = {}

G.REGISTRY_MANAGER:create(
	"fontsMeta", "ini", function(data)
		local res = inifile.parse(data:getString())
		return res
	end, {hinting = "normal"}, {}, "fonts"
)

G.REGISTRY_MANAGER:create(
	"fonts", "ttf",
	function(data, package, key)
		local meta = G.REGISTRIES.fontsMeta(package, key)
		local cached_fonts = {}
		return function(size)
			size = math.floor(size)
			if cached_fonts[size] then return cached_fonts[size] end
			local font = love.graphics.newFont(data, size, "normal")
			cached_fonts[size] = font
			return font
		end
	end,
	function(size)
		size = math.floor(size)
		if
			G.REGISTRIES.fonts.loadedAssets.base and
			G.REGISTRIES.fonts.loadedAssets.base.default
		then
			return G.REGISTRIES.fonts.loadedAssets.base.default(size)
		end
		if cached_default_fonts[size] then return cached_default_fonts[size] end
		local font = love.graphics.newFont(size)
		cached_default_fonts[size] = font
		return font
	end
)

G.REGISTRY_MANAGER:create(
	"scenes", "lua",
	function(data, package, key)
		return loadstring(data:getString(), "[Scene " .. package .. "." .. key .. "]")()
	end, nil
)
