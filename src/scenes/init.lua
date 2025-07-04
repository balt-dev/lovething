G.SCENES = {}
for _, scene in ipairs {
	"loading", "error", "ui_test", "mainmenu"
} do G.SCENES[scene] = require("src.scenes." .. scene) end
