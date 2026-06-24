local M = {}

local function copy(t)
  if type(t) ~= "table" then return t end
  local r = {}
  for k, v in pairs(t) do
    r[k] = copy(v)
  end
  return r
end

function M.normalize(animations)
  local hooks = {}

  for name, spec in pairs(animations) do
    local animation = spec.animation or name

    local hook = copy(spec)
    hook.name = name
    hook.animation = animation

    if spec.trigger then
      hook.type = "autocmd"
      hook.event = spec.trigger
    elseif spec.filetype then
      hook.type = "filetype"
      hook.ft = spec.filetype
    elseif spec.command then
      hook.type = "command"
      hook.command = spec.command
    else
      vim.notify(
        "Goofy: animation '" .. name .. "' has no trigger (command, trigger, or filetype required)",
        vim.log.levels.WARN
      )
      goto continue
    end

    table.insert(hooks, hook)
    ::continue::
  end

  return hooks
end

return M
