---@module SpellEffect
--- Factory functions returning effect objects (tables with apply method).
--- Each factory returns a table {type, amount, apply(self, target, context)}.

---@class SpellEffectObject
---@field type string
---@field amount number
---@field apply fun(self: SpellEffectObject, target: any, context: any)

local SpellEffect = {}

--- Create a healing effect
---@param amount number
---@return SpellEffectObject
function SpellEffect.heal(amount)
  return {
    type = "heal",
    amount = amount,
    apply = function(self, target, context)
      target:heal(self.amount)
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
      target:take_damage(self.amount)
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

--- Create a hinder effect (damage to hero)
---@param damage_amount number
---@return SpellEffectObject
function SpellEffect.hinder(damage_amount)
  return {
    type = "hinder",
    amount = damage_amount,
    apply = function(self, target, context)
      target:take_damage(self.amount)
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

return SpellEffect
