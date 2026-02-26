local M = {}

local positions = {
	bottom_right = function(w, h)
		return {
			row = vim.o.lines - h - 4,
			col = vim.o.columns - w - 4,
		}
	end,

	center = function(w, h)
		return {
			row = math.floor((vim.o.lines - h) / 2),
			col = math.floor((vim.o.columns - w) / 2),
		}
	end,
}

function M.open(lines, opts)
	opts = opts or {}

	local buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

	local width = opts.width or math.max(unpack(vim.tbl_map(function(l)
		return #l
	end, lines)))

	local height = opts.height or #lines

	local pos_fn = positions[opts.position] or positions.bottom_right
	local pos = pos_fn(width, height)

	local win = vim.api.nvim_open_win(buf, false, {
		relative = "editor",
		row = pos.row,
		col = pos.col,
		width = width,
		height = height,
		style = "minimal",
		border = opts.border or "rounded",
	})

	if opts.color then
		for i = 0, height - 1 do
			vim.api.nvim_buf_add_highlight(buf, -1, opts.color, i, 0, -1)
		end
	end

	return buf, win
end

return M
