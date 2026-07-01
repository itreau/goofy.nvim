local registry = require "goofy.registry"
local animator = require "goofy.engine.animator"
local config = require "goofy.config"
local goofy = require "goofy"

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

  -- Animations discoverable
  local goofy_opts = goofy.opts or config.defaults
  local udir = goofy_opts.animations_dir
  local names = registry.list()
  if #names == 0 then
    vim.health.warn(
      "no animations found (looked for lua/goofy/animations/*/animation.lua on runtimepath"
        .. (udir and (" and " .. udir) or "")
        .. ")"
    )
  else
    vim.health.ok("animations: " .. table.concat(names, ", "))
  end
  if udir then vim.health.ok("user animations_dir: " .. udir) end

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
