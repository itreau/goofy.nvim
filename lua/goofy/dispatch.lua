local animator = require("goofy.engine.animator")
local registry = require("goofy.registry")

local M = {}

-- Dispatches animate calls to rendering engine using identifier and
-- pre-registered animation functions
-- @param animation_name The name used to identify the animation during registration.
-- @param ctx Context table.
function M.fire(animation_name, ctx)
	local animation = registry.get(animation_name)
	if not animation then
		vim.notify("Goofy: Animation '" .. animation_name .. "' not found", vim.log.levels.WARN)
		return
	end
	animator.play(animation, ctx)
end

return M
