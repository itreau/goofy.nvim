local M = {}

M.defaults = {
	window = {
		border = "rounded",
		position = "bottom_right",
		width = nil,
		height = nil,
		color = nil,
	},

	animation = {
		delay = 30,
		loop = false,
		sequence_delay = 0,
	},

	animations = {},
}

function M.merge(user_opts)
	return vim.tbl_deep_extend("force", {}, M.defaults, user_opts or {})
end

return M
