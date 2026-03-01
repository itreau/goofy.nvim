local strategies = {
	["keyframe"] = require("goofy.engine.strategies.keyframe"),
	["swipe"] = require("goofy.engine.strategies.swipe"),
}

local M = {}

function M.play(anim, global_opts)
	local anim_type = anim.type or "keyframe"
	local strategy = strategies[anim_type]

	assert(strategy, "Unknown animation type: " .. tostring(anim_type))

	if strategy.validate then
		strategy.validate(anim)
	end

	strategy.play(anim, global_opts)
end

return M
