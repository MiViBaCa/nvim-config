--[[
--
-- !!! Don't modify this
-- Create you own profile, name don't matter, e.g. sdsvkz.lua
-- Return table with overrided options
-- Your profile will be merged with default profile
--
-- !!! You should only put one profile under this folder
-- If you want to disable other profile, you can change extension to others
-- e.g. sdsvkz.lua.disabled
--
-- !!! Don't use Vkzlib, as profile contains debugging flags
--
--]]

return {
  -- Preference
  preference = {
    ---Operating system used
    ---Used for platform-specific features
    ---@type Profiles.Options.System
    ---@diagnostic disable-next-line: undefined-field
    os = vim.uv.os_uname().sysname,

    ---If `true` use mason to install tools, then configure language servers with mason-lspconfig
    ---Otherwise, configure all language servers with lspconfig
    ---@type boolean
    use_mason = true,
  },

  -- Appearence
  appearence = {
    ---To get list of available themes
    ---Run `:lua for _, theme in ipairs(vim.fn.getcompletion("", "color")) do print(theme) end`
    ---@type string
    theme = "catppuccin",

    ---Put startup menus into "lua/config/menu"
    ---Choose here using file name without extension
    ---@type string
    menu = "theta_modified",
  },

  -- Debugging
  debugging = {
    ---Whether enable test module of `vkzlib`
    ---@type boolean
    enable_test = false,

    ---Log level for `vkzlib.logging`
    ---@type vkzlib.logging.Logger.Level
    log_level = "info"
  },
}
