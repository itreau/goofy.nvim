local M = {}

function M.open(lines, opts)
	opts = opts or {}

	local buf = vim.api.nvim_create_buf(false, true)

	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

	local width = 0
	for _, line in ipairs(lines) do
		width = math.max(width, #line)
	end

	local height = #lines

	local win = vim.api.nvim_open_win(buf, false, {
		relative = "editor",
		row = 2,
		col = vim.o.columns - width - 4,
		width = width,
		height = height,
		style = "minimal",
		border = "rounded",
	})

	return buf, win
end

return M
