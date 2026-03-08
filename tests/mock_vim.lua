-- Mock vim module for testing
local M = {
  split = function(str, sep, opts)
    opts = opts or {}
    local result = {}
    local pattern = opts.plain and sep or sep:gsub("([%(%)%.%%%+%-%*%?%[%]%^%$])", "%%%1")
    for part in string.gmatch(str .. sep, "([^" .. pattern .. "]*)" .. pattern) do
      table.insert(result, part)
    end
    if opts.trimempty then
      while #result > 0 and result[1] == "" do
        table.remove(result, 1)
      end
      while #result > 0 and result[#result] == "" do
        table.remove(result)
      end
    end
    return result
  end,
  
  log = {
    levels = {
      WARN = 2,
      ERROR = 3,
      INFO = 1,
    },
  },
}

return M
