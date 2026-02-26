local M = {}

function M.normalize(animations)
	local hooks = {}

	for name, spec in pairs(animations) do
		local animation = spec.animation or name

		if spec.trigger then
			table.insert(hooks, {
				type = "autocmd",
				event = spec.trigger,
				animation = animation,
			})
		elseif spec.filetype then
			table.insert(hooks, {
				type = "filetype",
				ft = spec.filetype,
				animation = animation,
			})
		elseif spec.command then
			table.insert(hooks, {
				type = "command",
				command = spec.command,
				animation = animation,
			})
		end

		::continue::
	end

	return hooks
end

return M
