describe("init", function()
  local goofy

  before_each(function()
    package.loaded["goofy"] = nil
    package.loaded["goofy.config"] = nil
    package.loaded["goofy.normalize"] = nil
    package.loaded["goofy.hooks"] = nil
    package.loaded["goofy.hooks.init"] = nil
    package.loaded["goofy.registry"] = nil
    package.loaded["goofy.dispatch"] = nil
    _G.vim = require "tests.mock_vim"
    vim.reset_fake_timers()
  end)

  describe("version gate", function()
    it("errors when nvim version is below 0.10", function()
      vim.fn.has = function() return 0 end
      assert.has.errors(function()
        require "goofy"
        require("goofy").setup {}
      end)
    end)

    it("does not error when nvim version is 0.10+", function()
      vim.fn.has = function() return 1 end
      vim.api.nvim_create_augroup = function() return 1 end
      vim.api.nvim_create_autocmd = function() return 1 end
      vim.api.nvim_create_user_command = function() end
      assert.has_no.errors(function()
        require "goofy"
        require("goofy").setup { animations = {} }
      end)
    end)
  end)

  describe("public API", function()
    it("exposes play, fire, and play_sequence that delegate to dispatch", function()
      vim.fn.has = function() return 1 end
      vim.api.nvim_create_augroup = function() return 1 end
      vim.api.nvim_create_autocmd = function() return 1 end
      vim.api.nvim_create_user_command = function() end
      require "goofy"
      goofy = require "goofy"
      goofy.setup { animations = {} }

      assert.is_not_nil(goofy.play)
      assert.is_not_nil(goofy.fire)
      assert.is_not_nil(goofy.play_sequence)

      -- all three alias dispatch.fire / dispatch.play_sequence
      local dispatch = require "goofy.dispatch"
      assert.are.equal(dispatch.fire, goofy.play)
      assert.are.equal(dispatch.fire, goofy.fire)
      assert.are.equal(dispatch.play_sequence, goofy.play_sequence)
    end)
  end)
end)
