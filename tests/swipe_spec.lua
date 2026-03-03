describe("swipe strategy", function()
	local swipe

	before_each(function()
		package.loaded["goofy.utils"] = nil
		package.loaded["goofy.engine.strategies.swipe"] = nil
		_G.vim = require("tests.mock_vim")
		swipe = require("goofy.engine.strategies.swipe")
	end)

	describe("validate", function()
		it("passes with valid swipe animation", function()
			local anim = {
				frames = { "frame1" },
				duration = 500,
				direction = "left",
			}
			assert.has_no.errors(function()
				swipe.validate(anim)
			end)
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
			assert.has_no.errors(function()
				swipe.validate(anim)
			end)
		end)

		it("passes with all supported directions", function()
			local directions = { "left", "right", "up", "down" }
			for _, dir in ipairs(directions) do
				local anim = {
					frames = { "frame" },
					duration = 500,
					direction = dir,
				}
				assert.has_no.errors(function()
					swipe.validate(anim)
				end)
			end
		end)

		it("fails when direction is missing", function()
			local anim = {
				frames = { "frame1" },
				duration = 500,
			}
			assert.has.errors(function()
				swipe.validate(anim)
			end)
		end)

		it("fails when duration is missing", function()
			local anim = {
				frames = { "frame1" },
				direction = "left",
			}
			assert.has.errors(function()
				swipe.validate(anim)
			end)
		end)

		it("fails when frames is missing", function()
			local anim = {
				duration = 500,
				direction = "left",
			}
			assert.has.errors(function()
				swipe.validate(anim)
			end)
		end)

		it("fails with unsupported direction", function()
			local anim = {
				frames = { "frame1" },
				duration = 500,
				direction = "diagonal",
			}
			assert.has.errors(function()
				swipe.validate(anim)
			end)
		end)

		it("fails with nil direction", function()
			local anim = {
				frames = { "frame1" },
				duration = 500,
				direction = nil,
			}
			assert.has.errors(function()
				swipe.validate(anim)
			end)
		end)
	end)
end)
