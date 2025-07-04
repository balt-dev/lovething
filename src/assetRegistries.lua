local missingTex = love.graphics.newImage("assets/base/textures/missing.png")
missingTex:setFilter("nearest", "nearest")

G.REGISTRY:registerFolder(
	"textures", "png", "",
	missingTex,
	function(data, meta)
		local min, mag = "nearest", "nearest"
		if meta.min then
			min = meta.min
			meta.min = nil
		end
		if meta.mag then
			mag = meta.mag
			meta.mag = nil
		end
		local im = love.graphics.newImage(data, meta)
		im:setFilter(min, mag)
		return im
	end
)

local cached_default_fonts = {}

G.REGISTRY:registerFolder(
	"fonts", "ttf", "",
	function(size)
		size = math.floor(size)
		if rawget(G.REGISTRY.assets.fonts, "base.default") then
			return G.REGISTRY.assets.fonts["base.default"](size)
		end
		if cached_default_fonts[size] then return cached_default_fonts[size] end
		local font = love.graphics.newFont(size)
		cached_default_fonts[size] = font
		return font
	end,
	function(data, meta)
		local cached_fonts = {}
		return function(size)
			size = math.floor(size)
			if cached_fonts[size] then return cached_fonts[size] end
			local font = love.graphics.newFont(data, size, meta.hinting or "normal")
			cached_fonts[size] = font
			return font
		end
	end
)
