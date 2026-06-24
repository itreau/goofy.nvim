local M = {}

function M.close(buf, win, timer)
  if timer and not timer:is_closing() then
    timer:stop()
    timer:close()
  end
  if win and vim.api.nvim_win_is_valid(win) then vim.api.nvim_win_close(win, true) end
end

return M
