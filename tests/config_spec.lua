describe("config", function()
  local config

  before_each(function()
    package.loaded["goofy.config"] = nil
    _G.vim = require "tests.mock_vim"
    config = require "goofy.config"
  end)

  describe("validate", function()
    it("accepts nil (no user_opts)", function()
      assert.has_no.errors(function() config.validate(nil) end)
    end)

    it("accepts a known full config", function()
      assert.has_no.errors(
        function()
          config.validate {
            window = { border = "rounded", position = "center" },
            animation = { delay = 30, sequence_delay = 0 },
            animations = {},
          }
        end
      )
    end)

    it("errors when top-level opts is not a table", function()
      assert.has.errors(function() config.validate "foo" end)
    end)

    it("errors when window is not a table", function()
      assert.has.errors(function() config.validate { window = "foo" } end)
    end)

    it("errors when window.border is not a string/table", function()
      assert.has.errors(function() config.validate { window = { border = 123 } } end)
    end)

    it("errors when animation.delay is negative", function()
      assert.has.errors(function() config.validate { animation = { delay = -1 } } end)
    end)

    it("errors when animations_dir is not a string", function()
      assert.has.errors(function() config.validate { animations_dir = 123 } end)
    end)

    it("accepts animations_dir as a string", function()
      assert.has_no.errors(function() config.validate { animations_dir = "~/goofy/anims" } end)
    end)

    it("errors when animations is not a table", function()
      assert.has.errors(function() config.validate { animations = "foo" } end)
    end)

    it("warns on unknown top-level keys", function()
      local warned = {}
      vim.notify = function(msg, level) table.insert(warned, msg) end
      config.validate { bogus = true }
      assert.is_true(#warned > 0)
      assert.is_truthy(warned[1]:find "bogus")
    end)
  end)

  describe("merge", function()
    it("uses defaults when no user_opts given", function()
      local merged = config.merge(nil)
      assert.are.equal("rounded", merged.window.border)
      assert.are.equal(30, merged.animation.delay)
      assert.are.same({}, merged.animations)
    end)

    it("overrides defaults with user_opts (deep)", function()
      local merged = config.merge { window = { position = "top_left" }, animation = { delay = 100 } }
      assert.are.equal("rounded", merged.window.border)
      assert.are.equal("top_left", merged.window.position)
      assert.are.equal(100, merged.animation.delay)
      assert.is_nil(merged.animation.loop)
    end)

    it("validates before merging", function()
      assert.has.errors(function() config.merge { window = "nope" } end)
    end)
  end)
end)
