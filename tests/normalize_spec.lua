describe("normalize", function()
  local normalize

  before_each(function()
    package.loaded["goofy.normalize"] = nil
    _G.vim = require "tests.mock_vim"
    normalize = require "goofy.normalize"
  end)

  describe("trigger detection", function()
    it("builds an autocmd hook from spec.trigger", function()
      local hooks = normalize.normalize {
        save_event = { trigger = "BufWritePost", animation = "write" },
      }
      assert.are.equal(1, #hooks)
      assert.are.equal("autocmd", hooks[1].type)
      assert.are.equal("BufWritePost", hooks[1].event)
      assert.are.equal("write", hooks[1].animation)
    end)

    it("builds a filetype hook from spec.filetype", function()
      local hooks = normalize.normalize {
        lua_files = { filetype = "lua", animation = "cool_glasses" },
      }
      assert.are.equal(1, #hooks)
      assert.are.equal("filetype", hooks[1].type)
      assert.are.equal("lua", hooks[1].ft)
    end)

    it("builds a command hook from spec.command", function()
      local hooks = normalize.normalize {
        write = { command = "w", animation = "write" },
      }
      assert.are.equal(1, #hooks)
      assert.are.equal("command", hooks[1].type)
      assert.are.equal("w", hooks[1].command)
    end)

    it("defaults animation name to the spec key when animation omitted", function()
      local hooks = normalize.normalize {
        cool_glasses = { command = "q" },
      }
      assert.are.equal("cool_glasses", hooks[1].animation)
    end)
  end)

  describe("missing trigger", function()
    it("warns and skips specs with no trigger", function()
      local warned = {}
      vim.notify = function(msg, level) table.insert(warned, { msg = msg, level = level }) end

      local hooks = normalize.normalize {
        broken = { animation = "write" },
      }

      assert.are.equal(0, #hooks)
      assert.are.equal(1, #warned)
      assert.is_truthy(warned[1].msg:find "broken")
      assert.are.equal(vim.log.levels.WARN, warned[1].level)
    end)

    it("still emits valid hooks alongside skipped ones", function()
      vim.notify = function() end
      local hooks = normalize.normalize {
        broken = { animation = "x" },
        good = { command = "w", animation = "write" },
      }
      assert.are.equal(1, #hooks)
      assert.are.equal("good", hooks[1].name)
    end)
  end)

  describe("full-spec passthrough", function()
    it("carries spec.delay into the hook", function()
      local hooks = normalize.normalize {
        celebrate = { command = "wq", animation = { "write", "cool_glasses" }, delay = 150 },
      }
      assert.are.equal(150, hooks[1].delay)
      assert.are.same({ "write", "cool_glasses" }, hooks[1].animation)
    end)

    it("carries spec.once into the hook", function()
      local hooks = normalize.normalize {
        lua_files = { filetype = "lua", animation = "cool_glasses", once = false },
      }
      assert.are.equal(false, hooks[1].once)
    end)

    it("carries spec.opts (per-hook window opts) into the hook", function()
      local opts = { position = "center", color = "String", width = 36 }
      local hooks = normalize.normalize {
        custom = { command = "w", animation = "write", opts = opts },
      }
      assert.are.equal("center", hooks[1].opts.position)
      assert.are.equal(36, hooks[1].opts.width)
    end)

    it("does not mutate the user-supplied spec table", function()
      local spec = { command = "w", animation = "write", delay = 100 }
      normalize.normalize { write_hook = spec }
      assert.are.equal(100, spec.delay)
      assert.is_nil(spec.name)
      assert.is_nil(spec.type)
    end)
  end)
end)
