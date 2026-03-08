local animator = require("goofy.engine.animator")
local registry = require("goofy.registry")

local M = {}

function M.play_sequence(animations, ctx, index)
	index = index or 1
	if index > #animations then
		return
	end

	local animation_name = animations[index]
	local animation = registry.get(animation_name)
	if not animation then
		vim.notify("Goofy: Animation '" .. animation_name .. "' not found", vim.log.levels.WARN)
		M.play_sequence(animations, ctx, index + 1)
		return
	end

	local delay = ctx and ctx.delay or 0

	animator.play(animation, ctx, function()
		if index < #animations then
			vim.defer_fn(function()
				M.play_sequence(animations, ctx, index + 1)
			end, delay)
		end
	end)
end

function M.fire(animation_name, ctx)
	if type(animation_name) == "string" then
		local animation = registry.get(animation_name)
		if not animation then
			vim.notify("Goofy: Animation '" .. animation_name .. "' not found", vim.log.levels.WARN)
			return
		end
		animator.play(animation, ctx)
	elseif type(animation_name) == "table" then
		M.play_sequence(animation_name, ctx)
	end
end

return M
