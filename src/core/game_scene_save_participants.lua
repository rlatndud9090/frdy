local RunStateRegistry = require('src.core.run_state_registry')
local RunSaveValidators = require('src.core.run_save_validators')

---@class GameSceneSaveRuntime
---@field get_rng_snapshot fun(): RunContextSnapshot
---@field restore_rng_snapshot fun(snapshot: RunContextSnapshot): boolean
---@field snapshot_map_progress fun(): table
---@field restore_map_progress fun(snapshot: table): nil
---@field hero Hero
---@field spell_book SpellBook
---@field mana_manager ManaManager
---@field suspicion_manager SuspicionManager
---@field reward_manager RewardManager

---@class GameSceneSaveParticipants
local GameSceneSaveParticipants = {}

local EXPECTED_KEYS = {
  'run_context',
  'map_progress',
  'hero',
  'spell_book',
  'mana',
  'suspicion',
  'reward',
}

---@return string[]
function GameSceneSaveParticipants.expected_keys()
  local keys = {}
  for index, key in ipairs(EXPECTED_KEYS) do
    keys[index] = key
  end
  return keys
end

---@param label string
---@param validator fun(snapshot: any): table|nil
---@return fun(snapshot: any): table|nil, string|nil
local function wrap_validator(label, validator)
  return function(snapshot)
    local sanitized = validator(snapshot)
    if sanitized == nil then
      return nil, label .. ' 상태가 올바르지 않습니다.'
    end
    return sanitized, nil
  end
end

---@param runtime GameSceneSaveRuntime
---@return RunStateRegistry
function GameSceneSaveParticipants.build_registry(runtime)
  local registry = RunStateRegistry:new()

  registry:register({
    key = 'run_context',
    snapshot = function()
      return runtime.get_rng_snapshot()
    end,
    validate = wrap_validator('run_context', RunSaveValidators.run_context),
    restore = function(snapshot)
      return runtime.restore_rng_snapshot(snapshot), nil
    end,
  })
  registry:register({
    key = 'map_progress',
    snapshot = function()
      return runtime.snapshot_map_progress()
    end,
    validate = wrap_validator('map_progress', RunSaveValidators.map_progress),
    restore = function(snapshot)
      runtime.restore_map_progress(snapshot)
      return true, nil
    end,
  })
  registry:register({
    key = 'hero',
    snapshot = function()
      return runtime.hero:persistent_snapshot()
    end,
    validate = wrap_validator('hero', RunSaveValidators.hero),
    restore = function(snapshot)
      runtime.hero:restore_persistent_snapshot(snapshot)
      return true, nil
    end,
  })
  registry:register({
    key = 'spell_book',
    snapshot = function()
      return runtime.spell_book:snapshot()
    end,
    validate = wrap_validator('spell_book', RunSaveValidators.spell_book),
    restore = function(snapshot)
      runtime.spell_book:restore(snapshot)
      return true, nil
    end,
  })
  registry:register({
    key = 'mana',
    snapshot = function()
      return runtime.mana_manager:snapshot()
    end,
    validate = wrap_validator('mana', RunSaveValidators.mana),
    restore = function(snapshot)
      runtime.mana_manager:restore_snapshot(snapshot)
      return true, nil
    end,
  })
  registry:register({
    key = 'suspicion',
    snapshot = function()
      return runtime.suspicion_manager:snapshot()
    end,
    validate = wrap_validator('suspicion', RunSaveValidators.suspicion),
    restore = function(snapshot)
      runtime.suspicion_manager:restore_snapshot(snapshot)
      return true, nil
    end,
  })
  registry:register({
    key = 'reward',
    snapshot = function()
      return runtime.reward_manager:snapshot()
    end,
    validate = wrap_validator('reward', RunSaveValidators.reward),
    restore = function(snapshot)
      runtime.reward_manager:restore(snapshot)
      runtime.reward_manager:set_runtime_refs(
        runtime.hero,
        runtime.spell_book,
        runtime.mana_manager,
        runtime.suspicion_manager
      )
      return true, nil
    end,
  })

  return registry
end

return GameSceneSaveParticipants
