describe("animator", function()
  local animator

  before_each(function()
    package.loaded["goofy.engine.animator"] = nil
    _G.vim = require "tests.mock_vim"
    animator = require "goofy.engine.animator"
  end)

  describe("register_strategy", function()
    it("registers a custom strategy module", function()
      local my_strategy = { play = function() end, validate = function() end }
      animator.register_strategy("my_custom", my_strategy)
      assert.are.equal(my_strategy, animator.get_strategy "my_custom")
    end)

    it("errors when name is not a string", function()
      assert.has.errors(function()
        animator.register_strategy(123, { play = function() end })
      end)
    end)

    it("errors when module has no play() function", function()
      assert.has.errors(function() animator.register_strategy("no_play", {}) end)
    end)
  end)

  describe("play", function()
    it("looks up the strategy by anim.type and calls its play()", function()
      local played = false
      local my_strategy = { play = function(anim, opts, cb) played = true end }
      animator.register_strategy("test_play_strategy", my_strategy)

      animator.play({ type = "test_play_strategy", frames = {} }, {}, nil)
      assert.is_true(played)
    end)

    it("asserts on unknown animation type", function()
      assert.has.errors(function() animator.play({ type = "nonexistent" }, {}, nil) end)
    end)

    it("defaults to keyframe when type is omitted", function()
      local played = false
      animator.register_strategy("keyframe", { play = function() played = true end, validate = function() end })
      animator.play({ frames = {} }, {}, nil)
      assert.is_true(played)
    end)

    it("calls strategy.validate before play when present", function()
      local validated = false
      animator.register_strategy("with_validation", {
        validate = function() validated = true end,
        play = function() end,
      })
      animator.play({ type = "with_validation" }, {}, nil)
      assert.is_true(validated)
    end)
  end)
end)
