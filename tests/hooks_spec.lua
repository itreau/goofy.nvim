describe("hooks", function()
  local hooks
  local autocmd
  local command
  local filetype

  before_each(function()
    package.loaded["goofy.hooks.init"] = nil
    package.loaded["goofy.hooks.autocmd"] = nil
    package.loaded["goofy.hooks.command"] = nil
    package.loaded["goofy.hooks.filetype"] = nil
    package.loaded["goofy.dispatch"] = nil
    _G.vim = require "tests.mock_vim"
    vim.reset_fake_timers()

    hooks = require "goofy.hooks"
    autocmd = require "goofy.hooks.autocmd"
    command = require "goofy.hooks.command"
    filetype = require "goofy.hooks.filetype"
  end)

  describe("register_all augroup", function()
    it("creates a clearable Goofy augroup and passes it to autocmds", function()
      local created_groups = {}
      local autocmd_calls = {}
      vim.api.nvim_create_augroup = function(name, opts)
        created_groups[name] = opts
        return 42
      end
      vim.api.nvim_create_autocmd = function(event, opts)
        table.insert(autocmd_calls, { event = event, group = opts.group })
        return 1
      end
      vim.api.nvim_create_user_command = function() end

      hooks.register_all {
        { type = "autocmd", event = "BufWritePost", animation = "write" },
      }

      assert.is_not_nil(created_groups["Goofy"])
      assert.is_true(created_groups["Goofy"].clear)
      assert.are.equal(42, autocmd_calls[1].group)
    end)

    it("clears the augroup on each register_all so re-setup dedupes", function()
      local clear_count = 0
      vim.api.nvim_create_augroup = function(_, opts)
        if opts.clear then clear_count = clear_count + 1 end
        return 1
      end
      vim.api.nvim_create_autocmd = function() return 1 end
      vim.api.nvim_create_user_command = function() end

      hooks.register_all {}
      hooks.register_all {}
      assert.are.equal(2, clear_count)
    end)
  end)

  describe("command.register forwarding", function()
    it("creates Goofy<cmd> proxy and forwards bang, range, count, args", function()
      local created_cmd
      local opts_captured
      vim.api.nvim_create_user_command = function(name, fn, opts)
        created_cmd = name
        opts_captured = opts
        -- store the callback so we can invoke it
        package.loaded["goofy.hooks.command"]._last_fn = fn
      end
      local cmd_called
      vim.api.nvim_cmd = function(spec) cmd_called = spec end
      local fired
      require("goofy.dispatch").fire = function(name, ctx) fired = { name = name, ctx = ctx } end

      command.register({ command = "w", animation = "write", delay = 100, opts = { position = "center" } }, nil, {})

      assert.are.equal("Goofyw", created_cmd)
      assert.is_true(opts_captured.bang)
      assert.is_true(opts_captured.range)
      assert.are.equal("*", opts_captured.nargs)
      assert.is_true(opts_captured.count)
      assert.is_true(opts_captured.force)

      package.loaded["goofy.hooks.command"]._last_fn {
        bang = true,
        range = 2,
        count = 2,
        fargs = { "foo.txt" },
      }

      assert.are.equal("w", cmd_called.cmd)
      assert.is_true(cmd_called.bang)
      assert.are.equal(2, cmd_called.range)
      assert.are.equal(2, cmd_called.count)
      assert.are.same({ "foo.txt" }, cmd_called.args)

      assert.are.equal("write", fired.name)
      assert.are.equal(100, fired.ctx.delay)
      assert.are.equal("center", fired.ctx.opts.position)
    end)

    it("warns on duplicate proxy command names (last-wins)", function()
      local warned = {}
      vim.notify = function(msg, level) table.insert(warned, msg) end
      vim.api.nvim_create_user_command = function() end

      -- register_all passes one shared seen_commands table across calls
      local seen = {}
      command.register({ command = "w", animation = "a" }, nil, seen)
      command.register({ command = "w", animation = "b" }, nil, seen)

      assert.are.equal(1, #warned)
      assert.is_truthy(warned[1]:find "Goofyw")
    end)

    it("does not warn on first registration of a unique command", function()
      local warned = false
      vim.notify = function() warned = true end
      vim.api.nvim_create_user_command = function() end

      command.register({ command = "w", animation = "a" }, nil, {})

      assert.is_false(warned)
    end)
  end)

  describe("filetype.register once-per-buffer", function()
    local function make_hook(once)
      return {
        type = "filetype",
        ft = "lua",
        animation = "cool_glasses",
        name = "lua_files",
        once = once,
      }
    end

    -- capture the FileType autocmd callback so we can drive it
    local function register_and_grab(hook)
      local captured
      vim.api.nvim_create_autocmd = function(event, opts)
        if event == "FileType" then captured = opts.callback end
        return 1
      end
      require("goofy.dispatch").fire = function() end
      filetype.register(hook, nil)
      return captured
    end

    it("default once=true: fires once per buffer then skips", function()
      local ft_cb = register_and_grab(make_hook(nil)) -- once defaults true
      local fired_count = 0
      require("goofy.dispatch").fire = function() fired_count = fired_count + 1 end

      -- shared per-buffer var store so get_var returns what set_var wrote
      local buf_vars = {}
      vim.api.nvim_buf_get_var = function(buf, key) return buf_vars[buf] and buf_vars[buf][key] or nil end
      vim.api.nvim_buf_set_var = function(buf, key, val)
        buf_vars[buf] = buf_vars[buf] or {}
        buf_vars[buf][key] = val
      end

      ft_cb { buf = 1 }
      ft_cb { buf = 1 } -- same buffer, should skip

      assert.are.equal(1, fired_count)
      assert.is_true(buf_vars[1]["goofy_played_lua_files"])
    end)

    it("once=false: fires every time the FileType autocmd triggers", function()
      local ft_cb = register_and_grab(make_hook(false))
      local fired_count = 0
      require("goofy.dispatch").fire = function() fired_count = fired_count + 1 end
      vim.api.nvim_buf_get_var = function() return nil end
      vim.api.nvim_buf_set_var = function() end

      ft_cb { buf = 1 }
      ft_cb { buf = 1 }
      ft_cb { buf = 1 }

      assert.are.equal(3, fired_count)
    end)

    it("registers a BufDelete cleanup that clears the per-buffer mark", function()
      local delete_registered = false
      vim.api.nvim_create_autocmd = function(event, opts)
        if event == "BufDelete" then delete_registered = true end
        return 1
      end
      require("goofy.dispatch").fire = function() end
      filetype.register(make_hook(nil), nil)
      assert.is_true(delete_registered)
    end)
  end)

  describe("autocmd.register carries spec.delay and spec.opts through ctx", function()
    it("builds ctx with delay and opts from the hook spec", function()
      local autocmd_cb
      vim.api.nvim_create_autocmd = function(_, opts) autocmd_cb = opts.callback end
      local fired
      require("goofy.dispatch").fire = function(name, ctx) fired = { name = name, ctx = ctx } end

      autocmd.register({
        type = "autocmd",
        event = "BufWritePost",
        animation = { "write", "cool_glasses" },
        delay = 150,
        opts = { position = "center", color = "String" },
      }, nil)

      autocmd_cb()
      assert.are.same({ "write", "cool_glasses" }, fired.name)
      assert.are.equal(150, fired.ctx.delay)
      assert.are.equal("center", fired.ctx.opts.position)
    end)
  end)
end)
