local M = {}

local function build_ctx(hook)
  return {
    delay = hook.delay,
    opts = hook.opts,
  }
end

function M.register(hook, group)
  local once = hook.once
  if once == nil then once = true end
  local mark = "goofy_played_" .. hook.name

  vim.api.nvim_create_autocmd("FileType", {
    group = group,
    pattern = hook.ft,
    callback = function(ctx)
      if once then
        local ok, already = pcall(vim.api.nvim_buf_get_var, ctx.buf, mark)
        if ok and already then return end
        vim.api.nvim_buf_set_var(ctx.buf, mark, true)
      end
      local dispatch = require "goofy.dispatch"
      dispatch.fire(hook.animation, build_ctx(hook))
    end,
  })

  vim.api.nvim_create_autocmd("BufDelete", {
    group = group,
    callback = function(ctx) pcall(vim.api.nvim_buf_set_var, ctx.buf, "goofy_played_" .. hook.name, nil) end,
  })
end

return M
