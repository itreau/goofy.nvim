local window = require("goofy.engine.window")

local M = {}

function M.play(frames, delay)
	local buf, win
	local i = 1

	local timer = vim.loop.new_timer()
	timer:start(
		0,
		delay,
		vim.schedule_wrap(function()
			if i > #frames then
				timer:stop()
				timer:close()
				vim.api.nvim_win_close(win, true)
				return
			end

			if not buf then
				buf, win = window.open(frames[i])
			else
				vim.api.nvim_buf_set_lines(buf, 0, -1, false, frames[i])
			end

			i = i + 1
		end)
	)
end

return M
