-- Mock vim module for testing (pure-Lua, no nvim dependency)
-- Tests may override individual fields (vim.defer_fn, vim.api.*, etc.) per-case.
--
-- Captured at first require (while _G.vim is still the real nvim) so that plenary's
-- busted runner (vim.deepcopy/vim.inspect) and nvim's Lua module loader
-- (vim.api.nvim__get_runtime) keep working after a test replaces _G.vim with this mock.
local _real = _G.vim or {}
local _real_api = _real.api or {}
local _real_fn = _real.fn or {}

local M = {}

local function copy(t)
  if type(t) ~= "table" then return t end
  local r = {}
  for k, v in pairs(t) do
    r[k] = copy(v)
  end
  return r
end
M._copy = copy

-- String split (basic, supports { plain = bool, trimempty = bool })
M.split = function(str, sep, opts)
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
end

-- Log levels matching nvim's vim.log.levels enum
M.log = {
  levels = {
    TRACE = 0,
    DEBUG = 1,
    INFO = 2,
    WARN = 3,
    ERROR = 4,
    OFF = 5,
  },
}

-- Notifies: no-op by default; tests may capture by overriding
M.notify = function() end

-- Schedules: run immediately by default
M.defer_fn = function(fn, _) fn() end
M.schedule_wrap = function(f) return f end

-- Deep table merge (force semantics): later keys win, nested tables merged
M.tbl_deep_extend = function(mode, ...)
  local function deep(dst, src)
    for k, v in pairs(src) do
      if type(v) == "table" and type(dst[k]) == "table" then
        deep(dst[k], v)
      else
        dst[k] = copy(v)
      end
    end
    return dst
  end

  local result = {}
  for i = 1, select("#", ...) do
    local t = select(i, ...)
    if t then deep(result, t) end
  end
  return result
end

-- Editor options (sane defaults; tests may override)
M.o = {
  lines = 24,
  columns = 80,
  cmdheight = 1,
  laststatus = 2,
  showtabline = 1,
}

M.cmd = function() end

-- Buffer-local vars table (flat, tests may reset)
M.b = {}

-- vim.fn stubs
M.fn = {
  -- Byte length fallback; tests needing grapheme width override this
  strdisplaywidth = function(s) return #tostring(s) end,
  has = function(_feature) return 0 end,
  fnamemodify = function(name, mod)
    if mod == ":t:r" then
      local base = name:match "([^/]+)$" or name
      base = base:gsub("%.lua$", "")
      return base
    end
    if mod == ":h" then
      -- parent dir: trim the final path component
      return (name:gsub("/[^/]*$", ""))
    end
    return name
  end,
  -- identity by default; tests may override
  expand = function(s) return s end,
  -- pessimistic by default so registry tests must stub the real fs
  isdirectory = function(_p) return 0 end,
  filereadable = function(_p) return 0 end,
}

-- vim.fs stub. Default dir() yields nothing; tests override with a real listing.
M.fs = {
  dir = function(_path)
    return function() end
  end,
}

-- Fake uv timer. Captures the callback so tests can drive frames via :fire().
-- All instances are tracked in M._fake_timers; reset via M.reset_fake_timers() in before_each.
M._fake_timers = {}

local FakeTimer = {}
FakeTimer.__index = FakeTimer
function FakeTimer.new()
  local t = setmetatable({ started = false, closed = false, _cb = nil, _repeat = 0 }, FakeTimer)
  table.insert(M._fake_timers, t)
  return t
end
function FakeTimer:start(_timeout, repeat_ms, cb)
  self.started = true
  self._cb = cb
  self._repeat = repeat_ms or 0
end
function FakeTimer:stop() self.started = false end
function FakeTimer:close()
  self.closed = true
  self.started = false
end
function FakeTimer:is_closing() return self.closed end
function FakeTimer:is_active() return self.started and not self.closed end
function FakeTimer:fire()
  if self._cb then self._cb() end
end

M.reset_fake_timers = function() M._fake_timers = {} end

M.uv = {
  new_timer = FakeTimer.new,
}

-- nvim api stubs (stateless; tests override to record/assert)
M.api = {
  nvim_create_buf = function(_listed, _scratch) return 1 end,
  nvim_buf_set_lines = function() end,
  nvim_open_win = function() return 1 end,
  nvim_win_close = function() end,
  nvim_win_is_valid = function() return true end,
  nvim_create_namespace = function(_name) return 1 end,
  nvim_buf_add_highlight = function() end,
  nvim_create_user_command = function() end,
  nvim_del_user_command = function() end,
  nvim_get_commands = function() return {} end,
  nvim_create_autocmd = function() return 1 end,
  nvim_create_augroup = function() return 1 end,
  nvim_buf_get_var = function() return nil end,
  nvim_buf_set_var = function() end,
  nvim_get_runtime_file = function() return {} end,
  nvim_list_tabpages = function() return { 1 } end,
  -- delegate module resolution to real nvim so `require("goofy.*")` works post-mock
  nvim__get_runtime = _real_api.nvim__get_runtime or function() return {} end,
}

-- Pass through real nvim helpers used by plenary.busted after _G.vim is mocked.
M.deepcopy = _real.deepcopy or function(x) return x end
M.inspect = _real.inspect or function(x) return tostring(x) end

return M
