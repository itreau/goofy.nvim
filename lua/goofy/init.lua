local animator = require("goofy.engine.animator")

local M = {}

M.config = {
	enabled = true,
}

function M.setup(opts)
	vim.api.nvim_create_user_command("GoofyTest", function()
		local anim = require("goofy.animations.cool_glasses")
		animator.play(anim.frames, anim.delay)
	end, {})
	M.config = vim.tbl_deep_extend("force", M.config, opts or {})
end

return M
