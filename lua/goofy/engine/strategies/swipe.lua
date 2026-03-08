local window = require("goofy.engine.window")
local utils = require("goofy.utils")

local M = {}

local FRAME_DELAY = 16

-- Using vector table for text shifts within ascii frame --
local DIRECTIONS = {
	left = { x = 1, y = 0 },
	right = { x = -1, y = 0 },
	up = { x = 0, y = 1 },
	down = { x = 0, y = -1 },
}

-- Returns max character width and number of lines in frame --
local function get_frame_dimensions(lines)
	local max_width = 0
	for _, line in ipairs(lines) do
		if #line > max_width then
			max_width = #line
		end
	end
	return max_width, #lines
end

-- Generic shift function moves image by pre-pending spaces --
local function shift_frame(lines, shift, dir, width)
	local result = {}
	local num_lines = #lines
	local empty_line = string.rep(" ", width)

	if dir.x ~= 0 then
		for _, line in ipairs(lines) do
			local padded
			if dir.x > 0 then
				padded = line .. empty_line
			else
				padded = empty_line .. line
			end
			local start = dir.x > 0 and (shift + 1) or (width - shift + 1)
			table.insert(result, padded:sub(start, start + width - 1))
		end
	else
		if dir.y > 0 then
			for i = shift + 1, num_lines do
				table.insert(result, lines[i])
			end
			for _ = 1, math.min(shift, num_lines) do
				table.insert(result, empty_line)
			end
		else
			for _ = 1, math.min(shift, num_lines) do
				table.insert(result, empty_line)
			end
			for i = 1, num_lines - math.min(shift, num_lines) do
				table.insert(result, lines[i])
			end
		end
	end

	return result
end

function M.validate(anim)
	assert(DIRECTIONS[anim.direction], "Swipe direction not supported: " .. tostring(anim.direction))
	assert(anim.duration, "`duration` required for swipe animation type.")
	assert(anim.frames, "`frames` required for swipe animation type.")
	assert(anim.direction, "`direction` required for swipe animation type.")
end

function M.play(anim, global_opts, on_complete)
	local dir = DIRECTIONS[anim.direction]
	local duration = anim.duration
	local opts = vim.tbl_deep_extend("force", global_opts or {}, anim.opts or {})

	local frame = utils.normalize_frame(anim.frames[1])
	local width, height = get_frame_dimensions(frame)

	local total_shifts = dir.x ~= 0 and width or height
	local shift_per_frame = total_shifts / (duration / FRAME_DELAY)

	local buf, win
	local current_shift = 0
	local closing = false

	local timer = vim.loop.new_timer()
	timer:start(
		0,
		FRAME_DELAY,
		vim.schedule_wrap(function()
			if closing then
				return
			end

			if current_shift >= total_shifts then
				closing = true
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

			local shifted_frame = shift_frame(frame, math.floor(current_shift), dir, width)

			if not buf then
				buf, win = window.open(shifted_frame, opts)
			else
				vim.api.nvim_buf_set_lines(buf, 0, -1, false, shifted_frame)
			end

			current_shift = current_shift + shift_per_frame
		end)
	)
end

return M
