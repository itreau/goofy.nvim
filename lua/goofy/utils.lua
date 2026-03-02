local M = {}

--- Converts heredoc strings to line arrays.
--- Animation frames can be defined as heredoc strings (e.g., [[multi\nline]])
--- or as arrays of lines (e.g., {"line1", "line2"}). This normalizes both
--- formats to arrays of lines for consistent processing.
--- @param frame string|table A heredoc string or array of lines
--- @return table Array of lines
function M.normalize_frame(frame)
	if type(frame) == "string" then
		local lines = vim.split(frame, "\n", { plain = true, trimempty = false })
		for i, line in ipairs(lines) do
			lines[i] = line:gsub("\r", "")
		end
		return lines
	end
	return frame
end

return M
