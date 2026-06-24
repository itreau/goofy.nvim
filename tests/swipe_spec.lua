describe("swipe strategy", function()
  local swipe

  before_each(function()
    package.loaded["goofy.utils"] = nil
    package.loaded["goofy.engine.window"] = nil
    package.loaded["goofy.engine.playback"] = nil
    package.loaded["goofy.engine.strategies.swipe"] = nil
    _G.vim = require "tests.mock_vim"
    vim.reset_fake_timers()
    swipe = require "goofy.engine.strategies.swipe"
  end)

  describe("validate", function()
    it("passes with valid swipe animation", function()
      local anim = {
        frames = { "frame1" },
        duration = 500,
        direction = "left",
      }
      assert.has_no.errors(function() swipe.validate(anim) end)
    end)

    it("passes with heredoc frame", function()
      local anim = {
        frames = {
          [[
  ___
 /   \
|  W  |
 \___/
          ]],
        },
        duration = 500,
        direction = "right",
      }
      assert.has_no.errors(function() swipe.validate(anim) end)
    end)

    it("passes with all supported directions", function()
      local directions = { "left", "right", "up", "down" }
      for _, dir in ipairs(directions) do
        local anim = {
          frames = { "frame" },
          duration = 500,
          direction = dir,
        }
        assert.has_no.errors(function() swipe.validate(anim) end)
      end
    end)

    it("fails when direction is missing", function()
      local anim = {
        frames = { "frame1" },
        duration = 500,
      }
      assert.has.errors(function() swipe.validate(anim) end)
    end)

    it("fails when duration is missing", function()
      local anim = {
        frames = { "frame1" },
        direction = "left",
      }
      assert.has.errors(function() swipe.validate(anim) end)
    end)

    it("fails when frames is missing", function()
      local anim = {
        duration = 500,
        direction = "left",
      }
      assert.has.errors(function() swipe.validate(anim) end)
    end)

    it("fails with unsupported direction", function()
      local anim = {
        frames = { "frame1" },
        duration = 500,
        direction = "diagonal",
      }
      assert.has.errors(function() swipe.validate(anim) end)
    end)

    it("fails with nil direction", function()
      local anim = {
        frames = { "frame1" },
        duration = 500,
        direction = nil,
      }
      assert.has.errors(function() swipe.validate(anim) end)
    end)
  end)

  describe("play", function()
    local function last_timer() return vim._fake_timers[#vim._fake_timers] end

    local function capture_frames()
      local frames = {}
      vim.api.nvim_buf_set_lines = function(buf, _, _, _, lines) table.insert(frames, lines) end
      vim.api.nvim_open_win = function() return 1 end
      return frames
    end

    it("left direction scrolls content left (exit left)", function()
      local frames = capture_frames()
      -- width 3, height 1, duration = 3 * 16 -> num_frames 3, shift_per_frame 1
      swipe.play({ direction = "left", duration = 48, frames = { "AAA" } }, {}, function() end)
      local timer = last_timer()

      timer:fire() -- shift 0
      timer:fire() -- shift 1
      timer:fire() -- shift 2
      timer:fire() -- current_shift >= total_shifts -> close

      assert.are.same({ "AAA" }, frames[1])
      assert.are.same({ "AA " }, frames[2])
      assert.are.same({ "A  " }, frames[3])
    end)

    it("up direction scrolls content up (exit top)", function()
      local frames = capture_frames()
      swipe.play({ direction = "up", duration = 48, frames = { { "AAA", "BBB", "CCC" } } }, {}, function() end)
      local timer = last_timer()

      timer:fire() -- shift 0
      timer:fire() -- shift 1
      timer:fire() -- shift 2
      timer:fire() -- close

      assert.are.same({ "AAA", "BBB", "CCC" }, frames[1])
      assert.are.same({ "BBB", "CCC", "   " }, frames[2])
      assert.are.same({ "CCC", "   ", "   " }, frames[3])
    end)

    it("down direction scrolls content down (exit bottom)", function()
      local frames = capture_frames()
      swipe.play({ direction = "down", duration = 48, frames = { { "AAA", "BBB", "CCC" } } }, {}, function() end)
      local timer = last_timer()

      timer:fire() -- shift 0
      timer:fire() -- shift 1
      timer:fire() -- shift 2
      timer:fire() -- close

      assert.are.same({ "AAA", "BBB", "CCC" }, frames[1])
      assert.are.same({ "   ", "AAA", "BBB" }, frames[2])
      assert.are.same({ "   ", "   ", "AAA" }, frames[3])
    end)

    it("right direction scrolls content right (exit right)", function()
      local frames = capture_frames()
      swipe.play({ direction = "right", duration = 48, frames = { "AAA" } }, {}, function() end)
      local timer = last_timer()

      timer:fire()
      timer:fire()
      timer:fire()
      timer:fire()

      assert.are.same({ "AAA" }, frames[1])
      assert.are.same({ " AA" }, frames[2])
      assert.are.same({ "  A" }, frames[3])
    end)

    it("clamps sub-FRAME_DELAY duration to a single frame then closes", function()
      local frames = capture_frames()
      local completed = false
      swipe.play({ direction = "left", duration = 5, frames = { "AAAA" } }, {}, function() completed = false end)
      local timer = last_timer()

      timer:fire() -- shift 0 rendered
      timer:fire() -- current_shift >= width(4) -> close

      assert.are.equal(1, #frames)
      assert.is_true(timer.closed)
    end)

    it("calls on_complete and closes when the swipe completes", function()
      capture_frames()
      local completed = false
      swipe.play({ direction = "left", duration = 48, frames = { "AAA" } }, {}, function() completed = true end)
      local timer = last_timer()

      timer:fire()
      timer:fire()
      timer:fire()
      timer:fire() -- close

      assert.is_true(completed)
      assert.is_true(timer.closed)
    end)

    it("cleans up and calls on_complete when open fails", function()
      vim.api.nvim_create_buf = function() error "boom" end
      local completed = false
      swipe.play({ direction = "left", duration = 48, frames = { "AAA" } }, {}, function() completed = true end)
      local timer = last_timer()
      timer:fire()
      assert.is_true(completed)
      assert.is_true(timer.closed)
    end)
  end)
end)
