local M = {}

M.defaults = {
  window = {
    border = "rounded",
    position = "bottom_right",
    width = nil,
    height = nil,
    color = nil,
  },
  animation = {
    delay = 30,
    loop = false,
    sequence_delay = 0,
  },
  animations = {},
}

local KNOWN_KEYS = { window = true, animation = true, animations = true }

function M.validate(user_opts)
  if user_opts == nil then return end
  assert(type(user_opts) == "table", "setup() expects a table, got: " .. type(user_opts))

  if user_opts.window then
    assert(type(user_opts.window) == "table", "window must be a table")
    if user_opts.window.border ~= nil then
      assert(
        type(user_opts.window.border) == "string" or type(user_opts.window.border) == "table",
        "window.border must be a string or table"
      )
    end
    if user_opts.window.position ~= nil then
      assert(type(user_opts.window.position) == "string", "window.position must be a string")
    end
  end

  if user_opts.animation then
    assert(type(user_opts.animation) == "table", "animation must be a table")
    if user_opts.animation.delay ~= nil then
      assert(
        type(user_opts.animation.delay) == "number" and user_opts.animation.delay >= 0,
        "animation.delay must be a non-negative number"
      )
    end
    if user_opts.animation.sequence_delay ~= nil then
      assert(
        type(user_opts.animation.sequence_delay) == "number" and user_opts.animation.sequence_delay >= 0,
        "animation.sequence_delay must be a non-negative number"
      )
    end
    if user_opts.animation.loop ~= nil then
      assert(type(user_opts.animation.loop) == "boolean", "animation.loop must be a boolean")
    end
  end

  if user_opts.animations ~= nil then assert(type(user_opts.animations) == "table", "animations must be a table") end

  for k in pairs(user_opts) do
    if not KNOWN_KEYS[k] then
      vim.notify("Goofy: unknown config key '" .. tostring(k) .. "' (ignored)", vim.log.levels.WARN)
    end
  end
end

function M.merge(user_opts)
  M.validate(user_opts)
  return vim.tbl_deep_extend("force", {}, M.defaults, user_opts or {})
end

return M
