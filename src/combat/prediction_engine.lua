local class = require('lib.middleclass')
local PredictedAction = require('src.combat.predicted_action')
local i18n = require('src.i18n.init')

---@class PredictionEngine
---@field max_actions number
local PredictionEngine = class('PredictionEngine')

---@class PredictionStateSnapshotEnemy
---@field id number
---@field name string
---@field hp number
---@field max_hp number
---@field alive boolean

---@class PredictionStateSnapshot
---@field hero_hp number
---@field hero_max_hp number
---@field enemies PredictionStateSnapshotEnemy[]

---@param max_actions? number
function PredictionEngine:initialize(max_actions)
  self.max_actions = max_actions or 20
end

--- Generate a predicted timeline by simulating combat
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
  local action_count = 0

  local ok, err = pcall(function()
    while action_count < self.max_actions do
      if not hero:is_alive() or #self:_get_living(enemies) == 0 then
        break
      end

      self:_simulate_hero_action(timeline, hero, enemies)
      action_count = #timeline

      if not hero:is_alive() or #self:_get_living(enemies) == 0 or action_count >= self.max_actions then
        break
      end

      for _, enemy in ipairs(enemies) do
        if not hero:is_alive() or #self:_get_living(enemies) == 0 or #timeline >= self.max_actions then
          break
        end
        self:_simulate_enemy_action(timeline, enemy, hero, enemies)
      end

      action_count = #timeline
    end
  end)

  if not ok then
    print('[PredictionEngine] Simulation error: ' .. tostring(err))
  end

  hero:restore(hero_snap)
  for i, enemy in ipairs(enemies) do
    enemy:restore(enemy_snaps[i])
  end

  return timeline
end

--- Recalculate timeline with interventions applied
---@param hero Hero
---@param enemies Enemy[]
---@param interventions table[]
---@return PredictedAction[]
function PredictionEngine:recalculate_with(hero, enemies, interventions)
  local base_timeline = self:generate_timeline(hero, enemies)
  local timeline = {}

  for i, action in ipairs(base_timeline) do
    timeline[i] = action
  end

  for _, intervention in ipairs(interventions) do
    local kind = intervention.kind
    if kind == 'insert' then
      self:_apply_insert_intervention(timeline, intervention)
    elseif kind == 'swap' then
      self:_apply_swap_intervention(timeline, intervention)
    elseif kind == 'remove' then
      self:_apply_remove_intervention(timeline, intervention)
    elseif kind == 'delay' then
      self:_apply_delay_intervention(timeline, intervention)
    elseif kind == 'modify' then
      self:_apply_modify_intervention(timeline, intervention)
    elseif kind == 'global' then
      self:_apply_global_intervention(timeline, intervention)
    end
  end

  return timeline
end

---@param timeline PredictedAction[]
---@param hero Hero
---@param enemies Enemy[]
function PredictionEngine:_simulate_hero_action(timeline, hero, enemies)
  if not hero:is_alive() then return end

  local target = self:_get_first_living(enemies)
  if not target then return end

  local pattern = hero:choose_action({
    target = target,
    enemies = self:_get_living(enemies),
  })

  if not pattern then return end

  local preview = pattern:get_preview(hero)
  pattern:execute(hero, target)

  local action = PredictedAction:new({
    actor = hero,
    pattern = pattern,
    action_type = pattern.type,
    target = target,
    value = preview.value,
    source_type = 'hero',
    description = preview.description,
    state_snapshot = self:_build_state_snapshot(hero, enemies),
  })
  table.insert(timeline, action)
end

---@param timeline PredictedAction[]
---@param enemy Enemy
---@param hero Hero
---@param enemies Enemy[]
function PredictionEngine:_simulate_enemy_action(timeline, enemy, hero, enemies)
  if not enemy:is_alive() or not hero:is_alive() then return end

  local pattern = enemy:choose_action({
    actor = enemy,
    target = hero,
  })
  if not pattern then return end

  local preview = pattern:get_preview(enemy)
  if pattern.type == 'attack' then
    pattern:execute(enemy, hero)
  elseif pattern.type == 'defend' then
    pattern:execute(enemy, enemy)
  end

  local action = PredictedAction:new({
    actor = enemy,
    pattern = pattern,
    action_type = pattern.type,
    target = hero,
    value = preview.value,
    source_type = 'enemy',
    description = enemy:get_name() .. ': ' .. preview.description,
    state_snapshot = self:_build_state_snapshot(hero, enemies),
  })
  table.insert(timeline, action)
end

---@param timeline PredictedAction[]
---@param intervention table
function PredictionEngine:_apply_insert_intervention(timeline, intervention)
  local index = math.max(1, math.min(intervention.index or (#timeline + 1), #timeline + 1))
  local spell = intervention.spell
  if not spell then return end

  local effect = spell:get_effect()
  local description = i18n.t('combat.demon_lord_used_spell', {spell = spell:get_name()})
  local snapshot = intervention.state_snapshot or self:_derive_spell_snapshot(timeline, index, effect, intervention.target_enemy_index, intervention.target)
  local predicted = PredictedAction:new({
    actor = intervention.actor,
    pattern = nil,
    action_type = effect and effect.type or 'spell',
    target = intervention.target,
    value = effect and effect.amount or 0,
    source_type = 'spell',
    spell = spell,
    description = description,
    state_snapshot = snapshot,
  })

  table.insert(timeline, index, predicted)
end

---@param timeline PredictedAction[]
---@param index number
---@param effect SpellEffectObject|nil
---@param target_enemy_index? number
---@param target Entity|nil
---@return PredictionStateSnapshot|nil
function PredictionEngine:_derive_spell_snapshot(timeline, index, effect, target_enemy_index, target)
  local base_snapshot = nil
  if index > 1 and timeline[index - 1] then
    base_snapshot = timeline[index - 1]:get_state_snapshot()
  end
  if not base_snapshot then
    return nil
  end

  local snapshot = {
    hero_hp = base_snapshot.hero_hp,
    hero_max_hp = base_snapshot.hero_max_hp,
    enemies = {},
  }

  for _, enemy_state in ipairs(base_snapshot.enemies or {}) do
    table.insert(snapshot.enemies, {
      id = enemy_state.id,
      name = enemy_state.name,
      hp = enemy_state.hp,
      max_hp = enemy_state.max_hp,
      alive = enemy_state.alive,
    })
  end

  if not effect then
    return snapshot
  end

  local effect_type = effect.type
  local amount = effect.amount or 0

  if target and target.name == 'entity.hero' then
    if effect_type == 'heal' then
      snapshot.hero_hp = math.min(snapshot.hero_max_hp, snapshot.hero_hp + amount)
    elseif effect_type == 'damage' or effect_type == 'hinder' then
      snapshot.hero_hp = math.max(0, snapshot.hero_hp - amount)
    end
  else
    for i = #snapshot.enemies, 1, -1 do
      local enemy_state = snapshot.enemies[i]
      local is_target_enemy = false
      if target_enemy_index and enemy_state.id == target_enemy_index then
        is_target_enemy = true
      elseif (not target_enemy_index) and target and enemy_state.name == target:get_name() then
        is_target_enemy = true
      end

      if is_target_enemy then
        if effect_type == 'damage' or effect_type == 'hinder' then
          enemy_state.hp = math.max(0, enemy_state.hp - amount)
        elseif effect_type == 'heal' then
          enemy_state.hp = math.min(enemy_state.max_hp, enemy_state.hp + amount)
        end
        enemy_state.alive = enemy_state.hp > 0
      end

      if not enemy_state.alive then
        table.remove(snapshot.enemies, i)
      end
    end
  end

  return snapshot
end

---@param timeline PredictedAction[]
---@param intervention table
function PredictionEngine:_apply_swap_intervention(timeline, intervention)
  local a = intervention.index
  local b = intervention.dest_index
  if not a or not b then return end
  if a >= 1 and a <= #timeline and b >= 1 and b <= #timeline then
    timeline[a], timeline[b] = timeline[b], timeline[a]
  end
end

---@param timeline PredictedAction[]
---@param intervention table
function PredictionEngine:_apply_remove_intervention(timeline, intervention)
  local index = intervention.index
  if index and index >= 1 and index <= #timeline then
    table.remove(timeline, index)
  end
end

---@param timeline PredictedAction[]
---@param intervention table
function PredictionEngine:_apply_delay_intervention(timeline, intervention)
  local index = intervention.index
  local amount = intervention.delay_amount or 1
  if not index then return end

  for _ = 1, amount do
    if index < #timeline then
      timeline[index], timeline[index + 1] = timeline[index + 1], timeline[index]
      index = index + 1
    end
  end
end

---@param timeline PredictedAction[]
---@param intervention table
function PredictionEngine:_apply_modify_intervention(timeline, intervention)
  local index = intervention.index
  local delta = intervention.modify_delta or 0
  if not index or not timeline[index] then return end

  local action = timeline[index]
  action.value = math.max(0, action.value + delta)
end

---@param timeline PredictedAction[]
---@param intervention table
function PredictionEngine:_apply_global_intervention(timeline, intervention)
  local delta = intervention.global_attack_delta or 0
  if delta == 0 then return end

  for _, action in ipairs(timeline) do
    if action:get_source_type() == 'hero' and action:get_action_type() == 'attack' then
      action.value = math.max(0, action.value + delta)
    end
  end
end

---@param hero Hero
---@param enemies Enemy[]
---@return PredictionStateSnapshot
function PredictionEngine:_build_state_snapshot(hero, enemies)
  local snapshot = {
    hero_hp = hero:get_hp(),
    hero_max_hp = hero:get_max_hp(),
    enemies = {},
  }

  for i, enemy in ipairs(enemies) do
    if enemy:is_alive() then
      table.insert(snapshot.enemies, {
        id = i,
        name = enemy:get_name(),
        hp = enemy:get_hp(),
        max_hp = enemy:get_max_hp(),
        alive = enemy:is_alive(),
      })
    end
  end

  return snapshot
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
