local dispatch = require("goofy.dispatch")

local M = {}

function M.register(hook)
	local proxy = "Goofy" .. hook.command

	vim.api.nvim_create_user_command(proxy, function()
		vim.cmd(hook.command)
		dispatch.fire(hook.animations)
	end, {})
end

return M
