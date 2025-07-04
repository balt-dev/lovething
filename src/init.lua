G = {}

-- Module initialization here
require "src.utils"

love.thread.newThread("src/loginit.lua"):start()
require "src.logging"
info("Logger initialized!")
require "src.errorhandler"

NFS = require "src.nativefs"

Singleton = require "src.singleton"
Class = require "src.class"
Scene = require "src.scene"
Weak = require "src.weak"

G.REGISTRY = require "src.registry"
require "src.assetRegistries"

Entity = require "src.entity"
UI = require "src.ui"
require "src.scenes"

