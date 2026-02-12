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

return SpellEffect
