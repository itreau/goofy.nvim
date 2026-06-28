local strategies = {
  ["keyframe"] = require "goofy.engine.strategies.keyframe",
  ["swipe"] = require "goofy.engine.strategies.swipe",
}

local M = {}

function M.register_strategy(name, mod)
  assert(type(name) == "string", "strategy name must be a string")
  assert(type(mod) == "table" and type(mod.play) == "function", "strategy module must expose a play() function")
  strategies[name] = mod
end

function M.get_strategy(name) return strategies[name] end

function M.play(anim, global_opts, on_complete)
  local anim_type = anim.type or "keyframe"
  local strategy = strategies[anim_type]
  assert(strategy, "Unknown animation type: " .. tostring(anim_type))

  if strategy.validate then strategy.validate(anim) end
  strategy.play(anim, global_opts, on_complete)
end

return M
