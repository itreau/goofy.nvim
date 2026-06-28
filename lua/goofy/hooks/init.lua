local autocmd = require "goofy.hooks.autocmd"
local filetype = require "goofy.hooks.filetype"
local command = require "goofy.hooks.command"

local M = {}

local AUGROUP_NAME = "Goofy"

function M.register_all(hooks)
  local group = vim.api.nvim_create_augroup(AUGROUP_NAME, { clear = true })

  local seen_commands = {}
  for _, hook in ipairs(hooks) do
    if hook.type == "autocmd" then
      autocmd.register(hook, group)
    elseif hook.type == "filetype" then
      filetype.register(hook, group)
    elseif hook.type == "command" then
      command.register(hook, group, seen_commands)
    end
  end
end

return M
