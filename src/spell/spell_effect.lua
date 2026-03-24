---@module SpellEffect
--- Factory functions returning effect objects (tables with apply method).
--- Each factory returns a table {type, amount, apply(self, target, context)}.

---@class SpellEffectObject
---@field type string
---@field amount number
---@field status_id string|nil
---@field status_spec table|nil
---@field apply fun(self: SpellEffectObject, target: any, context: any)

local SpellEffect = {}

---@param value any
---@return any
local function deep_copy(value)
  if type(value) ~= "table" then
    return value
  end

  local copied = {}
  for key, item in pairs(value) do
    if type(item) ~= "function" then
      copied[key] = deep_copy(item)
    end
  end
  return copied
end

--- Create a healing effect
---@param amount number
---@return SpellEffectObject
function SpellEffect.heal(amount)
  return {
    type = "heal",
    amount = amount,
    apply = function(self, target, context)
      if context and context.apply_heal then
        context.apply_heal(target, self.amount)
      else
        target:heal(self.amount)
      end
    end
  }
end

--- Create a damage effect
---@param amount number
---@return SpellEffectObject
function SpellEffect.damage(amount)
  return {
    type = "damage",
    amount = amount,
    apply = function(self, target, context)
      if context and context.apply_damage then
        context.apply_damage(target, self.amount)
      else
        target:take_damage(self.amount)
      end
    end
  }
end

--- Create an attack buff effect
---@param amount number
---@return SpellEffectObject
function SpellEffect.buff_attack(amount)
  return {
    type = "buff_attack",
    amount = amount,
    apply = function(self, target, context)
      target.attack = target.attack + self.amount
    end
  }
end

--- Create an attack debuff effect
---@param amount number
---@return SpellEffectObject
function SpellEffect.debuff_attack(amount)
  return {
    type = "debuff_attack",
    amount = amount,
    apply = function(self, target, context)
      target.attack = math.max(0, target.attack - self.amount)
    end
  }
end

--- Create a speed buff effect
---@param amount number
---@return SpellEffectObject
function SpellEffect.buff_speed(amount)
  return {
    type = "buff_speed",
    amount = amount,
    apply = function(self, target, context)
      target.speed = target.speed + self.amount
    end
  }
end

--- Create a speed debuff effect
---@param amount number
---@return SpellEffectObject
function SpellEffect.debuff_speed(amount)
  return {
    type = "debuff_speed",
    amount = amount,
    apply = function(self, target, context)
      target.speed = math.max(0, target.speed - self.amount)
    end
  }
end

--- Legacy alias for targeted damage.
--- Kept so older spell ids can stay stable while target rules remain side-agnostic.
---@param damage_amount number
---@return SpellEffectObject
function SpellEffect.hinder(damage_amount)
  return SpellEffect.damage(damage_amount)
end

--- Create a character status effect.
--- Status lifecycle is managed by StatusContainer on each entity.
---@param status_id string
---@param spec? table
---@return SpellEffectObject
function SpellEffect.apply_status(status_id, spec)
  spec = spec or {}
  return {
    type = "apply_status",
    amount = spec.preview_amount or 0,
    status_id = status_id,
    status_spec = spec,
    apply = function(self, target, context)
      if target and target.add_status then
        target:add_status(self.status_id, self.status_spec)
      end
    end
  }
end

--- Create a field status effect.
--- Field statuses are managed by CombatManager.field_status_container.
---@param status_id string
---@param spec? table
---@return SpellEffectObject
function SpellEffect.apply_field_status(status_id, spec)
  spec = spec or {}
  return {
    type = "apply_field_status",
    amount = spec.preview_amount or 0,
    status_id = status_id,
    status_spec = spec,
    apply = function(self, target, context)
      local field_statuses = context and context.field_statuses
      if field_statuses and field_statuses.add then
        field_statuses:add(self.status_id, self.status_spec)
      end
    end
  }
end

--- Create a next-action value delta effect.
--- This is applied by TimelineManager from the insertion point.
---@param delta number
---@return SpellEffectObject
function SpellEffect.action_delta(delta)
  return {
    type = "action_delta",
    amount = delta,
    apply = function(self, target, context)
      -- Handled by TimelineManager reapply pass.
    end
  }
end

--- Create a next-action block effect.
--- This is applied by TimelineManager from the insertion point.
---@param count number
---@return SpellEffectObject
function SpellEffect.action_block(count)
  return {
    type = "action_block",
    amount = count,
    apply = function(self, target, context)
      -- Handled by TimelineManager reapply pass.
    end
  }
end

--- Create a swap effect (swap two timeline positions)
--- Applied via TimelineManager:swap(), not target.apply
---@return SpellEffectObject
function SpellEffect.swap()
  return {
    type = "manipulate_swap",
    amount = 0,
    apply = function(self, target, context)
      -- Handled by TimelineManager:swap(a, b)
    end
  }
end

--- Create a nullify effect (remove a timeline action)
--- Applied via TimelineManager:remove_at()
---@return SpellEffectObject
function SpellEffect.nullify()
  return {
    type = "manipulate_remove",
    amount = 0,
    apply = function(self, target, context)
      -- Handled by TimelineManager:remove_at(index)
    end
  }
end

--- Create a delay effect (push action back by N positions)
---@param positions number
---@return SpellEffectObject
function SpellEffect.delay(positions)
  return {
    type = "manipulate_delay",
    amount = positions,
    apply = function(self, target, context)
      -- Handled by TimelineManager swap chain
    end
  }
end

--- Create a modify effect (change action value by amount)
---@param delta number positive = buff, negative = debuff
---@return SpellEffectObject
function SpellEffect.modify(delta)
  return {
    type = "manipulate_modify",
    amount = delta,
    apply = function(self, target, context)
      -- Handled by TimelineManager:modify_at(index, spell)
    end
  }
end

--- Create a global buff effect (buff all hero actions)
---@param attack_delta number
---@return SpellEffectObject
function SpellEffect.global_buff(attack_delta)
  return {
    type = "global",
    amount = attack_delta,
    apply = function(self, target, context)
      -- Handled by TimelineManager:apply_global(spell)
    end
  }
end

---@param effect SpellEffectObject|table|nil
---@return table|nil
function SpellEffect.snapshot(effect)
  if type(effect) ~= "table" then
    return nil
  end

  local snapshot = {}
  for key, value in pairs(effect) do
    if key ~= "apply" and type(value) ~= "function" then
      snapshot[key] = deep_copy(value)
    end
  end
  return snapshot
end

---@param effect SpellEffectObject
---@param snapshot table
---@return SpellEffectObject
local function copy_serialized_fields(effect, snapshot)
  for key, value in pairs(snapshot) do
    if key ~= "apply" and type(value) ~= "function" then
      effect[key] = deep_copy(value)
    end
  end
  return effect
end

---@param snapshot table|nil
---@return SpellEffectObject|nil
function SpellEffect.from_snapshot(snapshot)
  if type(snapshot) ~= "table" or type(snapshot.type) ~= "string" then
    return nil
  end

  local effect = nil
  local amount = type(snapshot.amount) == "number" and snapshot.amount or 0
  if snapshot.type == "heal" then
    effect = SpellEffect.heal(amount)
  elseif snapshot.type == "damage" then
    effect = SpellEffect.damage(amount)
  elseif snapshot.type == "buff_attack" then
    effect = SpellEffect.buff_attack(amount)
  elseif snapshot.type == "debuff_attack" then
    effect = SpellEffect.debuff_attack(amount)
  elseif snapshot.type == "buff_speed" then
    effect = SpellEffect.buff_speed(amount)
  elseif snapshot.type == "debuff_speed" then
    effect = SpellEffect.debuff_speed(amount)
  elseif snapshot.type == "apply_status" then
    effect = SpellEffect.apply_status(snapshot.status_id or "", deep_copy(snapshot.status_spec or {}))
  elseif snapshot.type == "apply_field_status" then
    effect = SpellEffect.apply_field_status(snapshot.status_id or "", deep_copy(snapshot.status_spec or {}))
  elseif snapshot.type == "action_delta" then
    effect = SpellEffect.action_delta(amount)
  elseif snapshot.type == "action_block" then
    effect = SpellEffect.action_block(amount)
  elseif snapshot.type == "manipulate_swap" then
    effect = SpellEffect.swap()
  elseif snapshot.type == "manipulate_remove" then
    effect = SpellEffect.nullify()
  elseif snapshot.type == "manipulate_delay" then
    effect = SpellEffect.delay(amount)
  elseif snapshot.type == "manipulate_modify" then
    effect = SpellEffect.modify(amount)
  elseif snapshot.type == "global" then
    effect = SpellEffect.global_buff(amount)
  end

  if not effect then
    return nil
  end

  return copy_serialized_fields(effect, snapshot)
end

return SpellEffect
