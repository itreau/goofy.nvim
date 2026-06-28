local config = require "goofy.config"
local normalize = require "goofy.normalize"
local hooks = require "goofy.hooks"
local registry = require "goofy.registry"
local dispatch = require "goofy.dispatch"

local M = {}

local MIN_NVIM = "nvim-0.10"

function M.setup(user_opts)
  assert(vim.fn.has(MIN_NVIM) == 1, "goofy.nvim requires Neovim 0.10+")

  local opts = config.merge(user_opts)
  M.opts = opts

  registry.load()

  local hook_specs = normalize.normalize(opts.animations)
  hooks.register_all(hook_specs)
end

-- Public API: trigger animations programmatically.
--   require("goofy").play("write")
--   require("goofy").fire({ "write", "cool_glasses" }, { delay = 100 })
M.play = dispatch.fire
M.fire = dispatch.fire
M.play_sequence = dispatch.play_sequence

return M
