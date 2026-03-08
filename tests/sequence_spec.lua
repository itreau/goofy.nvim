describe("sequential animations", function()
	local dispatch
	local registry
	local animator

	before_each(function()
		package.loaded["goofy.dispatch"] = nil
		package.loaded["goofy.registry"] = nil
		package.loaded["goofy.engine.animator"] = nil
		_G.vim = require("tests.mock_vim")
		
		vim.notify = function() end
		vim.defer_fn = function(fn, delay)
			fn()
		end
		vim.tbl_deep_extend = function(mode, ...)
			local result = {}
			for i = 1, select("#", ...) do
				local t = select(i, ...)
				if t then
					for k, v in pairs(t) do
						result[k] = v
					end
				end
			end
			return result
		end
		
		dispatch = require("goofy.dispatch")
		registry = require("goofy.registry")
		animator = require("goofy.engine.animator")
	end)

	describe("fire", function()
		it("handles single animation string", function()
			local animation = { frames = { "test" }, delay = 100 }
			registry.animations = { test_anim = animation }

			local played = false
			animator.play = function(anim, opts, callback)
				played = true
				assert.are.same(animation, anim)
			end

			dispatch.fire("test_anim", {})
			assert.is_true(played)
		end)

		it("handles array of animation names", function()
			local anim1 = { frames = { "frame1" }, delay = 100 }
			local anim2 = { frames = { "frame2" }, delay = 100 }
			registry.animations = {
				anim1 = anim1,
				anim2 = anim2,
			}

			local played_animations = {}
			animator.play = function(anim, opts, callback)
				table.insert(played_animations, anim)
				if callback then
					callback()
				end
			end

			dispatch.fire({ "anim1", "anim2" }, {})
			assert.are.same({ anim1, anim2 }, played_animations)
		end)

		it("continues sequence when animation not found", function()
			local anim2 = { frames = { "frame2" }, delay = 100 }
			registry.animations = {
				anim2 = anim2,
			}

			local notified = false
			vim.notify = function(msg, level)
				notified = true
				assert.is_truthy(msg:find("not found"))
			end

			local played_animations = {}
			animator.play = function(anim, opts, callback)
				table.insert(played_animations, anim)
				if callback then
					callback()
				end
			end

			dispatch.fire({ "missing_anim", "anim2" }, {})
			assert.is_true(notified)
			assert.are.same({ anim2 }, played_animations)
		end)

		it("handles empty array", function()
			local played = false
			animator.play = function()
				played = true
			end

			dispatch.fire({}, {})
			assert.is_false(played)
		end)

		it("handles single-element array", function()
			local animation = { frames = { "test" }, delay = 100 }
			registry.animations = { test_anim = animation }

			local played = false
			animator.play = function(anim, opts, callback)
				played = true
				assert.are.same(animation, anim)
			end

			dispatch.fire({ "test_anim" }, {})
			assert.is_true(played)
		end)
	end)

	describe("play_sequence", function()
		it("plays animations in order", function()
			local anim1 = { frames = { "frame1" }, delay = 100 }
			local anim2 = { frames = { "frame2" }, delay = 100 }
			local anim3 = { frames = { "frame3" }, delay = 100 }
			registry.animations = {
				anim1 = anim1,
				anim2 = anim2,
				anim3 = anim3,
			}

			local played_order = {}
			animator.play = function(anim, opts, callback)
				if anim == anim1 then
					table.insert(played_order, 1)
				elseif anim == anim2 then
					table.insert(played_order, 2)
				elseif anim == anim3 then
					table.insert(played_order, 3)
				end
				if callback then
					callback()
				end
			end

			dispatch.play_sequence({ "anim1", "anim2", "anim3" }, {})
			assert.are.same({ 1, 2, 3 }, played_order)
		end)

		it("respects delay from context", function()
			local anim1 = { frames = { "frame1" }, delay = 100 }
			local anim2 = { frames = { "frame2" }, delay = 100 }
			registry.animations = {
				anim1 = anim1,
				anim2 = anim2,
			}

			local delays = {}
			vim.defer_fn = function(fn, delay)
				table.insert(delays, delay)
				fn()
			end

			local played_count = 0
			animator.play = function(anim, opts, callback)
				played_count = played_count + 1
				if callback then
					callback()
				end
			end

			dispatch.play_sequence({ "anim1", "anim2" }, { delay = 150 })
			assert.are.same({ 150 }, delays)
			assert.are.equal(2, played_count)
		end)

		it("uses zero delay when not specified", function()
			local anim1 = { frames = { "frame1" }, delay = 100 }
			local anim2 = { frames = { "frame2" }, delay = 100 }
			registry.animations = {
				anim1 = anim1,
				anim2 = anim2,
			}

			local delays = {}
			vim.defer_fn = function(fn, delay)
				table.insert(delays, delay)
				fn()
			end

			local played_count = 0
			animator.play = function(anim, opts, callback)
				played_count = played_count + 1
				if callback then
					callback()
				end
			end

			dispatch.play_sequence({ "anim1", "anim2" }, {})
			assert.are.same({ 0 }, delays)
			assert.are.equal(2, played_count)
		end)
	end)
end)
