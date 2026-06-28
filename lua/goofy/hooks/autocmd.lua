local M = {}

local function build_ctx(hook)
  return {
    delay = hook.delay,
    opts = hook.opts,
  }
end

function M.register(hook, group)
  vim.api.nvim_create_autocmd(hook.event, {
    group = group,
    callback = function()
      local dispatch = require "goofy.dispatch"
      dispatch.fire(hook.animation, build_ctx(hook))
    end,
  })
end

return M
