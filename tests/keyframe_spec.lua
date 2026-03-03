describe("keyframe strategy", function()
  local keyframe
  
  before_each(function()
    package.loaded["goofy.utils"] = nil
    package.loaded["goofy.engine.strategies.keyframe"] = nil
    _G.vim = require("tests.mock_vim")
    keyframe = require("goofy.engine.strategies.keyframe")
  end)
  
  describe("validate", function()
    it("passes with valid keyframe animation", function()
      local anim = {
        frames = { "frame1", "frame2" },
        delay = 100,
      }
      assert.has_no.errors(function()
        keyframe.validate(anim)
      end)
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
      assert.has_no.errors(function()
        keyframe.validate(anim)
      end)
    end)
    
    it("fails when frames is missing", function()
      local anim = {
        delay = 100,
      }
      assert.has.errors(function()
        keyframe.validate(anim)
      end)
    end)
    
    it("fails when delay is missing", function()
      local anim = {
        frames = { "frame1" },
      }
      assert.has.errors(function()
        keyframe.validate(anim)
      end)
    end)
    
    it("fails when frames is nil", function()
      local anim = {
        frames = nil,
        delay = 100,
      }
      assert.has.errors(function()
        keyframe.validate(anim)
      end)
    end)
  end)
end)
