local class = require('lib.middleclass')

---@class Spell
---@field id string
---@field name string
---@field description string
---@field cost number
---@field suspicion_delta number
---@field target_scope string|nil "all"|"faction"|"single"
---@field target_side string|nil "hero"|"enemy"|"both"
---@field target_mode string "hero"|"enemy"|"any"
---@field effect SpellEffectObject
---@field timeline_type string "insert"|"manipulate_swap"|"manipulate_remove"|"manipulate_delay"|"manipulate_modify"|"global"
---@field new fun(self: Spell, data: table): Spell
local Spell = class('Spell')

---@param side string|nil
---@return string|nil
local function infer_target_mode_from_side(side)
  if side == "hero" then return "hero" end
  if side == "enemy" then return "enemy" end
  if side == "both" then return "any" end
  return nil
end

---@param effect SpellEffectObject|nil
---@param target_scope string|nil
---@param target_side string|nil
---@return string
local function infer_target_mode(effect, target_scope, target_side)
  local mode_from_side = infer_target_mode_from_side(target_side)
  if mode_from_side then
    return mode_from_side
  end

  if not effect then
    return "hero"
  end

  if effect.type == "damage" or effect.type == "debuff_attack" or effect.type == "debuff_speed" then
    -- Enemy-target spells are selectable on both sides in planning.
    return "any"
  end

  return "hero"
end

--- Initialize a spell from a data table
---@param data table
function Spell:initialize(data)
  self.id = data.id
  self.name = data.name
  self.description = data.description
  self.cost = data.cost
  self.suspicion_delta = data.suspicion_delta
  self.effect = data.effect
  self.timeline_type = data.timeline_type or "insert"

  if self.timeline_type == "insert" then
    self.target_scope = data.target_scope or "single"
    if data.target_side then
      self.target_side = data.target_side
    elseif data.target_mode == "hero" then
      self.target_side = "hero"
    elseif data.target_mode == "enemy" then
      self.target_side = "enemy"
    else
      self.target_side = "both"
    end
  else
    self.target_scope = nil
    self.target_side = nil
  end

  self.target_mode = data.target_mode
    or infer_target_mode(self.effect, self.target_scope, self.target_side)
end

---@return string
function Spell:get_id()
  return self.id
end

---@return string
function Spell:get_name()
  return self.name
end

---@return string
function Spell:get_description()
  return self.description
end

---@return number
function Spell:get_cost()
  return self.cost
end

---@return number
function Spell:get_suspicion_delta()
  return self.suspicion_delta
end

---@return string|nil
function Spell:get_target_scope()
  return self.target_scope
end

---@return string|nil
function Spell:get_target_side()
  return self.target_side
end

---@return string
function Spell:get_target_mode()
  return self.target_mode
end

---@param target any
---@param hero any
---@return string|nil
function Spell:_resolve_target_side(target, hero)
  if type(target) == "table" then
    if target.target_side and target.target_side ~= "both" then
      return target.target_side
    end
    if target.primary then
      if hero and target.primary == hero then
        return "hero"
      end
      return "enemy"
    end
    if target.entities and #target.entities > 0 then
      for _, entity in ipairs(target.entities) do
        if hero and entity == hero then
          return "hero"
        end
      end
      return "enemy"
    end
  end

  if target and hero and target == hero then
    return "hero"
  end
  if target then
    return "enemy"
  end

  local mode_from_side = infer_target_mode_from_side(self.target_side)
  if mode_from_side == "hero" then
    return "hero"
  elseif mode_from_side == "enemy" then
    return "enemy"
  end

  return nil
end

---@param target any
---@param hero any
---@return number
function Spell:get_signed_suspicion_delta(target, hero)
  local base = self.suspicion_delta or 0
  if base == 0 then
    return 0
  end

  if self.target_mode == "any" then
    local magnitude = math.abs(base)
    local side = self:_resolve_target_side(target, hero)
    if side == "hero" then
      return -magnitude
    elseif side == "enemy" then
      return magnitude
    end
    return base
  end

  return base
end

---@return SpellEffectObject
function Spell:get_effect()
  return self.effect
end

---@return string
function Spell:get_timeline_type()
  return self.timeline_type
end

--- Check if this spell can be played given current mana
---@param mana_manager ManaManager
---@return boolean
function Spell:can_play(mana_manager)
  return mana_manager:can_afford(self.cost)
end

--- Reserve mana for this spell (timeline placement)
---@param mana_manager ManaManager
---@return boolean
function Spell:reserve(mana_manager)
  return mana_manager:reserve(self.cost)
end

--- Unreserve mana for this spell (timeline removal)
---@param mana_manager ManaManager
function Spell:unreserve(mana_manager)
  mana_manager:unreserve(self.cost)
end

--- Execute spell effect (after confirmation, during EXECUTION phase)
---@param target any
---@param context {hero: any, enemies: any, suspicion_manager: SuspicionManager}
function Spell:execute(target, context)
  if self.effect.type == "global" then
    self.effect:apply(target, context)
  else
    local targets = {}
    if type(target) == "table" and target.entities then
      targets = target.entities
    else
      targets[1] = target
    end

    for _, entity in ipairs(targets) do
      if entity and (not entity.is_alive or entity:is_alive()) then
        self.effect:apply(entity, context)
      end
    end
  end

  if context and context.suspicion_manager then
    local delta = self:get_signed_suspicion_delta(target, context.hero)
    if delta > 0 then
      context.suspicion_manager:add(delta)
    elseif delta < 0 then
      context.suspicion_manager:reduce(math.abs(delta))
    end
  end
end

--- Play this spell: spend mana + apply effect + suspicion (legacy compat)
---@param target any
---@param context {hero: any, enemies: any, mana_manager: ManaManager, suspicion_manager: SuspicionManager}
---@return boolean
function Spell:play(target, context)
  if not self:can_play(context.mana_manager) then
    return false
  end

  context.mana_manager:spend(self.cost)
  self:execute(target, context)
  return true
end

return Spell
