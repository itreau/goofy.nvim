local M = {}

M.animations = {}
M.names = {}

function M.load()
  M.animations = {}
  M.names = {}

  if vim.api and vim.api.nvim_get_runtime_file then
    local files = vim.api.nvim_get_runtime_file("lua/goofy/animations/*.lua", true)
    for _, file in ipairs(files) do
      local name = vim.fn.fnamemodify(file, ":t:r")
      M.names[name] = true
    end
  end
end

function M.get(name)
  local cached = M.animations[name]
  if cached ~= nil then return cached or nil end

  local ok, anim = pcall(require, "goofy.animations." .. name)
  if ok then
    M.animations[name] = anim
    return anim
  end

  -- negative cache so we don't retry require on every fire
  M.animations[name] = false
  return nil
end

function M.list()
  local result = {}
  for name in pairs(M.names) do
    table.insert(result, name)
  end
  table.sort(result)
  return result
end

return M
