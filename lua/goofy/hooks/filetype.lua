local dispatch = require("goofy.dispatch")

local M = {}

function M.register(hook)
	vim.api.nvim_create_autocmd("FileType", {
		pattern = hook.ft,
		callback = function(ctx)
			dispatch.fire(hook.animation, ctx)
		end,
	})
end

return M
