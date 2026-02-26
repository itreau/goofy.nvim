local config = require("goofy.config")
local normalize = require("goofy.normalize")
local hooks = require("goofy.hooks")
local registry = require("goofy.registry")

local M = {}

function M.setup(user_opts)
	local opts = config.merge(user_opts)

	M.opts = opts

	registry.load()

	local hook_specs = normalize.normalize(opts.animations)
	hooks.register_all(hook_specs)
end

return M
