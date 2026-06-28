local M = {}

local function build_ctx(hook)
  return {
    delay = hook.delay,
    opts = hook.opts,
  }
end

function M.register(hook, group, seen_commands)
  local proxy = "Goofy" .. hook.command

  if seen_commands[proxy] then
    vim.notify("Goofy: duplicate command mapping for :" .. proxy .. " (last registration wins)", vim.log.levels.WARN)
  end
  seen_commands[proxy] = true

  vim.api.nvim_create_user_command(proxy, function(opts)
    vim.api.nvim_cmd({
      cmd = hook.command,
      bang = opts.bang and true or nil,
      range = opts.range,
      count = opts.count,
      args = opts.fargs,
    }, {})
    local dispatch = require "goofy.dispatch"
    dispatch.fire(hook.animation, build_ctx(hook))
  end, {
    bang = true,
    range = true,
    nargs = "*",
    count = true,
    force = true,
  })
end

return M
