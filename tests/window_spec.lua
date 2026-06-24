describe("window", function()
  local window

  before_each(function()
    package.loaded["goofy.engine.window"] = nil
    _G.vim = require "tests.mock_vim"
    window = require "goofy.engine.window"
  end)

  describe("open", function()
    it("uses vim.fn.strdisplaywidth for width calculation", function()
      vim.fn.strdisplaywidth = function() return 42 end
      local captured
      vim.api.nvim_open_win = function(buf, enter, config)
        captured = config
        return 1
      end
      window.open({ "x" }, {})
      assert.are.equal(42, captured.width)
    end)

    it("respects explicit opts.width over auto-calculation", function()
      vim.fn.strdisplaywidth = function() return 99 end
      local captured
      vim.api.nvim_open_win = function(_, _, config)
        captured = config
        return 1
      end
      window.open({ "x" }, { width = 10 })
      assert.are.equal(10, captured.width)
    end)

    it("warns on unknown position and falls back to bottom_right", function()
      local warned = {}
      vim.notify = function(msg, level) table.insert(warned, msg) end
      vim.api.nvim_open_win = function() return 1 end
      window.open({ "x" }, { position = "nowhere" })
      assert.is_true(#warned > 0)
      assert.is_truthy(warned[1]:find "nowhere")
    end)

    it("does not warn for known positions", function()
      local warned = false
      vim.notify = function() warned = true end
      vim.api.nvim_open_win = function() return 1 end
      for _, pos in ipairs {
        "top_left",
        "top_center",
        "top_right",
        "center",
        "left_center",
        "right_center",
        "bottom_left",
        "bottom_center",
        "bottom_right",
      } do
        warned = false
        window.open({ "x" }, { position = pos })
        assert.is_false(warned)
      end
    end)

    it("applies highlights via the goofy namespace on open", function()
      local calls = {}
      vim.api.nvim_buf_add_highlight = function(buf, _ns, hl, line, c0, c1)
        table.insert(calls, { ns = _ns, hl = hl, line = line })
      end
      vim.api.nvim_open_win = function() return 1 end
      window.open({ "a", "b" }, { color = "String" })
      assert.are.equal(2, #calls)
      assert.are.equal(window.ns, calls[1].ns)
      assert.are.equal("String", calls[1].hl)
      assert.are.equal(0, calls[1].line)
    end)

    it("skips highlights when color is nil", function()
      local calls = 0
      vim.api.nvim_buf_add_highlight = function() calls = calls + 1 end
      vim.api.nvim_open_win = function() return 1 end
      window.open({ "a" }, {})
      assert.are.equal(0, calls)
    end)
  end)

  describe("render_frame", function()
    it("sets lines then re-applies highlights each call", function()
      local set_calls = 0
      local hl_calls = 0
      vim.api.nvim_buf_set_lines = function() set_calls = set_calls + 1 end
      vim.api.nvim_buf_add_highlight = function() hl_calls = hl_calls + 1 end
      window.render_frame(1, { "a" }, { color = "Error" })
      assert.are.equal(1, set_calls)
      assert.are.equal(1, hl_calls)
    end)

    it("uses opts.height for highlight count when provided", function()
      local hl_calls = 0
      vim.api.nvim_buf_add_highlight = function() hl_calls = hl_calls + 1 end
      window.render_frame(1, { "a" }, { color = "Error", height = 5 })
      assert.are.equal(5, hl_calls)
    end)
  end)
end)
