---@module PatternResolver
--- Selects the best action pattern from a list based on conditions and priorities.

local ActionPattern = require('src.combat.action_pattern')

local PatternResolver = {}

--- Resolve the best pattern from a list
---@param patterns ActionPattern[]
---@param context table {actor, target, enemies, cooldown_tracker, current_turn}
---@return ActionPattern|nil
function PatternResolver.resolve(patterns, context)
  local best = nil
  local best_priority = -math.huge

  for _, pattern in ipairs(patterns) do
    if pattern:can_use(context) then
      -- "fallback" condition has lowest implicit priority unless explicitly high
      local effective_priority = pattern.priority
      if pattern.condition == "fallback" then
        effective_priority = effective_priority - 1000
      end

      if effective_priority > best_priority then
        best = pattern
        best_priority = effective_priority
      end
    end
  end

  return best
end

--- Resolve a sequence of actions (for prediction)
---@param patterns ActionPattern[]
---@param context table
---@param count number
---@return ActionPattern[]
function PatternResolver.resolve_sequence(patterns, context, count)
  local results = {}
  for _ = 1, count do
    local pattern = PatternResolver.resolve(patterns, context)
    if pattern then
      table.insert(results, pattern)
    end
  end
  return results
end

--- Convert legacy round-robin patterns to ActionPattern list
---@param legacy_patterns table[] Array of {type, damage_mult, defense_bonus}
---@return ActionPattern[]
function PatternResolver.from_legacy_list(legacy_patterns)
  local patterns = {}
  for i, data in ipairs(legacy_patterns) do
    table.insert(patterns, ActionPattern.from_legacy(data, i))
  end
  return patterns
end

return PatternResolver
