local window = require("goofy.engine.window")
local utils = require("goofy.utils")

local M = {}

function M.validate(anim)
	assert(anim.frames, "Keyframe animation requires `frames`")
	assert(anim.delay, "keyframe animation requires `delay`")
end

function M.play(anim, global_opts, on_complete)
	local frames = anim.frames
	local delay = anim.delay

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
				if on_complete then
					on_complete()
				end
				return
			end

			local frame = utils.normalize_frame(frames[i])
			if not buf then
				buf, win = window.open(frame, opts)
			else
				vim.api.nvim_buf_set_lines(buf, 0, -1, false, frame)
			end
			i = i + 1
		end)
	)
end

return M
