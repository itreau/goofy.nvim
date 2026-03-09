local dispatch = require("goofy.dispatch")

local M = {}

function M.register(hook)
	vim.api.nvim_create_autocmd(hook.event, {
		callback = function(ctx)
			dispatch.fire(hook.animation, ctx)
		end,
	})
end

return M
