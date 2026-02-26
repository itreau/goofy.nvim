local window = require("goofy.engine.window")

local M = {}

function M.play(anim, global_opts)
	print(anim)
	local frames = anim.frames
	local delay = anim.delay or 100

	local opts = vim.tbl_deep_extend("force", global_opts or {}, anim.opts or {})

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
				if win and vim.api.nvim_win_is_valid(win) then
					vim.api.nvim_win_close(win, true)
				end
				return
			end

			if not buf then
				buf, win = window.open(frames[i], opts)
			else
				vim.api.nvim_buf_set_lines(buf, 0, -1, false, frames[i])
			end
			i = i + 1
		end)
	)
end

return M
