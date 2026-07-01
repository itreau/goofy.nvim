local registry

local tmp_root = (os.getenv "TMPDIR" or "/tmp") .. "/goofy_regtest_" .. tostring(os.time())

-- real-ish fs stubs backed by shell so registry's loadfile + reads work
local function shok(cmd)
  local r = os.execute(cmd)
  return r == 0 or r == true
end

local function install_fs_stubs(runtime_files)
  _G.vim.fn.expand = function(s) return s end
  _G.vim.fn.isdirectory = function(p) return shok("test -d '" .. p .. "'") and 1 or 0 end
  _G.vim.fn.filereadable = function(p) return shok("test -f '" .. p .. "'") and 1 or 0 end
  _G.vim.fs.dir = function(path)
    local f = io.popen("ls -A '" .. path .. "'")
    local entries = {}
    if f then
      for line in f:lines() do
        table.insert(entries, line)
      end
      f:close()
    end
    local i = 0
    return function()
      i = i + 1
      return entries[i]
    end
  end
  _G.vim.api.nvim_get_runtime_file = function(_pat, _all) return runtime_files or {} end
end

local function make_anim(folder, spec_src, frames)
  os.execute("mkdir -p '" .. folder .. "/frames'")
  local f = io.open(folder .. "/animation.lua", "w")
  f:write("return " .. spec_src .. "\n")
  f:close()
  for i, content in ipairs(frames) do
    local ff = io.open(folder .. "/frames/" .. i .. ".txt", "w")
    ff:write(content)
    ff:close()
  end
end

local function notify_capture()
  local msgs = {}
  _G.vim.notify = function(msg, level) table.insert(msgs, { msg = msg, level = level }) end
  return msgs
end

describe("registry (folder layout)", function()
  before_each(function()
    os.execute("rm -rf '" .. tmp_root .. "'")
    os.execute("mkdir -p '" .. tmp_root .. "'")
    package.loaded["goofy.registry"] = nil
    _G.vim = require "tests.mock_vim"
    install_fs_stubs {}
    registry = require "goofy.registry"
  end)

  after_each(function() os.execute("rm -rf '" .. tmp_root .. "'") end)

  describe("load", function()
    it("builds entries from runtime animation.lua folders", function()
      local a = tmp_root .. "/anim_a"
      local b = tmp_root .. "/anim_b"
      make_anim(a, '{ name = "alpha", delay = 200 }', { "Saving.\n", "Saving..\n", "Saving...\n" })
      make_anim(b, '{ name = "beta", type = "swipe", duration = 500, direction = "left" }', { "hello\nworld\n" })
      install_fs_stubs { a .. "/animation.lua", b .. "/animation.lua" }

      registry.load {}
      assert.are.same({ "alpha", "beta" }, registry.list())
    end)

    it("skips animation.lua missing required 'name' (warns)", function()
      local a = tmp_root .. "/no_name"
      make_anim(a, "{ delay = 100 }", { "x\n" })
      install_fs_stubs { a .. "/animation.lua" }
      local msgs = notify_capture()

      registry.load {}
      assert.are.same({}, registry.list())
      assert.is_true(#msgs > 0)
      assert.is_truthy(msgs[1].msg:find("name", 1, true))
    end)

    it("warns on duplicate built-in names and keeps first", function()
      local a = tmp_root .. "/dup_a"
      local b = tmp_root .. "/dup_b"
      make_anim(a, '{ name = "same", delay = 1 }', { "1\n" })
      make_anim(b, '{ name = "same", delay = 2 }', { "2\n" })
      install_fs_stubs { a .. "/animation.lua", b .. "/animation.lua" }
      local msgs = notify_capture()

      registry.load {}
      assert.are.same({ "same" }, registry.list())
      assert.is_truthy(msgs[1].msg:find("duplicate built-in", 1, true))
    end)

    it("user animations_dir merges and overrides built-ins on collision (warns)", function()
      local builtin = tmp_root .. "/builtin"
      local udir = tmp_root .. "/user_anims"
      make_anim(builtin, '{ name = "shared", delay = 10 }', { "old\n" })
      os.execute("mkdir -p '" .. udir .. "/shared/frames'")
      local f = io.open(udir .. "/shared/animation.lua", "w")
      f:write 'return { name = "shared", delay = 20 }\n'
      f:close()
      local ff = io.open(udir .. "/shared/frames/1.txt", "w")
      ff:write "new\n"
      ff:close()
      install_fs_stubs { builtin .. "/animation.lua" }
      _G.vim.fn.isdirectory = function(p) return shok("test -d '" .. p .. "'") and 1 or 0 end
      local msgs = notify_capture()

      registry.load { animations_dir = udir }
      assert.are.same({ "shared" }, registry.list())
      local anim = registry.get "shared"
      assert.is_not_nil(anim)
      assert.are.same({ "new" }, anim.frames[1])
      assert.is_truthy(msgs[1].msg:find("overrides built-in", 1, true))
    end)

    it("warns when animations_dir does not exist", function()
      local msgs = notify_capture()
      registry.load { animations_dir = tmp_root .. "/does_not_exist" }
      assert.are.same({}, registry.list())
      assert.is_truthy(msgs[1].msg:find("animations_dir not found", 1, true))
    end)
  end)

  describe("get", function()
    it("loads frames in numeric order and caches", function()
      local a = tmp_root .. "/ordered"
      make_anim(a, '{ name = "ordered", delay = 50 }', { "one\n", "two\n", "three\n" })
      install_fs_stubs { a .. "/animation.lua" }
      registry.load {}

      local anim = registry.get "ordered"
      assert.is_not_nil(anim)
      assert.are.equal(3, #anim.frames)
      assert.are.same({ "one" }, anim.frames[1])
      assert.are.same({ "two" }, anim.frames[2])
      assert.are.same({ "three" }, anim.frames[3])

      -- cached (same table identity on second call)
      local again = registry.get "ordered"
      assert.are.equal(anim, again)
    end)

    it("preserves multi-line frame content (heredoc-style)", function()
      local a = tmp_root .. "/multi"
      make_anim(
        a,
        '{ name = "multi", type = "swipe", duration = 100, direction = "left" }',
        { "line1\nline2\nline3\n" }
      )
      install_fs_stubs { a .. "/animation.lua" }
      registry.load {}

      local anim = registry.get "multi"
      assert.is_not_nil(anim)
      assert.are.same({ "line1", "line2", "line3" }, anim.frames[1])
    end)

    it("errors on non-contiguous frame files", function()
      local a = tmp_root .. "/gap"
      make_anim(a, '{ name = "gap", delay = 50 }', { "one\n", "two\n" })
      -- add a frame 4.txt without 3.txt
      os.execute("mkdir -p '" .. a .. "/frames'")
      local ff = io.open(a .. "/frames/4.txt", "w")
      ff:write "four\n"
      ff:close()
      install_fs_stubs { a .. "/animation.lua" }
      local msgs = notify_capture()
      registry.load {}

      local anim = registry.get "gap"
      assert.is_nil(anim)
      assert.is_truthy(msgs[1].msg:find("non-contiguous", 1, true))

      -- negative-cached: a second call stays nil without a fresh error
      local warned2 = #msgs
      assert.is_nil(registry.get "gap")
      assert.are.equal(warned2, #msgs)
    end)

    it("returns nil + error when frames/ directory is missing", function()
      local a = tmp_root .. "/noframes"
      os.execute("mkdir -p '" .. a .. "'")
      local f = io.open(a .. "/animation.lua", "w")
      f:write 'return { name = "noframes", delay = 50 }\n'
      f:close()
      install_fs_stubs { a .. "/animation.lua" }
      local msgs = notify_capture()
      registry.load {}

      assert.is_nil(registry.get "noframes")
      assert.is_truthy(msgs[1].msg:find("missing frames", 1, true))
    end)

    it("ignores non-integer .txt files in frames/", function()
      local a = tmp_root .. "/mixed"
      make_anim(a, '{ name = "mixed", delay = 50 }', { "real1\n", "real2\n" })
      os.execute("mkdir -p '" .. a .. "/frames'")
      local extra = io.open(a .. "/frames/notes.txt", "w")
      extra:write "ignore me\n"
      extra:close()
      local extra2 = io.open(a .. "/frames/readme.md.txt", "w")
      extra2:write "ignore me too\n"
      extra2:close()
      install_fs_stubs { a .. "/animation.lua" }
      registry.load {}

      local anim = registry.get "mixed"
      assert.is_not_nil(anim)
      assert.are.equal(2, #anim.frames)
      assert.are.same({ "real1" }, anim.frames[1])
    end)

    it("returns nil for unknown animation name", function()
      registry.load {}
      assert.is_nil(registry.get "does_not_exist")
    end)

    it("still serves test-injected animations from M.animations", function()
      local a = tmp_root .. "/injected"
      make_anim(a, '{ name = "injected", delay = 5 }', { "x\n" })
      install_fs_stubs { a .. "/animation.lua" }
      registry.load {}

      local fake = { frames = { { "fake" } }, delay = 999 }
      registry.animations["injected"] = fake
      assert.are.equal(fake, registry.get "injected")
    end)
  end)
end)
