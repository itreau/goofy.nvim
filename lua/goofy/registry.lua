local M = {}

M.animations = {}

function M.load()
	local files = vim.api.nvim_get_runtime_file("lua/goofy/animations/*.lua", true)

	for _, file in ipairs(files) do
		local name = vim.fn.fnamemodify(file, ":t:r")
		local ok, anim = pcall(require, "goofy.animations." .. name)
		if ok then
			M.animations[name] = anim
		end
	end
end

function M.get(name)
	return M.animations[name]
end

return M
