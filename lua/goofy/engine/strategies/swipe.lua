local window = require "goofy.engine.window"
local playback = require "goofy.engine.playback"
local utils = require "goofy.utils"

local M = {}

local FRAME_DELAY = 16

-- Vector sign is a branch selector, not a screen-space vector.
--   up   = { y =  1 }  -> drop top line, append empty at bottom  -> content scrolls UP
--   down = { y = -1 }  -> prepend empty on top, drop bottom line -> content scrolls DOWN
-- Verified against the shift_frame branches below.
local DIRECTIONS = {
  left = { x = 1, y = 0 },
  right = { x = -1, y = 0 },
  up = { x = 0, y = 1 },
  down = { x = 0, y = -1 },
}

local function get_frame_dimensions(lines)
  local max_width = 0
  for _, line in ipairs(lines) do
    local len = vim.fn.strdisplaywidth(line)
    if len > max_width then max_width = len end
  end
  return max_width, #lines
end

local function shift_frame(lines, shift, dir, width)
  local result = {}
  local num_lines = #lines
  local empty_line = string.rep(" ", width)

  if dir.x ~= 0 then
    for _, line in ipairs(lines) do
      local padded
      if dir.x > 0 then
        padded = line .. empty_line
      else
        padded = empty_line .. line
      end
      local start = dir.x > 0 and (shift + 1) or (width - shift + 1)
      table.insert(result, padded:sub(start, start + width - 1))
    end
  else
    if dir.y > 0 then
      for i = shift + 1, num_lines do
        table.insert(result, lines[i])
      end
      for _ = 1, math.min(shift, num_lines) do
        table.insert(result, empty_line)
      end
    else
      for _ = 1, math.min(shift, num_lines) do
        table.insert(result, empty_line)
      end
      for i = 1, num_lines - math.min(shift, num_lines) do
        table.insert(result, lines[i])
      end
    end
  end

  return result
end

function M.validate(anim)
  assert(anim.direction, "`direction` required for swipe animation type.")
  assert(DIRECTIONS[anim.direction], "Swipe direction not supported: " .. tostring(anim.direction))
  assert(anim.duration, "`duration` required for swipe animation type.")
  assert(anim.frames, "`frames` required for swipe animation type.")
end

function M.play(anim, global_opts, on_complete)
  local dir = DIRECTIONS[anim.direction]
  local duration = anim.duration
  local opts = vim.tbl_deep_extend("force", global_opts or {}, anim.opts or {})

  local frame = utils.normalize_frame(anim.frames[1])
  local width, height = get_frame_dimensions(frame)
  width = math.max(1, width)
  height = math.max(1, height)

  local total_shifts = (dir.x ~= 0) and width or height
  total_shifts = math.max(1, total_shifts)
  local num_frames = math.max(1, math.floor(duration / FRAME_DELAY))
  local shift_per_frame = total_shifts / num_frames

  local buf, win, timer
  local current_shift = 0
  local closing = false

  local function fail(err)
    vim.notify("Goofy: swipe error: " .. tostring(err), vim.log.levels.ERROR)
    playback.close(buf, win, timer)
    if on_complete then on_complete() end
  end

  timer = vim.uv.new_timer()
  timer:start(
    0,
    FRAME_DELAY,
    vim.schedule_wrap(function()
      if closing then return end

      if current_shift >= total_shifts then
        closing = true
        playback.close(buf, win, timer)
        if on_complete then on_complete() end
        return
      end

      local shifted_frame = shift_frame(frame, math.floor(current_shift), dir, width)

      if not buf then
        local ok, err = pcall(function()
          buf, win = window.open(shifted_frame, opts)
        end)
        if not ok then
          closing = true
          fail(err)
          return
        end
      else
        local ok, err = pcall(window.render_frame, buf, shifted_frame, opts)
        if not ok then
          closing = true
          fail(err)
          return
        end
      end

      current_shift = current_shift + shift_per_frame
    end)
  )
end

return M
