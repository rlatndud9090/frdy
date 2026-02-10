---@module CardEffect
--- Factory functions returning effect objects (tables with apply method).
--- Each factory returns a table {type, amount, apply(self, target, context)}.

---@class CardEffectObject
---@field type string
---@field amount number
---@field apply fun(self: CardEffectObject, target: any, context: any)

local CardEffect = {}

--- Create a healing effect
---@param amount number
---@return CardEffectObject
function CardEffect.heal(amount)
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
---@return CardEffectObject
function CardEffect.damage(amount)
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
---@return CardEffectObject
function CardEffect.buff_attack(amount)
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
---@return CardEffectObject
function CardEffect.debuff_attack(amount)
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
---@return CardEffectObject
function CardEffect.hinder(damage_amount)
  return {
    type = "hinder",
    amount = damage_amount,
    apply = function(self, target, context)
      target:take_damage(self.amount)
    end
  }
end

return CardEffect
