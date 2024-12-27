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

-- TODO: Complete language options
-- This should let user enable what language to use.
-- Profile should enable some tools for language being chosen
-- User should be able to exclude or include some optional tools

---@class profiles.Profile
local profile = {
  ---Preference
  ---@class profiles.Profile.Preference
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

  ---Editor
  ---@class profiles.Profile.Editor
  editor = {
    ---@type boolean
    ---
    ---@see vim.o.number
    line_numbering = true,

    ---@type boolean
    ---
    ---@see vim.o.expandtab
    expand_tab_to_spaces = true,

    ---@type integer
    ---
    ---@see vim.o.tabstop
    ---@see vim.o.softtabstop
    ---@see vim.o.shiftwidth
    tab_size = 4,

    ---@type boolean
    ---
    ---@see vim.o.autoindent
    ---@see vim.o.smartindent
    auto_indent = true,
  },

  ---Appearence
  ---@class profiles.Profile.Appearence
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

  ---Languages
  ---@class profiles.Profile.Languages
  languages = {
    -- TODO: I need some utilities to turn this into usable datasets. Probably put them into profiles.utils

    ---Supported language, map filetype into language options
    ---@class profiles.Profile.Languages.Supported
    supported = {
      ---@class profiles.Profile.Languages.Language
      c = {
        ---Whether to use this language
        ---e.g. You can use this to implement platform
        ---@type boolean
        enable = false,
        ---@class profiles.Profile.Languages.Tools
        tools = {
          -- TODO: Add options to `formatters` and `linters`

          ---@type [string]?
          formatters = nil,
          ---@type [string]?
          linters = nil,
          ---@type { [config.lsp.Server.MasonConfig]: config.lsp.Handler }?
          ls = {
            [{ "clangd", auto_update = true }] = true,
          },
          -- TODO: Add dap config here after nvim-dap is added
        },
      },
      ---@type profiles.Profile.Languages.Language
      cpp = {
        enable = false,
        tools = {
          ls = {
            [{ "clangd", auto_update = true }] = true,
          },
        },
      },
      ---@type profiles.Profile.Languages.Language
      haskell = {
        enable = false,
        tools = {
          -- formatters = { "ormolu" }, -- HLS use Ormolu as built-in formatter
          linters = { "hlint" },
          ls = {
            ["hls"] = {
              -- Use HLS from PATH for better customization
              -- Since only supported ghc versions can be used
              config = true
            },
          },
        },
      },
      ---@type profiles.Profile.Languages.Language
      lua = {
        enable = false,
        tools = {
          formatters = { "stylua" },
          linters = { "luacheck" },
          ls = {
            [{ "lua_ls", auto_update = true }] = function (info)
              info.lspconfig.lua_ls.setup {
                on_init = function(client)
                  local path = client.workspace_folders[1].name
                  ---@diagnostic disable-next-line: undefined-field
                  if vim.uv.fs_stat(path..'/.luarc.json') or vim.uv.fs_stat(path..'/.luarc.jsonc') then
                    return
                  end

                  client.config.settings.Lua = vim.tbl_deep_extend('force', client.config.settings.Lua, {
                    runtime = {
                      -- Tell the language server which version of Lua you're using
                      -- (most likely LuaJIT in the case of Neovim)
                      version = 'LuaJIT'
                    },
                    -- Make the server aware of Neovim runtime files
                    workspace = {
                      checkThirdParty = false,
                      library = {
                        vim.env.VIMRUNTIME
                        -- Depending on the usage, you might want to add additional paths here.
                        -- "${3rd}/luv/library"
                        -- "${3rd}/busted/library",
                      }
                      -- or pull in all of 'runtimepath'.
                      -- library = vim.api.nvim_get_runtime_file("", true)
                    }
                  })
                end,

                settings = {
                  Lua = {}
                }
              }
            end,
          },
        },
      },
      ---@type profiles.Profile.Languages.Language
      json = {
        enable = false,
        tools = {
          ls = {
            [{ "jsonls", auto_update = true }] = true,
          },
        },
      },
      ---@type profiles.Profile.Languages.Language
      python = {
        enable = false,
        tools = {
          formatters = { "isort", "black" },
          linters = { "flake8", "bandit" },
          ls = {
            [{ "pyright", auto_update = true }] = true,
          },
        },
      },
    },

    ---Map filetype into language options
    ---Override this in your own profile. It will be merged with `supported`
    ---@type profiles.Profile.Languages.Supported | [profiles.Profile.Languages.Language]
    custom = {},

    --- !!! Don't touch those fields
    --- Those will be extracted automatically from fields above

    ---This should be extracted automatically from fields above
    ---@type string[]?
    formatters = nil,

    ---This should be extracted automatically from fields above
    ---@type string[]?
    linters = nil,

    ---This should be extracted automatically from fields above
    ---@type { [config.lsp.Server.MasonConfig]: config.lsp.Handler }?
    ls = nil,
  },

  ---Debugging
  ---@class profiles.Profile.Debugging
  debugging = {

  },
}

return profile
