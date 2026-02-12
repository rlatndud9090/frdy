local class = require('lib.middleclass')
local PredictedAction = require('src.combat.predicted_action')

---@class PredictionEngine
---@field max_actions number
local PredictionEngine = class('PredictionEngine')

---@param max_actions? number
function PredictionEngine:initialize(max_actions)
  self.max_actions = max_actions or 20
end

--- Generate a predicted timeline by simulating combat
---@param hero Hero
---@param enemies Enemy[]
---@return PredictedAction[]
function PredictionEngine:generate_timeline(hero, enemies)
  -- Snapshot all entities
  local hero_snap = hero:snapshot()
  local enemy_snaps = {}
  for i, enemy in ipairs(enemies) do
    enemy_snaps[i] = enemy:snapshot()
  end

  local timeline = {}
  local action_count = 0

  local ok, err = pcall(function()
    -- Simulate alternating turns: hero → enemies → hero → enemies...
    while action_count < self.max_actions do
      -- Hero action
      if hero:is_alive() then
        local pattern = hero:choose_action({
          target = self:_get_first_living(enemies),
          enemies = self:_get_living(enemies),
        })
        if pattern then
          local target = self:_get_first_living(enemies)
          if target then
            local preview = pattern:get_preview(hero)
            table.insert(timeline, PredictedAction:new({
              actor = hero,
              pattern = pattern,
              action_type = pattern.type,
              target = target,
              value = preview.value,
              source_type = "hero",
              description = preview.description,
            }))
            action_count = action_count + 1

            -- Apply simulated effect
            pattern:execute(hero, target)
          end
        end

        -- Check if all enemies dead
        if #self:_get_living(enemies) == 0 then
          break
        end
      end

      -- Enemy actions
      for _, enemy in ipairs(enemies) do
        if enemy:is_alive() and action_count < self.max_actions then
          local pattern = enemy:choose_action({
            actor = enemy,
            target = hero,
          })
          if pattern then
            local preview = pattern:get_preview(enemy)
            table.insert(timeline, PredictedAction:new({
              actor = enemy,
              pattern = pattern,
              action_type = pattern.type,
              target = hero,
              value = preview.value,
              source_type = "enemy",
              description = enemy:get_name() .. ": " .. preview.description,
            }))
            action_count = action_count + 1

            -- Apply simulated effect
            if pattern.type == "attack" then
              pattern:execute(enemy, hero)
            elseif pattern.type == "defend" then
              pattern:execute(enemy, enemy)
            end
          end
        end
      end

      -- Check if hero dead
      if not hero:is_alive() then
        break
      end
    end
  end)

  if not ok then
    print("[PredictionEngine] Simulation error: " .. tostring(err))
  end

  -- Restore all entities
  hero:restore(hero_snap)
  for i, enemy in ipairs(enemies) do
    enemy:restore(enemy_snaps[i])
  end

  return timeline
end

--- Recalculate timeline from a given index with interventions
---@param hero Hero
---@param enemies Enemy[]
---@param interventions table[] List of {index, spell} to insert
---@return PredictedAction[]
function PredictionEngine:recalculate_with(hero, enemies, interventions)
  -- For now, regenerate the full timeline
  -- Future: partial recalculation from the earliest intervention point
  return self:generate_timeline(hero, enemies)
end

---@param entities Entity[]
---@return Entity|nil
function PredictionEngine:_get_first_living(entities)
  for _, e in ipairs(entities) do
    if e:is_alive() then return e end
  end
  return nil
end

---@param entities Entity[]
---@return Entity[]
function PredictionEngine:_get_living(entities)
  local living = {}
  for _, e in ipairs(entities) do
    if e:is_alive() then
      table.insert(living, e)
    end
  end
  return living
end

return PredictionEngine
