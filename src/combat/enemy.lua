local Entity = require('src.combat.entity')

---@class Enemy : Entity
---@field action_patterns table[]
---@field current_pattern_index number
---@field intent table|nil
local Enemy = Entity:subclass('Enemy')

---@param name string
---@param stats {hp: number, attack: number, defense: number}
---@param action_patterns table[]
function Enemy:initialize(name, stats, action_patterns)
  Entity.initialize(self, name, stats)
  self.action_patterns = action_patterns or {{type = "attack", damage_mult = 1.0}}
  self.current_pattern_index = 1
  self.intent = nil
end

---@return table current action pattern
function Enemy:choose_action()
  local pattern = self.action_patterns[self.current_pattern_index]
  self.current_pattern_index = self.current_pattern_index % #self.action_patterns + 1
  return pattern
end

---@return table|nil
function Enemy:get_intent()
  return self.intent
end

---적의 다음 행동 미리보기를 계산
function Enemy:prepare_intent()
  local pattern = self.action_patterns[self.current_pattern_index]
  if pattern.type == "attack" then
    local damage = math.floor(self.attack * (pattern.damage_mult or 1.0))
    self.intent = {
      type = "attack",
      damage = damage,
      description = "공격 " .. damage,
    }
  elseif pattern.type == "defend" then
    local bonus = pattern.defense_bonus or 0
    self.intent = {
      type = "defend",
      defense_bonus = bonus,
      description = "방어 +" .. bonus,
    }
  end
end

return Enemy
