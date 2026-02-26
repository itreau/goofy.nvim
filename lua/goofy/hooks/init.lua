local autocmd = require("goofy.hooks.autocmd")
local filetype = require("goofy.hooks.filetype")
local command = require("goofy.hooks.command")

local M = {}

function M.register_all(hooks)
	for _, hook in ipairs(hooks) do
		if hook.type == "autocmd" then
			autocmd.register(hook)
		elseif hook.type == "filetype" then
			filetype.register(hook)
		elseif hook.type == "command" then
			command.register(hook)
		end
	end
end

return M
