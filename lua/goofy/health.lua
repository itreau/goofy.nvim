local registry = require "goofy.registry"
local animator = require "goofy.engine.animator"
local config = require "goofy.config"

local M = {}

function M.check()
  vim.health.start "goofy.nvim"

  if vim.fn.has "nvim-0.10" == 1 then
    vim.health.ok "Neovim >= 0.10"
  else
    vim.health.error("goofy.nvim requires Neovim 0.10+", {
      "Install Neovim 0.10 or newer",
      "See https://github.com/neovim/neovim/releases",
    })
  end

  -- Animations discoverable on runtimepath
  local names = registry.list()
  if #names == 0 then
    vim.health.warn "no animations found on runtimepath under lua/goofy/animations/"
  else
    vim.health.ok(table.concat(names, ", "))
  end

  -- Strategies loadable
  local keyframe = animator.get_strategy "keyframe"
  local swipe = animator.get_strategy "swipe"
  if keyframe and swipe then
    vim.health.ok "strategies registered: keyframe, swipe"
  else
    vim.health.error("core strategies failed to load", { "check runtimepath and require errors" })
  end

  -- Duplicate proxy commands in user config
  local opts = config.defaults
  if opts and opts.animations then
    local seen = {}
    for _, hook in pairs(opts.animations) do
      if hook.command then
        local proxy = "Goofy" .. hook.command
        if seen[proxy] then vim.health.warn("duplicate proxy command :" .. proxy .. " (last registration wins)") end
        seen[proxy] = true
      end
    end
  end

  vim.health.ok "setup complete"
end

return M
