local window = require "goofy.engine.window"
local playback = require "goofy.engine.playback"
local utils = require "goofy.utils"

local M = {}

function M.validate(anim)
  assert(anim.frames, "Keyframe animation requires `frames`")
  assert(anim.delay, "keyframe animation requires `delay`")
end

function M.play(anim, global_opts, on_complete)
  local frames = anim.frames
  local delay = anim.delay
  local opts = vim.tbl_deep_extend("force", global_opts or {}, anim.opts or {})

  local buf, win, timer
  local i = 1

  local function fail(err)
    vim.notify("Goofy: keyframe error: " .. tostring(err), vim.log.levels.ERROR)
    playback.close(buf, win, timer)
    if on_complete then on_complete() end
  end

  timer = vim.uv.new_timer()
  timer:start(
    0,
    delay,
    vim.schedule_wrap(function()
      if i > #frames then
        playback.close(buf, win, timer)
        if on_complete then on_complete() end
        return
      end

      local frame = utils.normalize_frame(frames[i])
      if not buf then
        local ok, err = pcall(function()
          buf, win = window.open(frame, opts)
        end)
        if not ok then
          fail(err)
          return
        end
      else
        local ok, err = pcall(window.render_frame, buf, frame, opts)
        if not ok then
          fail(err)
          return
        end
      end
      i = i + 1
    end)
  )
end

return M
