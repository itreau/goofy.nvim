local utils = require "goofy.utils"

local M = {}

-- name -> { dir = <abs folder containing animation.lua + frames/>, spec = <loaded anim table> }
M.entries = {}
-- name -> true (discovered names; drives M.list)
M.names = {}
-- resolved animation tables cache (also used by tests to inject synthetic anims)
M.animations = {}

local function read_file(path)
  local f, err = io.open(path, "r")
  if not f then return nil, err end
  local content = f:read "*a"
  f:close()
  return content
end

-- Strip exactly one trailing newline if present (POSIX final-newline convention).
local function strip_final_newline(s)
  if s and s:sub(-1) == "\n" then s = s:sub(1, -2) end
  return s
end

-- Load an animation.lua file via loadfile. Returns spec table or nil (+warn).
local function load_spec(path)
  local chunk, err = loadfile(path)
  if not chunk then
    vim.notify("goofy: failed to load animation spec: " .. tostring(err), vim.log.levels.WARN)
    return nil
  end
  local ok, spec = pcall(chunk)
  if not ok or type(spec) ~= "table" then
    vim.notify("goofy: animation.lua did not return a table: " .. path, vim.log.levels.WARN)
    return nil
  end
  if type(spec.name) ~= "string" then
    vim.notify("goofy: animation.lua missing required string field 'name': " .. path, vim.log.levels.WARN)
    return nil
  end
  return spec
end

local function register(name, dir, spec, is_user)
  if M.entries[name] then
    if is_user then
      vim.notify("goofy: user animation '" .. name .. "' overrides built-in (" .. dir .. ")", vim.log.levels.WARN)
    else
      vim.notify(
        "goofy: duplicate built-in animation name '" .. name .. "' (skipping " .. dir .. ")",
        vim.log.levels.WARN
      )
      return
    end
  end
  M.entries[name] = { dir = dir, spec = spec }
  M.names[name] = true
end

function M.load(opts)
  M.entries = {}
  M.names = {}
  M.animations = {}
  opts = opts or {}

  -- Built-in animations: scan runtimepath for .../lua/goofy/animations/<folder>/animation.lua
  if vim.api and vim.api.nvim_get_runtime_file then
    local files = vim.api.nvim_get_runtime_file("lua/goofy/animations/*/animation.lua", true)
    for _, file in ipairs(files) do
      local spec = load_spec(file)
      if spec then
        local dir = vim.fn.fnamemodify(file, ":h") -- parent folder of animation.lua
        register(spec.name, dir, spec, false)
      end
    end
  end

  -- User-supplied animations directory (merges over built-ins; user wins on collision).
  local udir = opts.animations_dir
  if udir then
    udir = vim.fn.expand(udir)
    if vim.fn.isdirectory(udir) == 1 then
      local iter = vim.fs and vim.fs.dir(udir)
      if iter then
        for name in iter do
          local anim_path = udir .. "/" .. name .. "/animation.lua"
          if vim.fn.filereadable(anim_path) == 1 then
            local spec = load_spec(anim_path)
            if spec then register(spec.name, udir .. "/" .. name, spec, true) end
          end
        end
      end
    else
      vim.notify("goofy: animations_dir not found or not a directory: " .. udir, vim.log.levels.WARN)
    end
  end
end

-- Load frame files for an animation from <dir>/frames/*.txt (1-based, contiguous).
local function build_frames(dir)
  local frames_dir = dir .. "/frames"
  if vim.fn.isdirectory(frames_dir) ~= 1 then return nil, "missing frames/ directory" end

  local indexed = {} -- numeric_stem -> file path
  local iter = vim.fs and vim.fs.dir(frames_dir)
  if not iter then return nil, "fs.dir unavailable" end
  for entry in iter do
    local stem = entry:match "^(%w+)%.[tT][xX][tT]$"
    stem = stem and tonumber(stem)
    if stem and stem >= 1 then indexed[stem] = frames_dir .. "/" .. entry end
  end

  local keys = {}
  for k in pairs(indexed) do
    table.insert(keys, k)
  end
  table.sort(keys)
  for i, k in ipairs(keys) do
    if k ~= i then return nil, "non-contiguous frame files (expected " .. i .. ".txt, got " .. k .. ".txt)" end
  end

  if #keys == 0 then return nil, "no .txt frame files found in frames/" end

  local frames = {}
  for _, k in ipairs(keys) do
    local content, err = read_file(indexed[k])
    if content == nil then return nil, "failed to read " .. indexed[k] .. ": " .. tostring(err) end
    frames[k] = utils.normalize_frame(strip_final_newline(content))
  end
  return frames, nil
end

function M.get(name)
  local cached = M.animations[name]
  if cached ~= nil then return cached or nil end

  local entry = M.entries[name]
  if not entry then return nil end

  local frames, err = build_frames(entry.dir)
  if not frames then
    vim.notify("goofy: animation '" .. name .. "': " .. err, vim.log.levels.ERROR)
    M.animations[name] = false -- negative cache
    return nil
  end

  local spec = vim.tbl_deep_extend("force", {}, entry.spec)
  spec.frames = frames
  M.animations[name] = spec
  return spec
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
