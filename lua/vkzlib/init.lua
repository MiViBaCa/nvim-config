-- Lazy load everything into vkzlib.
local MODULE = "init"

local vkzlib = setmetatable({}, {
  __index = function(t, k)
    local ok, val = pcall(require, string.format("vkzlib.%s", k))

    if ok and val ~= nil then
      -- Loaded and not ignored
      rawset(t, k, val)
    elseif _DEBUG ~= "OFF" and not ok then
      assert(false)
      -- Failed to load
      local log = {
        d = require("vkzlib.internal").logger(MODULE, "debug")
      }
      local core = require("vkzlib.core")
      assert(type(core) == "table", "vkzlib.init: Unable to load core for printing error object")
      log.d("vkzlib.<metatable>.__index", core.to_string(val))
    end
    -- ok == true and val == nil ignored

    return val
  end
})

return vkzlib
