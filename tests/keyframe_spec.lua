describe("keyframe strategy", function()
  local keyframe

  before_each(function()
    package.loaded["goofy.utils"] = nil
    package.loaded["goofy.engine.window"] = nil
    package.loaded["goofy.engine.playback"] = nil
    package.loaded["goofy.engine.strategies.keyframe"] = nil
    _G.vim = require "tests.mock_vim"
    vim.reset_fake_timers()
    keyframe = require "goofy.engine.strategies.keyframe"
  end)

  describe("validate", function()
    it("passes with valid keyframe animation", function()
      local anim = {
        frames = { "frame1", "frame2" },
        delay = 100,
      }
      assert.has_no.errors(function() keyframe.validate(anim) end)
    end)

    it("passes with heredoc frames", function()
      local anim = {
        frames = {
          [[line1
line2]],
          [[line3
line4]],
        },
        delay = 100,
      }
      assert.has_no.errors(function() keyframe.validate(anim) end)
    end)

    it("fails when frames is missing", function()
      local anim = {
        delay = 100,
      }
      assert.has.errors(function() keyframe.validate(anim) end)
    end)

    it("fails when delay is missing", function()
      local anim = {
        frames = { "frame1" },
      }
      assert.has.errors(function() keyframe.validate(anim) end)
    end)

    it("fails when frames is nil", function()
      local anim = {
        frames = nil,
        delay = 100,
      }
      assert.has.errors(function() keyframe.validate(anim) end)
    end)
  end)

  describe("play", function()
    local function last_timer() return vim._fake_timers[#vim._fake_timers] end

    it("opens a window on first frame and updates buffer on subsequent frames", function()
      local opens = 0
      local set_lines_calls = 0
      vim.api.nvim_open_win = function()
        opens = opens + 1
        return 100
      end
      vim.api.nvim_buf_set_lines = function() set_lines_calls = set_lines_calls + 1 end

      keyframe.play({ frames = { "a", "b", "c" }, delay = 50 }, {}, function() end)
      local timer = last_timer()

      timer:fire() -- frame 1: open + set_lines
      assert.are.equal(1, opens)
      assert.are.equal(1, set_lines_calls)

      timer:fire() -- frame 2: update only
      assert.are.equal(1, opens)
      assert.are.equal(2, set_lines_calls)

      timer:fire() -- frame 3: update only
      assert.are.equal(3, set_lines_calls)
    end)

    it("calls on_complete and closes the window after the last frame", function()
      local closed = false
      vim.api.nvim_win_close = function() closed = true end
      vim.api.nvim_win_is_valid = function() return true end

      local completed = false
      keyframe.play({ frames = { "a", "b" }, delay = 10 }, {}, function() completed = true end)
      local timer = last_timer()

      timer:fire() -- frame 1
      timer:fire() -- frame 2
      timer:fire() -- i > #frames -> close + on_complete

      assert.is_true(closed)
      assert.is_true(completed)
      assert.is_true(timer.closed)
    end)

    it("cleans up and calls on_complete when open fails", function()
      vim.api.nvim_create_buf = function() error "boom" end
      local completed = false
      keyframe.play({ frames = { "a" }, delay = 10 }, {}, function() completed = true end)
      local timer = last_timer()

      timer:fire()

      assert.is_true(completed)
      assert.is_true(timer.closed)
    end)

    it("cleans up and calls on_complete when render_frame fails mid-animation", function()
      local set_calls = 0
      vim.api.nvim_buf_set_lines = function()
        set_calls = set_calls + 1
        if set_calls == 2 then error "render boom" end
      end
      vim.api.nvim_win_close = function() end
      vim.api.nvim_win_is_valid = function() return true end

      local completed = false
      keyframe.play({ frames = { "a", "b", "c" }, delay = 10 }, {}, function() completed = true end)
      local timer = last_timer()

      timer:fire() -- frame 1: open (ok)
      timer:fire() -- frame 2: render fails

      assert.is_true(completed)
      assert.is_true(timer.closed)
    end)
  end)
end)
