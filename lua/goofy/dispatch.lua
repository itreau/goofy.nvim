local animator = require("goofy.engine.animator")

local M = {}

function M.fire(animation, ctx)
	animator.play(animation, ctx)
end

return M
