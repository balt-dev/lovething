G.SCENES = {}
for _, scene in ipairs {
	-- Put all scenes in the game in this list.
	"loading", "ui_test", "mainmenu"
} do G.SCENES[scene] = require("src.scenes." .. scene) end
