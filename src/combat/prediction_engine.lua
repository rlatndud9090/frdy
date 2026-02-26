local class = require('lib.middleclass')
local PredictedAction = require('src.combat.predicted_action')

---@class PredictionEngine
---@field max_actions number
local PredictionEngine = class('PredictionEngine')

---@param max_actions? number
function PredictionEngine:initialize(max_actions)
  -- 턴 단위 타임라인에서도 안전 장치로 액션 상한을 둔다.
  self.max_actions = max_actions or 20
end

--- Generate predicted actions for the current turn only.
---@param hero Hero
---@param enemies Enemy[]
---@return PredictedAction[]
function PredictionEngine:generate_timeline(hero, enemies)
  local hero_snap = hero:snapshot()
  local enemy_snaps = {}
  for i, enemy in ipairs(enemies) do
    enemy_snaps[i] = enemy:snapshot()
  end

  local timeline = {}
  local ok, err = pcall(function()
    local pending = self:_collect_turn_actors(hero, enemies)
    local steps = 0

    while #pending > 0 and steps < self.max_actions do
      steps = steps + 1

      local actor = self:_pick_next_actor(pending, hero, enemies)
      if not actor then
        break
      end
      self:_remove_actor_from_pending(pending, actor)

      local action = self:_build_actor_action(actor, hero, enemies)
      if action then
        timeline[#timeline + 1] = action
        self:_simulate_action(action, hero, enemies)
      end
    end
  end)

  if not ok then
    print('[PredictionEngine] Turn simulation error: ' .. tostring(err))
  end

  hero:restore(hero_snap)
  for i, enemy in ipairs(enemies) do
    enemy:restore(enemy_snaps[i])
  end

  return timeline
end

--- Recalculate timeline inside current turn from a changed index.
---@param hero Hero
---@param enemies Enemy[]
---@param timeline PredictedAction[]
---@param start_index number
---@param opts? {preserve_actor_slots?: boolean}
---@return PredictedAction[]
function PredictionEngine:recalculate_with(hero, enemies, timeline, start_index, opts)
  if not timeline or #timeline == 0 then
    return {}
  end

  local suffix_start = math.max(1, math.min(start_index or 1, #timeline))
  local preserve_actor_slots = opts and opts.preserve_actor_slots == true

  local hero_snap = hero:snapshot()
  local enemy_snaps = {}
  for i, enemy in ipairs(enemies) do
    enemy_snaps[i] = enemy:snapshot()
  end

  local result = {}
  local ok, err = pcall(function()
    local turn_actors = self:_collect_turn_actors(hero, enemies)
    local acted_actors = {}

    -- Prefix는 고정: 해당 상태를 재현하기 위해 그대로 시뮬레이션한다.
    for idx = 1, suffix_start - 1 do
      local action = timeline[idx]
      if action then
        result[#result + 1] = action
        local source = action:get_source_type()
        if source == 'hero' or source == 'enemy' then
          acted_actors[action.actor] = true
        end
        self:_simulate_action(action, hero, enemies)
      end
    end

    local pending = {}
    for _, actor in ipairs(turn_actors) do
      if actor and actor:is_alive() and not acted_actors[actor] then
        pending[#pending + 1] = actor
      end
    end

    -- Suffix의 spell 슬롯은 유지하고, actor 슬롯은 현재 상태 기준으로 다시 채운다.
    for idx = suffix_start, #timeline do
      local scaffold = timeline[idx]
      if scaffold then
        if scaffold:get_source_type() == 'spell' then
          local spell_action = self:_rebuild_spell_action(scaffold, hero, enemies)
          if spell_action then
            result[#result + 1] = spell_action
            self:_simulate_action(spell_action, hero, enemies)
          end
        else
          local actor = nil
          if preserve_actor_slots then
            actor = self:_pick_scaffold_actor(pending, scaffold)
          end
          if not actor then
            actor = self:_pick_next_actor(pending, hero, enemies)
          end
          if actor then
            self:_remove_actor_from_pending(pending, actor)
            local action = self:_build_actor_action(actor, hero, enemies)
            if action then
              result[#result + 1] = action
              self:_simulate_action(action, hero, enemies)
            end
          end
        end
      end
    end
  end)

  if not ok then
    print('[PredictionEngine] Recalculate error: ' .. tostring(err))
    result = timeline
  end

  hero:restore(hero_snap)
  for i, enemy in ipairs(enemies) do
    enemy:restore(enemy_snaps[i])
  end

  return result
end

---@param scaffold PredictedAction
---@param hero Hero
---@param enemies Enemy[]
---@return PredictedAction|nil
function PredictionEngine:_rebuild_spell_action(scaffold, hero, enemies)
  local spell = scaffold.spell
  if not spell then
    return nil
  end

  local effect = spell:get_effect()
  local target = self:_resolve_spell_target(scaffold, hero, enemies)
  if not target and effect and effect.type ~= 'global' then
    return nil
  end

  return PredictedAction:new({
    actor = scaffold.actor or hero,
    pattern = nil,
    action_type = effect and effect.type or 'spell',
    target = target,
    value = effect and effect.amount or 0,
    source_type = 'spell',
    spell = spell,
    description = scaffold:get_description(),
  })
end

---@param actor Entity
---@param hero Hero
---@param enemies Enemy[]
---@return PredictedAction|nil
function PredictionEngine:_build_actor_action(actor, hero, enemies)
  if actor == hero then
    if not hero:is_alive() then
      return nil
    end

    local target = self:_get_first_living(enemies)
    if not target then
      return nil
    end

    local pattern = hero:choose_action({
      actor = hero,
      target = target,
      enemies = self:_get_living(enemies),
      current_turn = 0,
    })
    if not pattern then
      return nil
    end

    local preview = pattern:get_preview(hero)
    return PredictedAction:new({
      actor = hero,
      pattern = pattern,
      action_type = pattern.type,
      target = target,
      value = preview.value,
      source_type = 'hero',
      description = preview.description,
    })
  end

  if not actor:is_alive() or not hero:is_alive() then
    return nil
  end

  local pattern = actor:choose_action({
    actor = actor,
    target = hero,
    enemies = {hero},
    current_turn = 0,
  })
  if not pattern then
    return nil
  end

  local preview = pattern:get_preview(actor)
  return PredictedAction:new({
    actor = actor,
    pattern = pattern,
    action_type = pattern.type,
    target = hero,
    value = preview.value,
    source_type = 'enemy',
    description = actor:get_name() .. ': ' .. preview.description,
  })
end

---@param scaffold PredictedAction
---@param hero Hero
---@param enemies Enemy[]
---@return Entity|nil
function PredictionEngine:_resolve_spell_target(scaffold, hero, enemies)
  local spell = scaffold.spell
  if not spell then
    return nil
  end

  local effect = spell:get_effect()
  if not effect then
    return scaffold.target
  end

  if effect.type == 'damage' or effect.type == 'debuff_attack' or effect.type == 'debuff_speed' then
    local target = scaffold.target
    if target and target ~= hero and target.is_alive and target:is_alive() then
      return target
    end
    return self:_get_first_living(enemies)
  end

  if effect.type == 'global' then
    return hero
  end

  local target = scaffold.target
  if target and target.is_alive and target:is_alive() then
    return target
  end

  if hero:is_alive() then
    return hero
  end
  return nil
end

---@param action PredictedAction
---@param hero Hero
---@param enemies Enemy[]
---@return nil
function PredictionEngine:_simulate_action(action, hero, enemies)
  local source = action:get_source_type()
  local action_type = action:get_action_type()
  local value = math.max(0, action:get_value() or 0)

  if source == 'spell' then
    if action.spell then
      local effect = action.spell:get_effect()
      if action.target or (effect and effect.type == 'global') then
        action.spell:execute(action.target, {
          hero = hero,
          enemies = enemies,
          suspicion_manager = nil,
        })
      end
    end
    return
  end

  if source == 'hero' then
    if not hero:is_alive() then
      return
    end

    local target = action.target
    if action_type == 'attack' then
      if target and target:is_alive() then
        target:take_damage(value)
      end
    elseif action_type == 'defend' then
      hero.defense = hero.defense + value
    elseif action_type == 'heal' then
      hero:heal(value)
    elseif action.pattern and target and target:is_alive() then
      action.pattern:execute(hero, target)
    end
    return
  end

  if source == 'enemy' then
    local actor = action.actor
    if not actor or not actor:is_alive() then
      return
    end

    if action_type == 'attack' then
      if hero:is_alive() then
        hero:take_damage(value)
      end
    elseif action_type == 'defend' then
      actor.defense = actor.defense + value
    elseif action_type == 'heal' then
      actor:heal(value)
    elseif action.pattern then
      if action.pattern.type == 'defend' then
        action.pattern:execute(actor, actor)
      elseif hero:is_alive() then
        action.pattern:execute(actor, hero)
      end
    end
  end
end

---@param hero Hero
---@param enemies Enemy[]
---@return Entity[]
function PredictionEngine:_collect_turn_actors(hero, enemies)
  local actors = {}
  if hero:is_alive() then
    actors[#actors + 1] = hero
  end
  for _, enemy in ipairs(enemies) do
    if enemy:is_alive() then
      actors[#actors + 1] = enemy
    end
  end
  return actors
end

---@param pending Entity[]
---@param hero Hero
---@param enemies Enemy[]
---@return Entity|nil
function PredictionEngine:_pick_next_actor(pending, hero, enemies)
  local best_actor = nil
  local best_speed = -math.huge
  local best_rank = math.huge

  for _, actor in ipairs(pending) do
    if actor and actor:is_alive() then
      local speed = actor.get_speed and actor:get_speed() or 0
      local rank = self:_get_actor_rank(actor, hero, enemies)
      if speed > best_speed or (speed == best_speed and rank < best_rank) then
        best_actor = actor
        best_speed = speed
        best_rank = rank
      end
    end
  end

  return best_actor
end

---@param pending Entity[]
---@param scaffold PredictedAction
---@return Entity|nil
function PredictionEngine:_pick_scaffold_actor(pending, scaffold)
  if not scaffold then
    return nil
  end

  local actor = scaffold.actor
  if not actor or not actor.is_alive or not actor:is_alive() then
    return nil
  end

  for _, candidate in ipairs(pending) do
    if candidate == actor then
      return actor
    end
  end

  return nil
end

---@param actor Entity
---@param hero Hero
---@param enemies Enemy[]
---@return number
function PredictionEngine:_get_actor_rank(actor, hero, enemies)
  if actor == hero then
    return 0
  end
  for i, enemy in ipairs(enemies) do
    if actor == enemy then
      return i
    end
  end
  return 999
end

---@param pending Entity[]
---@param actor Entity
---@return nil
function PredictionEngine:_remove_actor_from_pending(pending, actor)
  for i = #pending, 1, -1 do
    if pending[i] == actor then
      table.remove(pending, i)
      return
    end
  end
end

---@param entities Entity[]
---@return Entity|nil
function PredictionEngine:_get_first_living(entities)
  for _, e in ipairs(entities) do
    if e:is_alive() then
      return e
    end
  end
  return nil
end

---@param entities Entity[]
---@return Entity[]
function PredictionEngine:_get_living(entities)
  local living = {}
  for _, e in ipairs(entities) do
    if e:is_alive() then
      living[#living + 1] = e
    end
  end
  return living
end

return PredictionEngine
