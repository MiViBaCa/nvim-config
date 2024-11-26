---@type "OFF" | "ON"
_DEBUG = "OFF"

---@type vkzlib.logging.Logger.Level
LOG_LEVEL = "debug"

Vkzlib = require("config.vkzlib")
require("config.vim")

local options = require("config.options")
if options.CURRENT_SYSTEM == options.SYSTEM_LIST.WINDOWS then
  require("config.powershell")
end

---@diagnostic disable-next-line: different-requires
require("config.lazy")
require("config.lsp")
require("config.theme")
require('config.keymap')
require("config.autocmds")
