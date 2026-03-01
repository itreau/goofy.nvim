local window = require("goofy.engine.window")

local M = {}

local FRAME_DELAY = 16

local SUPPORTED_DIRECTIONS = {
	["left"] = true,
	["right"] = true,
	["up"] = true,
	["down"] = true,
}

local function normalize_frame(frame)
	if type(frame) == "string" then
		local lines = vim.split(frame, "\n", { plain = true, trimempty = false })
		for i, line in ipairs(lines) do
			lines[i] = line:gsub("\r", "")
		end
		return lines
	end
	return frame
end

local function get_frame_dimensions(lines)
	local max_width = 0
	for _, line in ipairs(lines) do
		if #line > max_width then
			max_width = #line
		end
	end
	return max_width, #lines
end

local function shift_frame_horizontal(lines, shift, direction, max_width)
	local result = {}
	for _, line in ipairs(lines) do
		if direction == "left" then
			local padded = line .. string.rep(" ", max_width)
			table.insert(result, padded:sub(shift + 1, shift + max_width))
		else
			local padded = string.rep(" ", max_width) .. line
			table.insert(result, padded:sub(max_width - shift + 1, max_width * 2 - shift))
		end
	end
	return result
end

local function shift_frame_vertical(lines, shift, direction, max_width)
	local result = {}
	local num_lines = #lines
	local empty_line = string.rep(" ", max_width)

	if direction == "up" then
		for i = shift + 1, num_lines do
			table.insert(result, lines[i])
		end
		for i = 1, math.min(shift, num_lines) do
			table.insert(result, empty_line)
		end
	else
		for i = 1, math.min(shift, num_lines) do
			table.insert(result, empty_line)
		end
		local start_idx = math.max(1, shift - num_lines + 1)
		for i = start_idx, num_lines do
			table.insert(result, lines[i - start_idx + 1])
		end
	end
	return result
end

function M.validate(anim)
	assert(SUPPORTED_DIRECTIONS[anim.direction], "Swipe direction not supported: " .. tostring(anim.direction))
	assert(anim.duration, "`duration` required for swipe animation type.")
	assert(anim.frames, "`frames` required for swipe animation type.")
	assert(anim.direction, "`direction` required for swipe animation type.")
end

function M.play(anim, global_opts)
	local direction = anim.direction
	local duration = anim.duration
	local opts = vim.tbl_deep_extend("force", global_opts or {}, anim.opts or {})

	local frame = normalize_frame(anim.frames[1])
	local max_width, height = get_frame_dimensions(frame)

	local total_shifts, shift_per_frame

	if direction == "left" or direction == "right" then
		total_shifts = max_width
		shift_per_frame = total_shifts / (duration / FRAME_DELAY)
	else
		total_shifts = height
		shift_per_frame = total_shifts / (duration / FRAME_DELAY)
	end

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
				return
			end

			local shifted_frame
			if direction == "left" or direction == "right" then
				shifted_frame = shift_frame_horizontal(frame, math.floor(current_shift), direction, max_width)
			else
				shifted_frame = shift_frame_vertical(frame, math.floor(current_shift), direction, max_width)
			end

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
